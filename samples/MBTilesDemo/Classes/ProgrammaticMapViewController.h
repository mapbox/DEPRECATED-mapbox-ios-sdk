//
//  ProgrammaticMapViewController.h
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RMMapView.h"

@interface ProgrammaticMapViewController : UIViewController <RMMapViewDelegate>

@property(nonatomic, retain) RMMapView *mapView;

- (IBAction)swtichTilesource:(id)sender;

@end

