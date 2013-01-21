//
//  SettingsMenuViewController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SettingsMenuViewController.h"
#import "SettingsMenuView.h"
#import "CPCheckinHandler.h"
#import "CPGeofenceHandler.h"
#import "CPUserSessionHandler.h"
#import "UserVoice.h"
#import "AppDelegate.h"
#import "TutorialViewController.h"
#import "ProfileViewController.h"

#define menuWidthPercentage 0.8
#define kFeedbackSegueID @"ShowFeedbackFromMenu"
#define kTutorialSegueID @"ShowTutorialFromMenu"

@interface SettingsMenuViewController() <UITabBarControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;
@property (strong, nonatomic) NSArray *menuStringsArray;
@property (strong, nonatomic) NSArray *menuAssociatedIdentifiersArray;
@property (strong, nonatomic) UITapGestureRecognizer *menuCloseGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *menuClosePanFromNavbarGestureRecognizer;
@property (strong, nonatomic) UIViewController *currentChildViewController;
@property (nonatomic) CGPoint panStartLocation;

- (void)setMapAndButtonsViewXOffset:(CGFloat)xOffset;

@end

@implementation SettingsMenuViewController

- (void)initMenu 
{
    // Setup the menu strings and seque identifiers
    self.menuStringsArray = [NSArray arrayWithObjects:
                             @"Invite",
                             @"Profile",
                             @"Linked Accounts",
                             @"Notifications",
                             @"Automatic Check Ins",
                             @"Feedback",
                             @"Tutorial",
                             @"Logout",
                             nil];
    
    self.menuAssociatedIdentifiersArray = [NSArray arrayWithObjects:
                                      @"LinkedInConnectionsNC",
                                      @"ProfileViewControllerNC",
                                      @"LinkedAccountsNC",
                                      @"NotificationSettingsNC",
                                      @"GeofenceSettingsNC",
                                      kFeedbackSegueID,
                                      kTutorialSegueID,
                                      @"PerformLogoutFromMenu",
                                      nil];
    
    [self.tableView reloadData];
}

#pragma mark - Alert View Setters

- (void)setF2fInviteAlert:(UIAlertView *)f2fInviteAlert
{
    _f2fInviteAlert = f2fInviteAlert;
    _f2fInviteAlert.delegate = self;
}

#pragma mark - View lifecycle
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
    
    [self placeVersionNumberAndTermsButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initMenu];
}

#pragma mark - Child View Controller Handling

#define PUSH_LEFT_AND_POP_ANIMATION_DURATION 0.35

- (void)setCurrentChildViewController:(UIViewController *)currentChildViewController
{
    if (currentChildViewController) {
        [self addChildViewController:currentChildViewController];
        currentChildViewController.view.frame = CGRectOffset(self.view.bounds, -currentChildViewController.view.frame.size.width, 0);
        [self.view addSubview:currentChildViewController.view];
    }
    
    float shift = [UIScreen mainScreen].bounds.size.width * (!!currentChildViewController ? 1 : -1);
    
    [UIView animateWithDuration:PUSH_LEFT_AND_POP_ANIMATION_DURATION animations:^{
        for (UIView *subview in self.view.subviews) {
            subview.frame = CGRectOffset(subview.frame, shift, 0);
        }
    }];
    
    if (currentChildViewController) {
        ((SettingsMenuView *) self.view).menuChildViewControllerView = currentChildViewController.view;
    } else {
        [currentChildViewController removeFromParentViewController];
    }    
    
    _currentChildViewController = currentChildViewController;
}

- (void)slideAwayChildViewController
{
    self.currentChildViewController = nil;
}

#pragma mark - Menu Movement

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
    
    // add a view in front of the tab bar controller to handle pan and tap
    UINavigationController *visibleNC = (UINavigationController *)self.cpTabBarController.selectedViewController;
    UIView *touchView = [self.cpTabBarController.view viewWithTag:touchViewTag];
    
    if (!touchView) {
        // height of the touch view is the device height, minus navigation bar
        CGFloat navBarHeight = visibleNC.navigationBar.frame.size.height;
        CGFloat touchViewHeight = self.cpTabBarController.view.frame.size.height - navBarHeight;
       
        CGRect touchFrame = CGRectMake(0,
                                       navBarHeight,
                                       self.cpTabBarController.view.frame.size.width,
                                       touchViewHeight);
        touchView = [[UIView alloc] initWithFrame:touchFrame];
        touchView.tag = touchViewTag;
        [self.cpTabBarController.view addSubview:touchView];
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
            [visibleNC.navigationBar addGestureRecognizer:self.menuClosePanFromNavbarGestureRecognizer];
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
        
        [visibleNC.navigationBar removeGestureRecognizer:self.menuClosePanFromNavbarGestureRecognizer];
        self.menuClosePanFromNavbarGestureRecognizer = nil;
    }
    [UIView commitAnimations];
    self.isMenuShowing = showMenu ? 1 : 0;
}

