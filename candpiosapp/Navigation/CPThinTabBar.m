//
//  CPThinTabBar.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPThinTabBar.h"
#import "CustomBadge.h"

#define kBadgeAnimationDuration 0.5

@interface CPThinTabBar()

@property (strong, nonatomic) UIView *thinBarBackground;
@property (strong, nonatomic) NSMutableArray *customBarButtons;
@property (strong, nonatomic) NSMutableArray *customBarBadges;
@property (strong, nonatomic) UIView *greenLine;
@property (strong, nonatomic) UIButton *checkInOutButton;

@end

@implementation CPThinTabBar

static NSArray *_tabBarIcons;

+ (void)initialize
{
    // setup our array of tab bar icons to be called when creating the custom buttons
    if (!_tabBarIcons) {
        _tabBarIcons = [NSArray arrayWithObjects:[UIImage imageNamed:@"tab-venues"],
                                                [UIImage imageNamed:@"tab-people"], 
                                                [UIImage imageNamed:@"tab-contacts"],
                                                [UIImage imageNamed:@"tab-login"], nil];
    }
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (UIImage *)backgroundImage
{
    return [UIImage imageNamed:@"thin-nav-bg"];
}

- (void)awakeFromNib
{    
    UIImage *thinBackgroundImage = [[self class] backgroundImage];
    
    // make the frame of the tabBar thinner
    CGFloat heightDiff = self.frame.size.height - thinBackgroundImage.size.height;
    self.frame = CGRectMake(self.frame.origin.x, 
                            self.frame.origin.y + heightDiff, 
                            self.frame.size.width, 
                            self.frame.size.height - heightDiff);
    
    
    // add an imageView using the thin-nav-bg
    // this can't be the background image because we need to hide the normal tab highlight
    
    self.thinBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 
                                                                      thinBackgroundImage.size.width,
                                                                      thinBackgroundImage.size.width)];
    self.thinBarBackground.backgroundColor = [UIColor colorWithPatternImage:thinBackgroundImage]; 
    [self addSubview:self.thinBarBackground];
    
    // add the other tab bar buttons
    [self addCustomButtons];
    
    // add the little green line on the bottom
    [self addBottomGreenLine];
    
    // setup the check in / check out button
    [self refreshCheckInButton];
}

- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex
{
    CGFloat xPosition = LEFT_AREA_WIDTH + (selectedIndex * BUTTON_WIDTH) + 1;
    
    // setup a CGRect with the frame of the green line but a new x-origin
    CGRect greenFrame = self.greenLine.frame;
    greenFrame.origin.x = xPosition;
    
    // animate the change of self.greenLine.frame to the new frame
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
        self.greenLine.frame = greenFrame;
    } completion:nil];
}

- (void)addBottomGreenLine
{
    // add the green line to the bottom of the tab bar
    // it sits inside of the button's borders
    self.greenLine = [[UIView alloc] initWithFrame:CGRectMake(LEFT_AREA_WIDTH + 1, self.frame.size.height - 2, BUTTON_WIDTH - 1, 2)];
    self.greenLine.backgroundColor = [CPUIHelper CPTealColor];
    [self.thinBarBackground addSubview:self.greenLine];
}

- (void)refreshLastTab:(BOOL)loggedIn
{
    // grab the new image from our array of tabBarIcons
    UIImage *newImage = [_tabBarIcons objectAtIndex:(loggedIn ? (kNumberOfTabsRightOfButton - 1) : kNumberOfTabsRightOfButton)];
    // give the new image to the button
    [[self.customBarButtons objectAtIndex:(kNumberOfTabsRightOfButton - 1)] setImage:newImage forState:UIControlStateNormal];
    
    // make sure the thinBar is in front of the new button
    [self bringSubviewToFront:self.thinBarBackground];
}

- (void)setBadgeNumber:(NSNumber *)number atTabIndex:(NSUInteger)index
{
    CustomBadge *badge = [self.customBarBadges objectAtIndex:index];
    [UIView animateWithDuration:kBadgeAnimationDuration animations:^{
        if ([number intValue]) {
            badge.badgeText = [number stringValue];
            badge.alpha = 1;
        } else {
            badge.alpha = 0;
        }
        [badge setNeedsDisplay];
    }];
}

