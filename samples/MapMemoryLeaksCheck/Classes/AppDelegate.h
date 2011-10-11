//
//  ProgrammaticMapAppDelegate.h
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

