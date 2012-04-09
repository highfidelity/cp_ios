//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"

@interface CPTabBarController ()

@end

@implementation CPTabBarController

@synthesize centerButton = _centerButton;
@synthesize currentVenueID = _currentVenueID;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self addCenterButtonWithImage:[UIImage imageNamed:@"tab-check-in.png"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)addCenterButtonWithImage:(UIImage *)buttonImage
{
    // setup a UIButton with the image
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    // figure out where to position the button
    CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
    if (heightDifference < 0)
        button.center = self.tabBar.center;
    else
    {
        CGPoint center = self.tabBar.center;
        center.y = center.y - self.tabBar.frame.origin.y - heightDifference/2.0;
        button.center = center;
    }
    
    // add a tag to the button so we can grab it and hide it later
    button.tag = 901;
    
    // add the clock hand to the button
    // this is seperate so we can spin it when the person is checked out
    
    UIImageView *clockHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab-check-in-clock-hand.png"]];
    CGRect handFrame = clockHand.frame;
    handFrame.origin.x = 30;
    handFrame.origin.y = 23;
    clockHand.frame = handFrame;
    clockHand.tag = 903;
    [button addSubview:clockHand];
    
    // add the target for the button
    [button addTarget:CPAppDelegate action:@selector(checkInButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // we need a useless view controller at index 2 in the tab bar controller
    UIViewController *placeHolder = [[UIViewController alloc] init];
    placeHolder.tabBarItem = [[UITabBarItem alloc] init];
    
    NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
    [tabVCArray insertObject:placeHolder atIndex:2];
    self.viewControllers = tabVCArray;
    
    placeHolder.tabBarItem.enabled = NO;
    
    // add the button to the tab bar controller
    [self.tabBar addSubview:button];
    
    self.centerButton = button;
    
    // change the button to the check out button if required
    [CPAppDelegate refreshCheckInButton];
    

}

@end
