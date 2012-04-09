//
//  SettingsMenuController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SettingsMenuController.h"
#import "BalanceViewController.h"
#import "MapTabController.h"

#define menuWidthPercentage 0.8

@interface SettingsMenuController() 

@property (nonatomic, retain) NSArray *menuStringsArray;
@property (nonatomic, retain) NSArray *menuSegueIdentifiersArray;
@property (nonatomic) CGPoint panStartLocation;
@property (strong, nonatomic) UITapGestureRecognizer *menuCloseGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanFromNavbarGestureRecognizer;

-(void)setMapAndButtonsViewXOffset:(CGFloat)xOffset;
- (void)setCheckin:(BOOL)setCheckin;
- (void)setVenue:(BOOL)setVenue;

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
@synthesize venueButton;
@synthesize checkedInOnlyButton;

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
    self.menuStringsArray = [NSArray arrayWithObjects:
                             // @"Face To Face", DISABLED (alexi)
                             @"Invite",
                             @"Wallet",
                             @"Settings",
                             //@"Linked Accounts", DISABLED (alexi)
                             @"Logout",
                             nil];
    
    self.menuSegueIdentifiersArray = [NSArray arrayWithObjects:
                                      @"ShowInvitationCodeMenu",
                                      // @"ShowFaceToFaceFromMenu", DISABLED (alexi)
                                      @"ShowBalanceFromMenu",
                                      @"ShowUserSettingsFromMenu",
                                      // @"ShowFederationFromMenu", DISALBED (alexi)
                                      @"ShowLogoutFromMenu",
                                      nil];

}

- (void)loadNotificationSettings
{
    [CPapi getNotificationSettingsWithCompletition:^(NSDictionary *json, NSError *err) {
        BOOL error = [[json objectForKey:@"error"] boolValue];
        
        if (error) {
            [venueButton setEnabled:NO];
            [checkedInOnlyButton setEnabled:NO];
        } else {
            
            [venueButton setEnabled:YES];
            [checkedInOnlyButton setEnabled:YES];
            
            NSDictionary *dict = [json objectForKey:@"payload"];
            
            NSString *venue = (NSString *)[dict objectForKey:@"push_distance"];
            BOOL is_venue = [venue isEqualToString:@"venue"];
            NSString *checkin = (NSString *)[dict objectForKey:@"checked_in_only"];
            BOOL is_checkin = [checkin isEqualToString:@"1"];
            
            [self setVenue:is_venue];
            [self setCheckin:is_checkin];
            
            [AppDelegate instance].settings.notifyInVenueOnly = is_venue;
            [AppDelegate instance].settings.notifyWhenCheckedIn = is_checkin;
            [[AppDelegate instance] saveSettings];
        }
    }];
}

- (void)saveNotificationSettings
{
    BOOL notifyInVenue = [venueButton tag] == 1;
    BOOL checkedInOnly = [checkedInOnlyButton tag] == 1;
    
    BOOL settingsVenue = [AppDelegate instance].settings.notifyInVenueOnly;
    BOOL settingsCheckedIn = [AppDelegate instance].settings.notifyWhenCheckedIn;
    
    if (notifyInVenue != settingsVenue || checkedInOnly != settingsCheckedIn) {
        NSString *distance = notifyInVenue ? @"venue" : @"city";
        [CPapi setNotificationSettingsForDistance:distance
                                     andCheckedId:checkedInOnly];
        
        [AppDelegate instance].settings.notifyInVenueOnly = notifyInVenue;
        [AppDelegate instance].settings.notifyWhenCheckedIn = checkedInOnly;
        [[AppDelegate instance] saveSettings];   
    }
}

- (void)setCheckin:(BOOL)setCheckin
{
    [checkedInOnlyButton setTag:setCheckin ? 1 : 0];
    UIImage *btnImage = [UIImage imageNamed:setCheckin ? @"toggle-on" : @"toggle-off"];
    [checkedInOnlyButton setBackgroundImage:btnImage forState:UIControlStateNormal];
}

- (void)setVenue:(BOOL)setVenue
{
    if (setVenue) {
        [venueButton setTitle:@"in venue" forState: UIControlStateNormal];
    } 
    else {
        [venueButton setTitle:@"in city" forState: UIControlStateNormal];
    }
    
    [venueButton setTag:setVenue ? 1 : 0];
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
    [self venueButton].titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    
    [self setVenue:[AppDelegate instance].settings.notifyInVenueOnly];
    [self setCheckin:[AppDelegate instance].settings.notifyWhenCheckedIn];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setEdgeShadow:nil];
    [self setVenueButton:nil];
    [self setCheckedInOnlyButton:nil];
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
    MKMapView* mapView = (MKMapView*)[self.frontViewController.view viewWithTag:mapTag];
    if (showMenu) {
        // shift to the right, hiding buttons 
        [self setMapAndButtonsViewXOffset:shift];
        
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
    }
    cell.textLabel.text = (NSString*)[self.menuStringsArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Check to see if our login is valid, using the user name for the header
	if([CPAppDelegate currentUser] ||
	   [[AppDelegate instance].facebook isSessionValid])
	{
		return [CPAppDelegate currentUser].nickname;
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
    [CPUIHelper changeFontForLabel:headerLabel toLeagueGothicOfSize:24.0];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return  40.0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Handle the selected menu item, closing the menu for when we return
    NSInteger logoutRowIndex = [self.menuStringsArray indexOfObject:@"Logout"];
    if (indexPath.row == logoutRowIndex) { 
        //TODO: Merge logout xib with storyboard, adding segue for logout
        if (self.isMenuShowing) { [self showMenu:NO]; }
        [self.mapTabController logoutButtonTapped];
        [self.mapTabController loginButtonTapped];
    } else {
        NSLog(@"You clicked on %@", [self.menuSegueIdentifiersArray objectAtIndex:indexPath.row]);
        [self performSegueWithIdentifier:[self.menuSegueIdentifiersArray objectAtIndex:indexPath.row] sender:self];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && [[alertView buttonTitleAtIndex:1] isEqualToString:@"Wallet"]) {
        // the user wants to see their wallet, so let's do that
        [self performSegueWithIdentifier:@"ShowBalanceFromMenu" sender:self];
    }
    if (alertView.tag == 904 && buttonIndex == 1) {
        [SVProgressHUD showWithStatus:@"Checking out..."];
        
        [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
            
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            
            [SVProgressHUD dismiss];
            if (!error && !respError) {
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                [[AppDelegate instance] setCheckedOut];
            } else {
                
                 
                NSString *message = [json objectForKey:@"payload"];
                if (!message) {
                    message = @"Oops. Something went wrong.";    
                }
                
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"An error occurred"
                                      message:message
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles: nil];
                [alert show];
            }
        }];
    }
    alertView = nil;
}


#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < 2) {
        [self setVenue:buttonIndex == 1];
    }
}


- (IBAction)checkedInButtonClick:(UIButton *)sender 
{
    [self setCheckin:[sender tag] == 0];
}

- (IBAction)selectVenueCity:(id)sender 
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Show me new check-ins from:"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"City", @"Venue", nil
                                  ];
    [actionSheet showInView:self.view];
}
@end
