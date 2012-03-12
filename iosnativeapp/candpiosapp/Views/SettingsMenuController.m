//
//  SettingsMenuController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SettingsMenuController.h"
#import "BalanceViewController.h"
#import "AppDelegate.h"
#import "MapTabController.h"
#import "CPapi.h"

#define logoutMenuIndex 1
#define menuWidthPercentage 0.8

@interface SettingsMenuController() 

@property (nonatomic, retain) NSArray *menuStringsArray;
@property (nonatomic, retain) NSArray *menuSegueIdentifiersArray;
@property (nonatomic) CGPoint panStartLocation;
@property (strong, nonatomic) UITapGestureRecognizer *menuCloseGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanFromNavbarGestureRecognizer;

-(void)setMapAndButtonsViewXOffset:(CGFloat)xOffset;

@end


@implementation SettingsMenuController

@synthesize mapTabController;
@synthesize tableView;
@synthesize frontViewController;
@synthesize isMenuShowing;
@synthesize edgeShadow;
@synthesize menuStringsArray;
@synthesize menuSegueIdentifiersArray;
@synthesize menuCloseGestureRecognizer;
@synthesize menuClosePanGestureRecognizer;
@synthesize menuClosePanFromNavbarGestureRecognizer;
@synthesize panStartLocation;
@synthesize f2fInviteAlert = _f2fInviteAlert;
@synthesize f2fPasswordAlert = _f2fPasswordAlert;
@synthesize citySwitch;
@synthesize venueSwitch;
@synthesize checkedInSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)initMenu 
{
    // Setup the menu strings and seque identifiers
    // COMMENTING OUT FOR FIRST BUILD
    // Face To Face and Settings aren't showing anything
//    self.menuStringsArray = [NSArray arrayWithObjects:
//                             @"Face To Face", 
//                             @"Wallet",
//                             @"Settings",
//                             @"Logout",
//                             nil];
    
//    self.menuSegueIdentifiersArray = [NSArray arrayWithObjects:
//                                      @"ShowFaceToFaceFromMenu", 
//                                      @"ShowBalanceFromMenu",
//                                      @"ShowSettingsFromMenu",
//                                      @"ShowLogoutFromMenu",
//                                      nil];
    
    // Setup the menu strings and seque identifiers
    self.menuStringsArray = [NSArray arrayWithObjects:
                             @"Wallet",
                             @"Logout",
                             nil];
    
    self.menuSegueIdentifiersArray = [NSArray arrayWithObjects:
                                      @"ShowBalanceFromMenu",
                                      @"ShowLogoutFromMenu",
                                      nil];
    
    
    
    
}

- (void)loadNotificationSettings
{
    [CPapi getNotificationSettingsWithCompletition:^(NSDictionary *json, NSError *err) {
        BOOL error = [[json objectForKey:@"error"] boolValue];
        
        NSLog(@"notif. rec.: %@", json); 
        
        if (error) {
            [self setVenue:[AppDelegate instance].settings.notifyInVenueOnly];
            [self setCheckin:[AppDelegate instance].settings.notifyWhenCheckedIn];
        } else {
            NSDictionary *dict = [json objectForKey:@"payload"];
            
            
            NSString *venue = [dict objectForKey:@"push_distance"];
            BOOL is_venue = [venue isEqualToString:@"venue"];
            NSString *checkin = [dict objectForKey:@"checked_in_only"];
            BOOL is_checkin = [checkin isEqualToString:@"1"];
            
            [self setVenue:is_venue];
            [self setCheckin:is_checkin];
            
            [AppDelegate instance].settings.notifyInVenueOnly = venue;
            [AppDelegate instance].settings.notifyWhenCheckedIn = checkin;
            [[AppDelegate instance] saveSettings];
        }
    }];
}

