//
// RMWebMapSource.m
//
// Copyright (c) 2009, Frank Schroeder, SharpMind GbR
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMAbstractWebMapSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"

#define kWebTileRetries 30

@implementation RMWebDownloadOperation

@synthesize isExecuting;
@synthesize isFinished;

+ (id)operationWithUrl:(NSURL *)anURL withTileImage:(RMTileImage *)aTileImage andTileCache:(RMTileCache *)aTileCache withCacheKey:(NSString *)aCacheKey
{
    return [[[self alloc] initWithUrl:anURL withTileImage:aTileImage andTileCache:aTileCache withCacheKey:aCacheKey] autorelease];
}

- (id)initWithUrl:(NSURL *)anURL withTileImage:(RMTileImage *)aTileImage andTileCache:(RMTileCache *)aTileCache withCacheKey:(NSString *)aCacheKey
{
    if (!(self = [super init]))
        return nil;
    
//    [self setQueuePriority:10]; // Highest priority
    
    connection = nil;
    retries = kWebTileRetries;
    data = [[NSMutableData alloc] initWithCapacity:0];
    tileURL = [anURL retain];
    tileImage = [aTileImage retain];
    tileCache = [aTileCache retain];
    cacheKey = [aCacheKey retain];
    
    isExecuting = NO;
    isFinished = NO;

    return self;
}

- (void)dealloc
{
    [connection cancel]; [connection release]; connection = nil;
    [tileURL release]; tileURL = nil;
    [data release]; data = nil;
    [tileImage release]; tileImage = nil;
    [tileCache release]; tileCache = nil;
    [cacheKey release]; cacheKey = nil;
    [super dealloc];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)finish
{
    [connection cancel]; [connection release]; connection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

    if (tileImage.loadingCancelled) {
        [self finish];
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    NSURLRequest *request = [NSURLRequest requestWithURL:tileURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

    [connection cancel]; [connection release]; connection = nil;
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (!connection) {
        [tileImage updateWithImage:[RMTileImage errorTile] andNotifyListeners:NO];
        [self finish];
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse
{
	int statusCode = NSURLErrorUnknown; // unknown
	if ([aResponse isKindOfClass:[NSHTTPURLResponse class]])
        statusCode = [(NSHTTPURLResponse *)aResponse statusCode];

	[data setLength:0];

	if (statusCode < 400) { // Success
	}
    else if (statusCode == 404) { // Not Found
        if (!tileImage.loadingCancelled)
            [tileImage updateWithImage:[RMTileImage missingTile] andNotifyListeners:NO];

        [self finish];
	}
	else { // Other Error
           //RMLog(@"didReceiveResponse %@ %d", _connection, statusCode);
		BOOL retry = FALSE;

		switch(statusCode)
		{
			case 500: retry = TRUE; break;
			case 503: retry = TRUE; break;
		}

		if (retry) {
			[self start];
		}
		else {
			[self finish];
		}
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)newData
{
    [data appendData:newData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	if ([data length] == 0) {
		[self start];
	}
	else {
        if (tileImage.loadingCancelled) {
            [self finish];
            return;
        }

        UIImage *image = [UIImage imageWithData:data];
        [tileImage updateWithImage:image andNotifyListeners:YES];
        if (tileCache) [tileCache addImage:image forTile:tileImage.tile withCacheKey:cacheKey];
        [self finish];
	}
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	//RMLog(@"didFailWithError %@ %d %@", _connection, [error code], [error localizedDescription]);
	BOOL retry = FALSE;
    
	switch ([error code])
	{
        case NSURLErrorBadURL:                      // -1000
        case NSURLErrorTimedOut:                    // -1001
        case NSURLErrorUnsupportedURL:              // -1002
        case NSURLErrorCannotFindHost:              // -1003
        case NSURLErrorCannotConnectToHost:         // -1004
        case NSURLErrorNetworkConnectionLost:       // -1005
        case NSURLErrorDNSLookupFailed:             // -1006
        case NSURLErrorResourceUnavailable:         // -1008
        case NSURLErrorNotConnectedToInternet:      // -1009
            retry = TRUE; 
            break;
	}
	    
	if (retry) {
		[self start];
	}
	else {
		[self finish];
	}
}

@end

#pragma mark -

@implementation RMAbstractWebMapSource

- (id)init
{
    if (!(self = [super init]))
        return nil;

    requestQueue = [NSOperationQueue new];
    [requestQueue setMaxConcurrentOperationCount:2];
    
    return self;
}

- (void)dealloc
{
    [requestQueue cancelAllOperations];
    [requestQueue release]; requestQueue = nil;
    [super dealloc];
}

- (NSURL *)URLForTile:(RMTile)tile
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"URLForTile: invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}

- (UIImage *)imageForTileImage:(RMTileImage *)tileImage addToCache:(RMTileCache *)tileCache withCacheKey:(NSString *)aCacheKey
{
	RMTile tile = [[self mercatorToTileProjection] normaliseTile:tileImage.tile];

//    [requestQueue setSuspended:YES];
//    for (NSOperation *currentRequest in [requestQueue operations])
//    {
//        [currentRequest setQueuePriority:[currentRequest queuePriority] - 1];
//    }
//    [requestQueue setSuspended:NO];
    
    [requestQueue addOperation:[RMWebDownloadOperation operationWithUrl:[self URLForTile:tile] withTileImage:tileImage andTileCache:tileCache withCacheKey:aCacheKey]];
    
    return nil;
}

@end
