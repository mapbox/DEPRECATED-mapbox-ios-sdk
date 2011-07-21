//
//  Sample2AppDelegate.m
//  SampleMap : Diagnostic map
//

#import "SampleMapAppDelegate.h"
#import "RootViewController.h"
#import "MainViewController.h"

@implementation SampleMapAppDelegate

@synthesize window;
@synthesize rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{    
    [window addSubview:[rootViewController view]];
    [window makeKeyAndVisible];
}

- (void)dealloc
{
    [rootViewController release];
    [window release];
    [super dealloc];
}

@end
