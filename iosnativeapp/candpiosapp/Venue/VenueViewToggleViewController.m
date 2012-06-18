//
//  VenueViewToggleViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueViewToggleViewController.h"
#import "VenueListTableViewController.h"

@interface VenueViewToggleViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) MapTabController *venueMapController;
@property (strong, nonatomic) VenueListTableViewController *venueListController;

@end

@implementation VenueViewToggleViewController
@synthesize segmentedControl = _segmentedControl;
@synthesize venueMapController = _venueMapController;
@synthesize venueListController = _venueListController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // use league gothic for the text in the segmented control
    [self.segmentedControl setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:16] forKey:UITextAttributeFont] forState:UIControlStateNormal];
	
    // grab both view controllers from the storyboard
    self.venueMapController = [CPAppDelegate settingsMenuController].mapTabController;
    self.venueListController = [self.storyboard instantiateViewControllerWithIdentifier:@"venueListController"];
    
    // add both of the view controllers as our child view controllers
    [self addChildViewController:self.venueMapController];
    [self addChildViewController:self.venueListController];
    
    // the map is our default view controller
    [self showViewController:self.venueMapController];
}

- (void)viewDidUnload
{
    [self setSegmentedControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    UIViewController *currentVC = sender.selectedSegmentIndex ? self.venueMapController : self.venueListController;
    UIViewController *nextVC = sender.selectedSegmentIndex ? self.venueListController : self.venueMapController;

    [currentVC.view removeFromSuperview];
    
    [self showViewController:nextVC];
}

- (void)showViewController:(UIViewController *)newVC
{
    newVC.view.frame = self.view.bounds;
    [self.view addSubview:newVC.view];
    self.title = newVC.title;
}

@end
