//
//  DAO.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
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

#import "RMTileCacheDAO.h"
#import "FMDatabase.h"
#import "RMTileCache.h"
#import "RMTileImage.h"

@interface RMTileCacheDAO ()
- (NSUInteger)countTiles;
@end

@implementation RMTileCacheDAO

-(void)configureDBForFirstUse
{
    [db executeQuery:@"PRAGMA synchronous=OFF"];
    [db executeQuery:@"PRAGMA journal_mode=OFF"];
	[db executeUpdate:@"CREATE TABLE IF NOT EXISTS ZCACHE (ztileHash INTEGER PRIMARY KEY, zlastUsed DOUBLE, zdata BLOB)"];
    [db executeUpdate:@"CREATE INDEX IF NOT EXISTS zlastUsedIndex ON ZCACHE(zLastUsed)"];
}

-(id) initWithDatabase: (NSString*)path
{
	if (![super init])
		return nil;

    writeQueue = [NSOperationQueue new];
    [writeQueue setMaxConcurrentOperationCount:1];
    writeQueueLock = [NSRecursiveLock new];

	RMLog(@"Opening database at %@", path);

	db = [[FMDatabase alloc] initWithPath:path];
	if (![db open])
	{
		RMLog(@"Could not connect to database - %@", [db lastErrorMessage]);
		return nil;
	}
	
	[db setCrashOnErrors:TRUE];
    [db setShouldCacheStatements:TRUE];
	
	[self configureDBForFirstUse];
	
    tileCount = [self countTiles];
    
	return self;
}

- (void)dealloc
{
    LogMethod();
    [writeQueueLock lock];
    [writeQueue release]; writeQueue = nil;
    [writeQueueLock unlock];
    [writeQueueLock release]; writeQueueLock = nil;
    [db close]; [db release]; db = nil;
    [super dealloc];
}

- (NSUInteger)count
{
    return tileCount;
}

- (NSUInteger)countTiles
{
    [writeQueueLock lock];
	
	NSUInteger count = 0;
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(ztileHash) FROM ZCACHE"];
	if ([results next])
		count = [results intForColumnIndex:0];
	else
		RMLog(@"Unable to count columns");	
	[results close];

    [writeQueueLock unlock];
	
	return count;
}

-(NSData *)dataForTile:(uint64_t)tileHash
{
    [writeQueueLock lock];

	FMResultSet *results = [db executeQuery:@"SELECT zdata FROM ZCACHE WHERE ztilehash = ?", [NSNumber numberWithUnsignedLongLong:tileHash]];
	
	if ([db hadError]) {
		RMLog(@"DB error while fetching tile data: %@", [db lastErrorMessage]);
		return nil;
	}

	NSData *data = nil;	
	if ([results next])
		data = [results dataForColumnIndex:0];
	
	[results close];
	
    [writeQueueLock unlock];

	return data;
}

-(void) purgeTiles: (NSUInteger) count;
{
    RMLog(@"purging %u old tiles from db cache", count);
	
    [writeQueueLock lock];
    BOOL result = [db executeUpdate: @"DELETE FROM ZCACHE WHERE ztileHash IN (SELECT ztileHash FROM ZCACHE ORDER BY zlastUsed LIMIT ? )", [NSNumber numberWithUnsignedInt: count]];
    [db executeQuery:@"VACUUM"];
    tileCount = [self countTiles];
    [writeQueueLock unlock];

    if (result == NO) {
        RMLog(@"Error purging cache");
    }        
}

-(void) removeAllCachedImages 
{
    [writeQueue addOperationWithBlock:^{
        [writeQueueLock lock];
        BOOL result = [db executeUpdate: @"DELETE FROM ZCACHE"];
        [db executeQuery:@"VACUUM"];
        [writeQueueLock unlock];

        if (result == NO) {
            RMLog(@"Error purging all cache");
        }
        
        tileCount = [self countTiles];
    }];
}

-(void) touchTile: (uint64_t) tileHash withDate: (NSDate*) date
{
    [writeQueue addOperationWithBlock:^{
        [writeQueueLock lock];
        BOOL result = [db executeUpdate: @"UPDATE ZCACHE SET zlastUsed = ? WHERE ztileHash = ? ", date, [NSNumber numberWithUnsignedInt: tileHash]];
        [writeQueueLock unlock];

        if (result == NO) {
            RMLog(@"Error touching tile");
        }
    }];
}

-(void) addData: (NSData*) data LastUsed: (NSDate*)date ForTile: (uint64_t) tileHash
{
    [writeQueue addOperationWithBlock:^{
//        RMLog(@"addData\t%d", tileHash);
        
        [writeQueueLock lock];
        BOOL result = [db executeUpdate:@"INSERT OR IGNORE INTO ZCACHE (ztileHash, zlastUsed, zdata) VALUES (?, ?, ?)", 
                       [NSNumber numberWithUnsignedLongLong:tileHash], date, data];
        [writeQueueLock unlock];

        if (result == NO)
        {
            RMLog(@"Error occured adding data");
        } else
            tileCount++;
    }];
}

-(void)didReceiveMemoryWarning
{
    RMLog(@"Low memory in the tilecache");
    [writeQueue cancelAllOperations];
}

@end