- (void)placeVersionNumberAndTermsButton
{
    // give the label the current version number
    self.versionNumberLabel.text = [NSString stringWithFormat:@"| v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    
    // grab the frames for the versionNumberLabel and the termsOfServiceButton
    CGRect versionFrame = self.versionNumberLabel.frame;
    CGRect termsFrame = self.termsOfServiceButton.frame;
    
    // shrink the version number label horizontally to just fit the contents
    versionFrame.size.width = [self.versionNumberLabel.text sizeWithFont:self.versionNumberLabel.font].width;
    
    // find total width of both button and label
    CGFloat buttonLabelWidth = termsFrame.size.width + versionFrame.size.width;
    
    // give the TOS button frame its new origin
    termsFrame.origin.x = self.tableView.center.x - (buttonLabelWidth / 2);
    
    // give the version number frame its new origin
    versionFrame.origin.x = termsFrame.origin.x + termsFrame.size.width;
    
    // give both elements their new frames
    self.versionNumberLabel.frame = versionFrame;
    self.termsOfServiceButton.frame = termsFrame;
    
    // ugly way to add an underline to the TOS button that will sit under the text
    
    // make the underline 75% of the width of the button
    CGFloat underlineWidth = 0.75 * termsFrame.size.width;
    
    // alloc-init a 1pt tall underline 
    UIView *underline = [[UIView alloc] initWithFrame:CGRectMake((termsFrame.size.width / 2) - (underlineWidth / 2), termsFrame.size.height - 6, underlineWidth, 1)];
    
    // give it the same color as the text
    underline.backgroundColor = self.termsOfServiceButton.titleLabel.textColor;
    
    // add it to the existing button
    [self.termsOfServiceButton addSubview:underline];
}

- (IBAction)showTermsOfServiceModal:(id)sender
{
    [self performSegueWithIdentifier:@"ShowTermsOfServiceModal" sender:self];
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
    if (!cell) {
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
        if (self.isMenuShowing) { 
            [self showMenu:NO]; 
        }
        
        // logout and show the signup modal
        [CPUserSessionHandler showSignupModalFromViewController:self animated:YES];

    } else {
        NSString *identifierID = [self.menuAssociatedIdentifiersArray objectAtIndex:indexPath.row];
        
        if ([identifierID isEqualToString:kFeedbackSegueID]) {
            UVConfig *config = [UVConfig configWithSite:kUserVoiceSite
                                                 andKey:kUserVoiceKey
                                              andSecret:kUserVoiceSecret];
            [UserVoice presentUserVoiceForumForParentViewController:self andConfig:config];
        } else if ([identifierID isEqualToString:kTutorialSegueID]) {
            UINavigationController *tutorialNC = [[UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil]
                                                  instantiateViewControllerWithIdentifier:@"TutorialViewControllerNavigationViewController"];
            
            ((TutorialViewController *) tutorialNC.topViewController).isShownFromLeft = YES;
            
            self.currentChildViewController = tutorialNC;
        } else {
            UINavigationController *childNC = [self.storyboard instantiateViewControllerWithIdentifier:identifierID];
            self.currentChildViewController = childNC;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 904 && buttonIndex == 1) {
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
            [Flurry logEvent:@"autoCheckInPromptAccepted"];
        }
        else if (buttonIndex == 2) {
            autoPromptVenue.autoCheckin = NO;
            // User does NOT want to automatically check in to this venue        
            [[CPGeofenceHandler sharedHandler] stopMonitoringVenue:autoPromptVenue];
            [Flurry logEvent:@"autoCheckInPromptDenied"];
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
            case CPAfterLoginActionShowMap:
                [CPAppDelegate tabBarController].selectedIndex = 0;
            default:
                // do nothing, the action is CPAfterLoginActionNone
                break;
        }
    }
}

@end