- (void)addCustomButtons 
{
    CGFloat xOrigin = LEFT_AREA_WIDTH;
    
    self.customBarButtons = [NSMutableArray array];
    self.customBarBadges = [NSMutableArray array];
    
    // create the four buttons that will be added
    for (int i = 0; i < kNumberOfTabsRightOfButton; i++) {
        // alloc-init the button
        UIButton *tabBarButton = [[UIButton alloc] initWithFrame:CGRectMake(xOrigin, 0, BUTTON_WIDTH, self.frame.size.height)];
        tabBarButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        // make the the tag of this button the index of the VC it corresponds to
        tabBarButton.tag = i;
        
        // give this button the right icon image
        [tabBarButton setImage:[_tabBarIcons objectAtIndex:i] forState:UIControlStateNormal];
        
        // add a a seperator line on the left of the button
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, tabBarButton.frame.size.height)];
        sepLine.backgroundColor = [UIColor colorWithR:152 G:152 B:152 A:0.3];
        
        // add the seperator line to the button
        [tabBarButton addSubview:sepLine];
        
        // add the button to the thinBackground imageView
        [self.thinBarBackground addSubview:tabBarButton];
        
        // the target for this button is the CPTabBarController
        [tabBarButton addTarget:self.tabBarController action:@selector(tabBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        // add the tabBarButton to our array of custom buttons
        [self.customBarButtons addObject:tabBarButton];

        // add badges
        CustomBadge *badge = [CustomBadge customBadgeWithString:@"?"
                                                withStringColor:[UIColor whiteColor]
                                                 withInsetColor:[UIColor redColor]
                                                 withBadgeFrame:YES
                                            withBadgeFrameColor:[UIColor whiteColor]
                                                      withScale:0.8
                                                    withShining:YES];
        CGFloat badgeInset = 4.0;
        badge.frame = CGRectMake(tabBarButton.frame.size.width - badge.frame.size.width - badgeInset,
                                 badge.frame.origin.y + badgeInset,
                                 badge.frame.size.width,
                                 badge.frame.size.height);
        badge.alpha = 0;
        CATransition *animation = [CATransition animation];
        animation.duration = kBadgeAnimationDuration;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [badge.layer addAnimation:animation forKey:@"badgeTextTransition"];
        badge.userInteractionEnabled = NO;
        [tabBarButton addSubview:badge];
        [self.customBarBadges addObject:badge];
        
        // add the right padding for the next button
        xOrigin += BUTTON_WIDTH;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.checkInOutButton.frame, point)) {
        return self.checkInOutButton;
    } else {
        return [super hitTest:point withEvent:event];
    } 
}

- (void)refreshCheckInButton
{
    // if we don't already have the button set it up now
    if (!self.checkInOutButton) {
        
        UIImage *buttonImage = [UIImage imageNamed:@"action-menu-button-base"];
        
        self.checkInOutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.checkInOutButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        self.checkInOutButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        
        [self.checkInOutButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        
        // place the center of the button on the top of the CPThinBar at the center of LEFT_AREA_WIDTH
        self.checkInOutButton.center = CGPointMake(LEFT_AREA_WIDTH / 2, 0);
        
        // add the button to the tab bar controller
        [self.thinBarBackground addSubview:self.checkInOutButton];
        
        // target for check in button is tabBarController
        [self.checkInOutButton addTarget:self.tabBarController action:@selector(checkinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshCheckInButton)
                                                     name:@"userCheckInStateChange"
                                                   object:nil];
    }
    
    [self.checkInOutButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"action-menu-button-%@", [self checkInOutSuffix]]] forState:UIControlStateNormal];
}

-(NSString *)checkInOutSuffix
{
    return ![CPUserDefaultsHandler isUserCurrentlyCheckedIn] ? @"plus" : @"minus";
}

@end