- (void)saveNotificationSettings
{
    NSString *distance = venueSwitch.on ? @"venue" : @"city";
    [CPapi setNotificationSettingsForDistance:distance
                                 andCheckedId:checkedInSwitch.on];
    
    [AppDelegate instance].settings.notifyInVenueOnly = venueSwitch.on;
    [AppDelegate instance].settings.notifyWhenCheckedIn = checkedInSwitch.on;
    [[AppDelegate instance] saveSettings];   
}

- (void)setCheckin:(BOOL)setCheckin
{
    [checkedInSwitch setOn:setCheckin animated:YES];
}

- (void)setVenue:(BOOL)setVenue
{
    [citySwitch setOn:!setVenue animated:YES];
    [venueSwitch setOn:setVenue animated:YES];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Alert View Setters

- (void)setF2fInviteAlert:(UIAlertView *)f2fInviteAlert
{
    _f2fInviteAlert = f2fInviteAlert;
    _f2fInviteAlert.delegate = self;
}

- (void)setF2fPasswordAlert:(UIAlertView *)f2fPasswordAlert 
{
    _f2fPasswordAlert = f2fPasswordAlert;
    _f2fPasswordAlert.delegate = self;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view bringSubviewToFront:self.edgeShadow];    
    [self initMenu];
}

- (void)viewWillUnload
{
    if ([AppDelegate instance].settings.notifyInVenueOnly != 1 ||
        [AppDelegate instance].settings.notifyWhenCheckedIn !=1 ) {
        
        [AppDelegate instance].settings.notifyInVenueOnly = 1;
        [AppDelegate instance].settings.notifyWhenCheckedIn = 1;
        
        //save
    }
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setEdgeShadow:nil];
    [self setCitySwitch:nil];
    [self setVenueSwitch:nil];
    [self setCheckedInSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)menuClosePan:(UIPanGestureRecognizer*) sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // record the start location
        panStartLocation = [sender locationInView:self.view];
    } else if (sender.state == UIGestureRecognizerStateChanged ||
               sender.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [sender locationInView:self.view];
        CGFloat dx = location.x - panStartLocation.x;
        CGFloat menuWidth = menuWidthPercentage * [UIScreen mainScreen].bounds.size.width;
        if (sender.state == UIGestureRecognizerStateChanged) { 
            // move the map, buttons and shadow
            if (dx < -menuWidth) {
                dx = -menuWidth;
            } else if (dx > 0) {
                dx = 0;
            }
            [self setMapAndButtonsViewXOffset:menuWidth + dx];            
        } else if (sender.state == UIGestureRecognizerStateEnded) {
            // test the drop point and set the menu state accordingly        
            if (dx < -0.2 * menuWidth) { 
                [self showMenu:NO];
            } else {
                [self showMenu:YES];
            }
        }        
    }
}

- (void)closeMenu {
    [self showMenu:NO];
}

- (void)setMapAndButtonsViewXOffset:(CGFloat)xOffset {
    self.frontViewController.view.frame = CGRectOffset(self.view.bounds, xOffset, 0);
    self.edgeShadow.frame = CGRectOffset(self.edgeShadow.bounds, xOffset - self.edgeShadow.frame.size.width, 0);
}


- (IBAction)switchValueChanged:(id)sender {
    if (sender == citySwitch) {
        [self setVenue:!citySwitch.on];
    } else {
        [self setVenue:venueSwitch.on];
    }
}

