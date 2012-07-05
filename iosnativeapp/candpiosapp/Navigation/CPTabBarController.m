//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"
#import "FeedVenuesTableViewController.h"
#import "FeedViewController.h"
 
@implementation CPTabBarController

// TODO: get rid of the currentVenueID here, let's keep that in NSUserDefaults (my bad)

@synthesize thinBar = _thinBar;
@synthesize forcedCheckin = _forcedCheckin;
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
    
    // we are the target for the leftButton
    [self.thinBar.leftButton addTarget:self action:@selector(postUpdateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
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

- (IBAction)postUpdateButtonPressed:(id)sender
{   
    if (![CPUserDefaultsHandler currentUser]) {
        // if we don't have a current user then we need to just show the login banner
        [self promptForLoginToSeeLogbook:CPAfterLoginActionAddNewLog];
    } else if (![CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {
        // if we have a user but they aren't checked in
        // they need to be checked in before they can log
        
        NSString *alertMessage = @"You must be checked in to post an update. Want to checkin now?";
        
        UIAlertView *checkinAlert =  [[UIAlertView alloc] initWithTitle:@"Wait!"
                                                                message:alertMessage 
                                                               delegate:self 
                                                      cancelButtonTitle:@"Cancel" 
                                                      otherButtonTitles:@"Checkin", nil];
        [checkinAlert show];
        
    } else {
        // the user is logged in and checked in
        
        // we need to bring them to the feed VC for the venue they are checked into
        // and then tell that VC that the user wants to add a new log
        
        // assume that the venue the user is currently checked into is the first
        // in the UITableView of the FeedVenuesTableViewController
        
        // grab the logbook navigation controller and logbook view controller
        UINavigationController *feedNC = [self.viewControllers objectAtIndex:0];
            
        if (feedNC.viewControllers.count > 1) {
            FeedViewController *feedVC = [feedNC.viewControllers objectAtIndex:1];
            
            if ([CPUserDefaultsHandler currentVenue].venueID == feedVC.venue.venueID) {
                // the user is already on the feed for the right venue
                // so tell the feedVC that we want to add a new post
                
                if (self.selectedIndex == 0) {
                    // the feedVC is on screen so we want a new post right now
                    [feedVC newPost];
                } else {
                    // the feedVC isn't on screen yet so tell we want a new post after it loads
                    feedVC.newPostAfterLoad = YES;
                    self.selectedIndex = 0;
                }
                
                // we're done with the execution of this method, get out of here
                return;
            } else {
                // we need to pop the wrong feed off the navigation controller
                // so it can segue to the right one below
                [feedNC popViewControllerAnimated:NO];
            }
        }
        
        // grab the FeedVenuesTableViewController
        FeedVenuesTableViewController *feedTVC = [feedNC.viewControllers objectAtIndex:0];
        
        // now that we're on the feeds TVC tell it to perform ShowVenueFeedForNewPost segue
        [feedTVC performSegueWithIdentifier:@"ShowVenueFeedForNewPost" sender:self]; 
        
        // switch to the feeds TVC if we weren't on it
        if (self.selectedIndex != 0) {
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        // the user wants to checkin
        // this is a forced checkin
        self.forcedCheckin = YES;
        
        // grab the inital view controller of the checkin storyboard
        UINavigationController *checkinNVC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        
        // present that VC modally
        [self presentModalViewController:checkinNVC animated:YES];
    }
}

@end
