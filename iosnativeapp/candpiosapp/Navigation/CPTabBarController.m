//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"
#import "LogViewController.h"

@implementation CPTabBarController

// TODO: get rid of the currentVenueID here, let's keep that in NSUserDefaults (my bad)

@synthesize thinBar = _thinBar;
@synthesize currentVenueID = _currentVenueID;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *bgImage = [UIImage imageNamed:@"thin-nav-bg"];
    
    CGFloat heightDiff = self.tabBar.frame.size.height - bgImage.size.height;
    // change the frame of the regular tab bar
    self.tabBar.frame = CGRectMake(self.tabBar.frame.origin.x, 
                                   self.tabBar.frame.origin.y + heightDiff, 
                                   self.tabBar.frame.size.width, 
                                   self.tabBar.frame.size.height - heightDiff);
    
    // add our custom thin bar
    // alloc-init a UIImageView and give it the background image
    self.thinBar = [[CPThinTabBar alloc] initWithFrame:CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height)
                                       backgroundImage:bgImage];
    
    // be the tabBarController for the thinBar
    self.thinBar.tabBarController = self;
    
    // add the UIView to the CPTabBarController's view
    [self.tabBar addSubview:self.thinBar];
    
    // make sure the CPTabBarController's views take up the extra space
    CGRect viewFrame = [[self.view.subviews objectAtIndex:0] frame];
    viewFrame.size.height += heightDiff;
    [[self.view.subviews objectAtIndex:0] setFrame:viewFrame];
    
    // we are always the target for the left button
    [self.thinBar.leftButton addTarget:self action:@selector(addLogButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self refreshTabBar];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTabBar)
                                                 name:@"LoginStateChanged"
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (self.selectedIndex > 0 && 
        self.selectedIndex <= 4 && 
        selectedIndex == 0 && 
        ![CPUserDefaultsHandler currentUser]) {
        // don't change the selected index here
        // just show the login banner
        [self promptForLoginToSeeLogbook:CPAfterLoginActionShowLogbook];
    } else {
        // switch to the designated VC
        [super setSelectedIndex:selectedIndex];
        
        // move the green line to the right spot
        [self.thinBar moveGreenLineToSelectedIndex:selectedIndex];
    }
   
}

- (void)tabBarButtonPressed:(id)sender
{
    // switch to the tab the user just tapped
    int tabIndex = ((UIButton *)sender).tag;
    self.selectedIndex = tabIndex;
}

- (void)refreshTabBar
{
    if (![CPUserDefaultsHandler currentUser]) {
        UIStoryboard *signUpStoryboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
        UINavigationController *signupController = [signUpStoryboard instantiateInitialViewController];
        
        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:3 withObject:signupController];
        self.viewControllers = tabVCArray;
        
        // tell the thinBar to update the button
        [self.thinBar refreshLastTab:NO];
    } else {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                                 bundle:nil];
        UINavigationController *contactsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"contactsNavigationController"];

        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:3 withObject:contactsController];
        self.viewControllers = tabVCArray;
        
        // tell the thinBar to update the button
        [self.thinBar refreshLastTab:YES];
    }  
    
    // make sure the thinBar is in front of the new button
    [self.tabBar bringSubviewToFront:self.thinBar];
    
}

- (IBAction)addLogButtonPressed:(id)sender
{
    // we only get this if the logbook hasn't loaded
    // otherwise the logbook is the new target for that button
    
    // if we don't have a current user then we need to just show the login banner
    if (![CPUserDefaultsHandler currentUser]) {
        [self promptForLoginToSeeLogbook:CPAfterLoginActionAddNewLog];
    } else {
        // let's check if the log has already been loaded
        
        // grab the logbook navigation controller and logbook view controller
        UINavigationController *logNavVC = [self.viewControllers objectAtIndex:0];
        LogViewController *logVC = [logNavVC.viewControllers objectAtIndex:0];
    
        if (self.selectedIndex == 0) {
            // the log view controller is loaded
            // forward the fact that the button has been touched to that VC
            [logVC newLogEntry];
        } else {
            // otherwise they user is logged but we've not yet loaded the logbook
            // we need to tell the logbook that when it finishes loading the user wants to add a new entry
            
            if (!logVC.isViewLoaded) {
                // make the logVC load its view
                [logVC view];
            }
            
            // tell the log view controller that it needs to bring up the keyboard for a new log entry once it loads
            logVC.newLogEntryAfterLoad = YES;
            
            // switch to the logbook 
            self.selectedIndex = 0;
        }       
    }
}

- (void)promptForLoginToSeeLogbook:(CPAfterLoginAction)action
{
    // set the settingsMenuController CPAfterLoginAction so it knows where to go after login
    [CPAppDelegate settingsMenuController].afterLoginAction = action;
    
    // show the login banner
    [CPAppDelegate showLoginBanner];
}

@end
