//
//  SettingsMenuController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPCheckinHandler.h"
#import "CPGeofenceHandler.h"
#import "CPUserSessionHandler.h"

#define menuWidthPercentage 0.8
#define kEnterInviteFakeSegueID @"--kEnterInviteFakeSegueID"

@interface SettingsMenuController() <UITabBarControllerDelegate>

@property (strong, nonatomic) NSArray *menuStringsArray;
@property (strong, nonatomic) NSArray *menuSegueIdentifiersArray;
@property (strong, nonatomic) UITapGestureRecognizer *menuCloseGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanFromNavbarGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanFromTabbarGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *menuCloseTapFromTabbarGestureRecognizer;
@property (nonatomic) CGPoint panStartLocation;

- (void)setMapAndButtonsViewXOffset:(CGFloat)xOffset;

@end

@implementation SettingsMenuController

- (void)initMenu 
{
    NSString *inviteItemName = @"Invite";
    NSString *inviteItemSegue = @"ShowInvitationCodeMenu";
    
    if (![CPUserDefaultsHandler currentUser].enteredInviteCode) {
        inviteItemName = @"Enter invite code";
        inviteItemSegue = kEnterInviteFakeSegueID;
    }
    
    // Setup the menu strings and seque identifiers
    self.menuStringsArray = [NSArray arrayWithObjects:
                             // @"Face To Face", DISABLED (alexi)
                             inviteItemName,
                             // @"Wallet", DISABLED (WL #17339 - andyast)
                             @"Profile",
                             @"Linked Accounts",
                             @"Notifications",
                             @"Support",
                             @"Logout",
                             nil];
    
    self.menuSegueIdentifiersArray = [NSArray arrayWithObjects:
                                      inviteItemSegue,
                                      // @"ShowFaceToFaceFromMenu", DISABLED (alexi)
                                      // @"ShowBalanceFromMenu", DISABLED (WL #17339 - andyast)
                                      @"ShowUserSettingsFromMenu",
                                      @"ShowFederationFromMenu",
                                      @"ShowNotificationsFromMenu",
                                      @"ShowSupportFromMenu",
                                      @"ShowLogoutFromMenu",
                                      nil];
    
    [self.tableView reloadData];
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view bringSubviewToFront:self.edgeShadow];    
    [self initMenu];
    
    [CPUIHelper makeButtonCPButton:self.loginButton
                 withCPButtonColor:CPButtonTurquoise];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performAfterLoginActionIfRequired)
                                                 name:@"LoginStateChanged"
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initMenu];
}

- (void)menuClosePan:(UIPanGestureRecognizer*) sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // record the start location
        self.panStartLocation = [sender locationInView:self.view];
    } else if (sender.state == UIGestureRecognizerStateChanged ||
               sender.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [sender locationInView:self.view];
        CGFloat dx = location.x - self.panStartLocation.x;
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
    self.cpTabBarController.view.frame = CGRectOffset(self.view.bounds, xOffset, 0);
    self.edgeShadow.frame = CGRectOffset(self.edgeShadow.bounds, xOffset - self.edgeShadow.frame.size.width, 0);
}

