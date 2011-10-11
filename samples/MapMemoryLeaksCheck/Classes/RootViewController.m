//
//  RootViewController.m
//  MapMemoryLeaksCheck
//
//  Created by Thomas Rasch on 11.10.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RootViewController.h"

#import "MapViewController.h"

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
        return nil;

    return self;
}

- (void)loadView
{
    [super loadView];

    CGRect bounds = self.view.bounds;

    UIButton *showMapButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    showMapButton.frame = CGRectMake(10.0, bounds.size.height - 100.0, bounds.size.width-20.0, 44.0);
    [showMapButton setTitle:@"Show the map" forState:UIControlStateNormal];
    [showMapButton addTarget:self action:@selector(showTheMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:showMapButton];
}

- (void)showTheMap
{
    MapViewController *mapViewController = [[[MapViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    [self.navigationController pushViewController:mapViewController animated:YES];
}

@end
