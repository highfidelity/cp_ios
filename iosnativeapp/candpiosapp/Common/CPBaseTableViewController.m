//
//  CPBaseTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPBaseTableViewController.h"

@interface CPBaseTableViewController ()
@property (nonatomic, assign) BOOL showingHUD;

@end

@implementation CPBaseTableViewController
@synthesize delegate = _delegate;
@synthesize barSpinner = _barSpinner;
@synthesize showingHUD = _showingHUD;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // alloc-init a UIActivityIndicatorView to put in the navigation item
    self.barSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.barSpinner.hidesWhenStopped = YES;
    
    // set the rightBarButtonItem to that UIActivityIndicatorView 
    [self placeSpinnerOnRightBarButtonItem];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // dismiss our HUD if we were showing one
    if (self.showingHUD) {
        [SVProgressHUD dismiss];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)placeSpinnerOnRightBarButtonItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.barSpinner]; 
}

- (void)showCorrectLoadingSpinnerForCount:(int)count
{
    // show a progress hud if we don't have anybody
    // or show the spinner in the navigation item
    if (count > 0) {
        [self.barSpinner startAnimating];
    } else {
        self.showingHUD = YES;
        [SVProgressHUD showWithStatus:@"Loading..."];
    }
}

- (void)stopAppropriateLoadingSpinner
{
    // dismiss the SVProgressHUD and reload our data
    // or stop the navigationItem spinner
    if (self.showingHUD) {
        [SVProgressHUD dismiss];
        self.showingHUD = NO;
    } else {
        [self.barSpinner stopAnimating];
    }
}

- (void)scrollTableViewToBottomAnimated:(BOOL)animated
{
    // scroll to the bottom of the tableView
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height) animated:animated];
}

@end
