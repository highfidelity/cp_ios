//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"

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
    
//    [self refreshTabBar];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(refreshTabBar)
//                                                 name:@"LoginStateChanged"
//                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    // we have no VC at index 0 so make it go to the logbook
    
    [super setSelectedIndex:selectedIndex];
    
    // move the green line to the right spot
    [self.thinBar moveGreenLineToSelectedIndex:selectedIndex];
}

- (void)tabBarButtonPressed:(id)sender
{
    // switch to the tab the user just tapped
    int tabIndex = ((UIButton *)sender).tag;
    self.selectedIndex = tabIndex;
}

- (void)refreshTabBar
{
    if (![CPAppDelegate currentUser]) {
        UIStoryboard *signUpStoryboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
        UINavigationController *signupController = [signUpStoryboard instantiateInitialViewController];

        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:4 withObject:signupController];
        self.viewControllers = tabVCArray;
    } else {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                                 bundle:nil];
        UINavigationController *contactsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"contactsNavigationController"];

        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:4 withObject:contactsController];
        self.viewControllers = tabVCArray;
    }
}


@end
