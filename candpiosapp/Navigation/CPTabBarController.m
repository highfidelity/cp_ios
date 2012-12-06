//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"
#import "CPCheckinHandler.h"
#import "CPUserSessionHandler.h"
#import "VenueInfoViewController.h"
#import "LinkedInLoginController.h"

@interface CPTabBarController()

@end

@implementation CPTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *bgImage = [CPThinTabBar backgroundImage];
    
    CGFloat heightDiff = self.tabBar.frame.size.height - bgImage.size.height;
    
    // change the frame of the tab bar
    self.tabBar.frame = CGRectMake(self.tabBar.frame.origin.x, 
                                   self.tabBar.frame.origin.y + heightDiff, 
                                   self.tabBar.frame.size.width, 
                                   self.tabBar.frame.size.height - heightDiff);
    
    // be the tabBarController of the tab bar
    // so that it can send its buttons actions back to us
    // this is a weak pointer    
    self.thinBar.tabBarController = self;
    
    // make sure the CPTabBarController's views take up the extra space
    CGRect viewFrame = [[self.view.subviews objectAtIndex:0] frame];
    viewFrame.size.height += heightDiff;
    [[self.view.subviews objectAtIndex:0] setFrame:viewFrame];
    
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
    // only try and change things if this isn't already our selected index
    if (selectedIndex != self.selectedIndex) {
        // switch to the designated VC
        [super setSelectedIndex:selectedIndex];
        
        // move the green line to the right spot
        [self.thinBar moveGreenLineToSelectedIndex:selectedIndex];
    }
}

- (CPThinTabBar *)thinBar
{
    return (CPThinTabBar *)self.tabBar;
}

- (IBAction)tabBarButtonPressed:(id)sender
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
        [tabVCArray replaceObjectAtIndex:(kNumberOfTabsRightOfButton - 1) withObject:signupController];
        self.viewControllers = tabVCArray;
        
        // tell the thinBar to update the button
        [self.thinBar refreshLastTab:NO];
    } else {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                                 bundle:nil];
        UINavigationController *contactsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"contactsNavigationController"];

        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        UINavigationController *replacedController = [tabVCArray objectAtIndex:(kNumberOfTabsRightOfButton - 1)];
        
        // replace last tab if the conntroller is LinkedIn login
        if ([[replacedController visibleViewController] class] == [LinkedInLoginController class]) {
            [tabVCArray replaceObjectAtIndex:(kNumberOfTabsRightOfButton - 1) withObject:contactsController];
            self.viewControllers = tabVCArray;
            // tell the thinBar to update the button
            [self.thinBar refreshLastTab:YES];
        }
    }  
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        // just show the regular check in list
        [CPCheckinHandler presentCheckInListModalFromViewController:self];
    } else {
        // show check in details view for the venue on screen
        [CPCheckinHandler presentCheckInDetailsModalForVenue:[VenueInfoViewController onScreenVenueVC].venue
                                                    presentingViewController:self];
        
    }
}

@end
