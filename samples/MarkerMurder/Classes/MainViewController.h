//
//  MainViewController.h
//  SampleMap : Diagnostic map
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"

@interface MainViewController : UIViewController <RMMapViewDelegate>

@property (nonatomic, retain) IBOutlet RMMapView *mapView;
@property (nonatomic, retain) IBOutlet UITextView *infoTextView;
@property (nonatomic, retain) IBOutlet UILabel *mppLabel;
@property (nonatomic, retain) IBOutlet UIImageView *mppImage;

- (void)updateInfo;

@end