- (void)showMenu:(BOOL)showMenu {
    
    if (showMenu) {
        [self initMenu];
    }

    // Animate the reveal of the menu
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.3];
    
    float shift = menuWidthPercentage * [UIScreen mainScreen].bounds.size.width;
    
    int touchViewTag = 3040;
    
    UINavigationController *visibleNC = (UINavigationController *)self.cpTabBarController.selectedViewController;
    UIViewController *visibleVC = visibleNC.visibleViewController; 
    
    // make sure we have a touchView layer
    UIView *touchView = [visibleVC.view viewWithTag:touchViewTag];
    
    if (!touchView) {
        // place an invisible view over the VC's view to handle touch
        CGRect touchFrame = CGRectMake(0, 0, visibleVC.view.frame.size.width, visibleVC.view.frame.size.height);
        touchView = [[UIView alloc] initWithFrame:touchFrame];
        touchView.tag = touchViewTag;
        [visibleVC.view addSubview:touchView];        
    }   
    
    // make sure we have a tabTouch layer over the tabBar
    UIView *tabTouch = [self.cpTabBarController.tabBar viewWithTag:touchViewTag];
    
    if (!tabTouch) {
        // place an invisible view over the tab bar to handle tap
        CGRect tabFrame = CGRectMake(0, 0, self.cpTabBarController.tabBar.frame.size.width, self.cpTabBarController.tabBar.frame.size.height);
        tabTouch = [[UIView alloc] initWithFrame:tabFrame];
        tabTouch.tag = touchViewTag;
        [self.cpTabBarController.tabBar addSubview:tabTouch];
    }
   
    if (showMenu) {
        
        // shift to the right, hiding buttons 
        [self setMapAndButtonsViewXOffset:shift];
        
        if (!self.menuCloseGestureRecognizer) {
            // Tap to close gesture recognizer
            self.menuCloseGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
            self.menuCloseGestureRecognizer.numberOfTapsRequired = 1;
            self.menuCloseGestureRecognizer.cancelsTouchesInView = YES;
            [touchView addGestureRecognizer:self.menuCloseGestureRecognizer];
        }
        if (!self.menuClosePanGestureRecognizer) { 
            // Pan to close gesture recognizer
            self.menuClosePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuClosePan:)];
            [touchView addGestureRecognizer:self.menuClosePanGestureRecognizer];
        }
        if (!self.menuClosePanFromNavbarGestureRecognizer) { 
            // Pan to close from navbar
            self.menuClosePanFromNavbarGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuClosePan:)];
            [visibleVC.navigationController.navigationBar addGestureRecognizer:self.menuClosePanFromNavbarGestureRecognizer];
        }
        if (!self.menuClosePanFromTabbarGestureRecognizer) {
            // Pan to close from tab bar
            self.menuClosePanFromTabbarGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuClosePan:)];
            [tabTouch addGestureRecognizer:self.menuClosePanFromTabbarGestureRecognizer];
        }
        if (!self.menuCloseTapFromTabbarGestureRecognizer) {
            // Tap to close from tab bar
            self.menuCloseTapFromTabbarGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
            [tabTouch addGestureRecognizer:self.menuCloseTapFromTabbarGestureRecognizer];
        }
    } else {
        // shift to the left, restoring the buttons
        [self setMapAndButtonsViewXOffset:0];
                                   
        // remove gesture recognizers
        [touchView removeGestureRecognizer:self.menuCloseGestureRecognizer];
        self.menuCloseGestureRecognizer = nil;
        [touchView removeGestureRecognizer:self.menuClosePanGestureRecognizer];
        self.menuClosePanGestureRecognizer = nil;
        
        // remove the touch view from the VC
        [touchView removeFromSuperview];
        
        [visibleVC.navigationController.navigationBar removeGestureRecognizer:self.menuClosePanFromNavbarGestureRecognizer];
        self.menuClosePanFromNavbarGestureRecognizer = nil;
        
        [tabTouch removeGestureRecognizer:self.menuClosePanFromTabbarGestureRecognizer];
        self.menuClosePanFromTabbarGestureRecognizer = nil; 
        
        [tabTouch removeGestureRecognizer:self.menuCloseTapFromTabbarGestureRecognizer];
        self.menuCloseTapFromTabbarGestureRecognizer = nil; 
        
        // remove the tab touch view from the tab bar
        [tabTouch removeFromSuperview];
        
    }
    [UIView commitAnimations];
    self.isMenuShowing = showMenu ? 1 : 0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuStringsArray.count;
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
	if([CPUserDefaultsHandler currentUser])
	{
		return [CPUserDefaultsHandler currentUser].nickname;
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
        if (self.isMenuShowing) { 
            [self showMenu:NO]; 
        }
        
        // logout and show the signup modal
        [CPUserSessionHandler showSignupModalFromViewController:self animated:YES];

    } else {
        NSString *segueID = [self.menuSegueIdentifiersArray objectAtIndex:indexPath.row];
        NSLog(@"You clicked on %@", segueID);
        
        if ([kEnterInviteFakeSegueID isEqual:segueID]) {
            [CPUserSessionHandler showEnterInvitationCodeModalFromViewController:self
                                     withDontShowTextNoticeAfterLaterButtonPressed:YES
                                                                      pushFromLeft:YES
                                                                          animated:YES];
        } else {
            [self performSegueWithIdentifier:segueID sender:self];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && [[alertView buttonTitleAtIndex:1] isEqualToString:@"Wallet"]) {
        // the user wants to see their wallet, so let's do that
        [self performSegueWithIdentifier:@"ShowBalanceFromMenu" sender:self];
    } else if (alertView.tag == 904 && buttonIndex == 1) {
        [SVProgressHUD showWithStatus:@"Checking out..."];
        
        [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
            
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            if (!error && !respError) {
                
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                [[CPCheckinHandler sharedHandler] setCheckedOut];
                
                NSDictionary *jsonDict = [json objectForKey:@"payload"];
                NSString *venue = [jsonDict valueForKey:@"venue_name"];
                
                NSMutableString *message = [NSMutableString stringWithFormat:@"Checked out of %@.", venue];
                int hours = [[jsonDict valueForKey:@"hours_checked_in"] intValue];
                if (hours == 1) {
                    [message appendString:@" You were there for 1 hour."];
                } else if (hours > 1) {
                    [message appendFormat:@" You were there for %d hours.", hours];
                }
                
                [SVProgressHUD showSuccessWithStatus:message 
                                            duration:kDefaultDismissDelay];
            } else {
                NSString *message = [json objectForKey:@"payload"];
                if (!message) {
                    message = @"Oops. Something went wrong.";    
                }
                [SVProgressHUD dismissWithError:message
                                     afterDelay:kDefaultDismissDelay];
            }
        }];
    } else if (alertView.tag = AUTOCHECKIN_PROMPT_TAG) {
        // this alert view is shown if the user has just checked into a new venue
        // and we want to ask them if they'd like to autocheckin here in the future
        
        CPVenue *autoPromptVenue = [CPUserDefaultsHandler currentVenue];
        if (alertView.firstOtherButtonIndex == buttonIndex) {
            // Start monitoring the new location to allow auto-checkout and checkin (if enabled) 
            autoPromptVenue.autoCheckin = YES;
            [[CPGeofenceHandler sharedHandler] startMonitoringVenue:autoPromptVenue];
            [FlurryAnalytics logEvent:@"autoCheckInPromptAccepted"];
        }
        else if (buttonIndex == 2) {
            autoPromptVenue.autoCheckin = NO;
            // User does NOT want to automatically check in to this venue        
            [[CPGeofenceHandler sharedHandler] stopMonitoringVenue:autoPromptVenue];
            [FlurryAnalytics logEvent:@"autoCheckInPromptDenied"];
        }
    
        // add this venue to the array of past venues in NSUserDefaults
        // with the correct autoCheckin status
        [[CPGeofenceHandler sharedHandler] updatePastVenue:autoPromptVenue];
    }
}

