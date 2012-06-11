//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"
#import "UIButton+AnimatedClockHand.h"

#define TAB_SIZE self.tabBar.frame.size.width / 5

@interface CPTabBarController ()

@property (nonatomic, strong) UIView *greenLine;

@end

@implementation CPTabBarController

@synthesize centerButton = _centerButton;
@synthesize currentVenueID = _currentVenueID;
@synthesize greenLine = _greenLine;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // change the background image for the tab bar
    [self.tabBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-bg"]];
    
    // create a blank image
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // use that blankImage to have no difference for selectionIndicator
    [self.tabBar setSelectionIndicatorImage:blankImage];
    
    // add the green line to the bottom of the tab bar
    self.greenLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.tabBar.frame.size.height - 2, TAB_SIZE, 2)];
    self.greenLine.backgroundColor = [CPUIHelper CPTealColor];
    [self.tabBar addSubview:self.greenLine];
    
    // move the title up one point
    [[UITabBarItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    
    [self addCenterButtonWithImage:[UIImage imageNamed:@"tab-log"]];
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

// override setter for selectedIndex so we can animate the green line along the bottom
- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    // call super's method so that the tab actually gets switched
    [super setSelectedViewController:selectedViewController];
    
    // call our method that will slide the green line to the right spot
    [self moveGreenLineToSelectedIndex:[self.viewControllers indexOfObject:selectedViewController]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex
{
    CGFloat xPosition = selectedIndex * TAB_SIZE;
    
    // setup a CGRect with the frame of the green line but a new x-origin
    CGRect greenFrame = self.greenLine.frame;
    greenFrame.origin.x = xPosition;
    
    NSLog(@"moving line x origin to %f", xPosition);
    
    // animate the change of self.greenLine.frame to the new frame
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
        self.greenLine.frame = greenFrame;
    } completion:nil];
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
