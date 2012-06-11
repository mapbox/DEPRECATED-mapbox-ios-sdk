//
//  RootViewController.m
//  SampleMap : Diagnostic map
//

#import "RootViewController.h"
#import "MainViewController.h"
#import "FlipsideViewController.h"

@implementation RootViewController

@synthesize infoButton;
@synthesize flipsideNavigationBar;
@synthesize mainViewController;
@synthesize flipsideViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];

    MainViewController *viewController = [[[MainViewController alloc] initWithNibName:@"MainView" bundle:nil] autorelease];
    self.mainViewController = viewController;

    [self.view insertSubview:mainViewController.view belowSubview:infoButton];
}

- (void)loadFlipsideViewController
{
    FlipsideViewController *viewController = [[[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil] autorelease];
    self.flipsideViewController = viewController;

    // Set up the navigation bar
    UINavigationBar *aNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)] autorelease];
    aNavigationBar.barStyle = UIBarStyleBlackOpaque;
    self.flipsideNavigationBar = aNavigationBar;

    UIBarButtonItem *buttonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleView)] autorelease];
    UINavigationItem *navigationItem = [[[UINavigationItem alloc] initWithTitle:@"SampleMap"] autorelease];
    navigationItem.rightBarButtonItem = buttonItem;
    [flipsideNavigationBar pushNavigationItem:navigationItem animated:NO];
}

- (IBAction)toggleView
{
    /*
     This method is called when the info or Done button is pressed.
     It flips the displayed view from the main view to the flipside view and vice-versa.
     */
    if (flipsideViewController == nil)
        [self loadFlipsideViewController];

    UIView *mainView = mainViewController.view;
    UIView *flipsideView = flipsideViewController.view;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1];
    [UIView setAnimationTransition:([mainView superview] ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft) forView:self.view cache:YES];

    if ([mainView superview] != nil)
    {
        [flipsideViewController viewWillAppear:YES];
        [mainViewController viewWillDisappear:YES];
        [mainView removeFromSuperview];
        [infoButton removeFromSuperview];
        [self.view addSubview:flipsideView];
        [self.view insertSubview:flipsideNavigationBar aboveSubview:flipsideView];
        [mainViewController viewDidDisappear:YES];
        [flipsideViewController viewDidAppear:YES];
    }
    else
    {
        [mainViewController viewWillAppear:YES];
        [flipsideViewController viewWillDisappear:YES];
        [flipsideView removeFromSuperview];
        [flipsideNavigationBar removeFromSuperview];
        [self.view addSubview:mainView];
        [self.view insertSubview:infoButton aboveSubview:mainViewController.view];
        [flipsideViewController viewDidDisappear:YES];
        [mainViewController viewDidAppear:YES];
    }

    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning
{
	RMLog(@"didReceiveMemoryWarning %@", self);
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc
{
    self.infoButton = nil;
    self.flipsideNavigationBar = nil;
    self.mainViewController = nil;
    self.flipsideViewController = nil;
    [super dealloc];
}

@end