- (void)showMenu:(BOOL)showMenu {
    
    if (showMenu) {
        [self loadNotificationSettings];   
    }
    else {
        [self saveNotificationSettings];
    }
    // Animate the reveal of the menu
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.3];
    
    float shift = menuWidthPercentage * [UIScreen mainScreen].bounds.size.width;
    CPMapView* mapView = (CPMapView*)[self.frontViewController.view viewWithTag:mapTag];
    if (showMenu) {
        // shift to the right, hiding buttons 
        [self setMapAndButtonsViewXOffset:shift];
        
        [[AppDelegate instance] hideCheckInButton];
        mapView.scrollEnabled = NO;
        if (!self.menuCloseGestureRecognizer) {
            // Tap to close gesture recognizer
            self.menuCloseGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
            self.menuCloseGestureRecognizer.numberOfTapsRequired = 1;
            [mapView addGestureRecognizer:self.menuCloseGestureRecognizer];
        }
        if (!self.menuClosePanGestureRecognizer) { 
            // Pan to close gesture recognizer
            self.menuClosePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuClosePan:)];
            [mapView addGestureRecognizer:self.menuClosePanGestureRecognizer];
        }
        if (!self.menuClosePanFromNavbarGestureRecognizer) { 
            // Pan to close from navbar
            self.menuClosePanFromNavbarGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuClosePan:)];
            [self.mapTabController.navigationController.navigationBar addGestureRecognizer:menuClosePanFromNavbarGestureRecognizer];            
        }
    } else {
        // shift to the left, restoring the buttons
        [self setMapAndButtonsViewXOffset:0];
        [[AppDelegate instance] showCheckInButton];
        mapView.scrollEnabled = YES;                                   
        // remove gesture recognizers
        [mapView removeGestureRecognizer:self.menuCloseGestureRecognizer];
        self.menuCloseGestureRecognizer = nil;
        [mapView removeGestureRecognizer:self.menuClosePanGestureRecognizer];
        self.menuClosePanGestureRecognizer = nil;
        [self.mapTabController.navigationController.navigationBar removeGestureRecognizer:self.menuClosePanFromNavbarGestureRecognizer];
        self.menuClosePanFromNavbarGestureRecognizer = nil;
    }
    [UIView commitAnimations];
    isMenuShowing = showMenu ? 1 : 0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return menuStringsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        // Style the cell's font and background. clear the background colors so style is not obstructed.
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0];
        cell.textLabel.textColor = [UIColor colorWithRed:169.0/255.0 green:169.0/255.0 blue:169.0/255.0 alpha:1];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"menu-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:2.0]];  
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"selected-menu-background.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:2.0]];
        cell.accessoryView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"accessory-arrow.png"]];
    }
    cell.textLabel.text = (NSString*)[self.menuStringsArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Check to see if our login is valid, using the user name for the header
	if([AppDelegate instance].settings.candpUserId ||
	   [[AppDelegate instance].facebook isSessionValid])
	{
		return [AppDelegate instance].settings.userNickname;
	}
	else
	{
		return @"";
	}
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    float tableHeight = [self tableView:aTableView heightForHeaderInSection:section];
    NSString *headerString = [self tableView:aTableView titleForHeaderInSection:section];
    CGRect headerRect = CGRectMake(10,0,aTableView.frame.size.width,tableHeight);
    UIView *headerView = [[UIImageView alloc] initWithFrame:headerRect];  
    headerView.backgroundColor = [UIColor colorWithRed:(45.0/255.0) green:(45.0/255.0) blue:(45.0/255.0) alpha:1.0];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerRect];
    headerLabel.textAlignment = UITextAlignmentLeft;
    headerLabel.text = headerString;
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor colorWithRed:(201.0/255.0) green:(201.0/255.0) blue:(201.0/255.0) alpha:1.0];
    headerLabel.font = [UIFont boldSystemFontOfSize:18.0];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return  40.0;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Handle the selected menu item, closing the menu for when we return
    if (indexPath.row == logoutMenuIndex) { 
        //TODO: Merge logout xib with storyboard, adding segue for logout
        if (self.isMenuShowing) { [self showMenu:NO]; }
        [self.mapTabController logoutButtonTapped];
        [self.mapTabController loginButtonTapped];
    } else { 
        // for right now this is the wallet so let's slide over to there
        [self showUserWallet];
    }
}

- (void)showUserWallet
{
    [self performSegueWithIdentifier:@"ShowBalanceFromMenu" sender:self];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && [[alertView buttonTitleAtIndex:1] isEqualToString:@"Wallet"]) {
        // the user wants to see their wallet, so let's do that
        [self showUserWallet];
    }
    alertView = nil;
}


@end
