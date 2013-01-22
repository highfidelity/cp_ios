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

@property (strong, nonatomic) MapTabController *venueMapController;
@property (strong, nonatomic) VenueListTableViewController *venueListController;

- (void)mapListTogglePressed:(id)mapListTogglePressed;

@end

@implementation VenueViewToggleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"List"
                                                                                  style:UIBarButtonItemStylePlain 
                                                                                 target:self 
                                                                                 action:@selector(mapListTogglePressed:)]];

    // grab both view controllers from the storyboard
    self.venueMapController = [CPAppDelegate settingsMenuViewController].mapTabController;
    self.venueListController = [self.storyboard instantiateViewControllerWithIdentifier:@"venueListController"];
    
    // add both of the view controllers as our child view controllers
    [self addChildViewController:self.venueMapController];
    [self addChildViewController:self.venueListController];
    
    // the map is our default view controller
    [self showViewController:self.venueMapController];
}

- (void)mapListTogglePressed:(UIBarButtonItem *)sender
{
    UIViewController *currentVC = [sender.title isEqualToString:@"List"] ? self.venueMapController : self.venueListController;
    UIViewController *nextVC = [sender.title isEqualToString:@"List"] ? self.venueListController : self.venueMapController;

    sender.title = [sender.title isEqualToString:@"List"] ? @"Map": @"List";

    [currentVC.view removeFromSuperview];

    [self showViewController:nextVC];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)showViewController:(UIViewController *)newVC
{
    newVC.view.frame = self.view.bounds;
    [self.view addSubview:newVC.view];
    self.title = newVC.title;
}

@end