#pragma mark - Login banner
- (IBAction)blockUIButtonClick:(id)sender
{
    // reset the after login action
    self.afterLoginAction = CPAfterLoginActionNone;
    
    // hide the login banner
    [CPUserSessionHandler hideLoginBannerWithCompletion:nil];
}

- (IBAction)loginButtonClick:(id)sender
{
    [CPUserSessionHandler hideLoginBannerWithCompletion:^ {
        [CPUserSessionHandler showSignupModalFromViewController:[CPAppDelegate tabBarController]
                                                animated:YES];
    }];
}

#pragma mark - CPAfterLoginAction Handler
- (void)performAfterLoginActionIfRequired
{
    if ([CPUserDefaultsHandler currentUser]) {
        // we have a current user so check if the settings menu controller has an action to perform after login
        switch (self.afterLoginAction) {
            case CPAfterLoginActionShowLogbook:
                // show the logbook
                [CPAppDelegate tabBarController].selectedIndex = 0;
                break;
            case CPAfterLoginActionAddNewLog:
                // show the logbook and allow the user to enter a new log entry
                [[CPAppDelegate tabBarController] updateButtonPressed:nil];
                break;
            case CPAfterLoginActionPostQuestion:
                [[CPAppDelegate tabBarController] questionButtonPressed:nil];
                break;
            case CPAfterLoginActionShowMap:
                [CPAppDelegate tabBarController].selectedIndex = 1;
            default:
                // do nothing, the action is CPAfterLoginActionNone
                break;
        }
    }
}

@end
