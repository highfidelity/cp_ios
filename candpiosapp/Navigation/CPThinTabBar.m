//
//  CPThinTabBar.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPThinTabBar.h"
#import "CustomBadge.h"
#import "CPCheckinHandler.h"
#import "VenueInfoViewController.h"

#define kBadgeAnimationDuration 0.5

@interface CPThinTabBar()

@property (strong, nonatomic) UIView *thinBarBackground;
@property (strong, nonatomic) NSMutableArray *customBarButtons;
@property (strong, nonatomic) NSMutableArray *customBarBadges;
@property (strong, nonatomic) UIView *greenLine;
@property (strong, nonatomic) UIButton *actionButton;
@property (strong, nonatomic) UIView *actionMenu;
@property (nonatomic) BOOL isActionMenuShowing;

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
    [self refreshActionButton];
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

#define ACTION_MENU_HEIGHT 140
#define FIRST_IMAGE_VIEW_TAG 1332
#define CHECK_OUT_BUTTON_TOP_MARGIN 9
#define HEADLINE_CHANGE_BUTTON_TOP_MARGIN 57

- (void)refreshActionButton
{
    // if we don't already have the button set it up now
    if (!self.actionButton) {
        
        UIImage *buttonImage = [UIImage imageNamed:@"action-menu-button-base"];
        
        self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        self.actionButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
        
        [self.actionButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        
        // place the center of the button on the top of the CPThinBar at the center of LEFT_AREA_WIDTH
        self.actionButton.center = CGPointMake(LEFT_AREA_WIDTH / 2, 0);
        
        // target for action button is us
        [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshActionButton)
                                                     name:@"userCheckInStateChange"
                                                   object:nil];
        
        // add the button to the tab bar controller
        [self.thinBarBackground addSubview:self.actionButton];
        
        int currentTag = FIRST_IMAGE_VIEW_TAG;
        
        // add image view for each of the icons to the action button
        for (NSString *suffix in @[@"plus", @"minus", @"check-in"]) {
            // alloc-init an imageView and add it to the actionButton
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"action-menu-button-%@", suffix]];
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.alpha = 0.0;
            
            iconImageView.tag = currentTag;
            currentTag++;
            
            [self.actionButton addSubview:iconImageView];
        }
        
        // add the actionMenu
        // create a resizable image with the background
        UIImage *resizableBackground = [[UIImage imageNamed:@"action-menu-bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(34, 0, 0, 0)];
        
        CGRect actionMenuFrame = CGRectMake((LEFT_AREA_WIDTH / 2) - (resizableBackground.size.width / 2),
                                            0,
                                            resizableBackground.size.width,
                                            0);
        self.actionMenu = [[UIView alloc] initWithFrame:actionMenuFrame];
        // clip the subviews of the actionMenu to its bounds
        self.actionMenu.clipsToBounds = YES;
        
        UIImageView *actionMenuBackground = [[UIImageView alloc] initWithImage:resizableBackground];
        actionMenuBackground.frame = CGRectMake(0, 0, resizableBackground.size.width, ACTION_MENU_HEIGHT);
        [self.actionMenu addSubview:actionMenuBackground];
        
        [self.thinBarBackground insertSubview:self.actionMenu belowSubview:self.actionButton];
        
        // add check out and change headline buttons to action menu
        [self addActionMenuButtonWithImageSuffix:@"check-out" topMargin:CHECK_OUT_BUTTON_TOP_MARGIN selectorAction:@selector(checkOutButtonPressed:)];
        [self addActionMenuButtonWithImageSuffix:@"update" topMargin:HEADLINE_CHANGE_BUTTON_TOP_MARGIN selectorAction:@selector(changeHeadlineButtonPressed:)];
    }
    
    [self toggleActionMenu:self.isActionMenuShowing checkedIn:[CPUserDefaultsHandler isUserCurrentlyCheckedIn]];
}

- (void)addActionMenuButtonWithImageSuffix:(NSString *)imageSuffix
                                 topMargin:(CGFloat)topMargin
                            selectorAction:(SEL)selectorAction
{
    // alloc-init an actionMenuButton
    UIButton *actionMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // grab the background image
    UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"action-menu-button-%@", imageSuffix]];
    
    // give the background image to the button
    [actionMenuButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    
    // set the right frame
    actionMenuButton.frame = CGRectMake((self.actionMenu.frame.size.width / 2) - (backgroundImage.size.width / 2),
                                        topMargin,
                                        backgroundImage.size.width,
                                        backgroundImage.size.height);
    
    // give the button the action passed as tabBarControllerAction
    [actionMenuButton addTarget:self action:selectorAction forControlEvents:UIControlEventTouchUpInside];
    
    // add the the button to the actionMenu
    [self.actionMenu addSubview:actionMenuButton];
}

- (IBAction)actionButtonPressed:(UIButton *)sender
{
    if ([CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {
        [self toggleActionMenu:!self.isActionMenuShowing checkedIn:YES];
    } else {
        if ([VenueInfoViewController onScreenVenueVC]) {
            // if we have a VenueInfoVC on screen
            // prompt the user to see if they want to check directly in to that venue
            UIAlertView *checkinAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                       message:@"Would you like to check in to this venue?"
                                                                      delegate:self.tabBarController
                                                             cancelButtonTitle:@"Show me list"
                                                             otherButtonTitles:@"Check in here", nil];
            [checkinAlertView show];
        } else {
            [CPCheckinHandler presentCheckInListModalFromViewController:self.tabBarController];
        }
    }
}

- (IBAction)checkOutButtonPressed:(UIButton *)sender
{
    [CPCheckinHandler promptForCheckout];
}

- (IBAction)changeHeadlineButtonPressed:(id)sender
{
    [CPCheckinHandler presentChangeHeadlineModalFromViewController:self.tabBarController];
    [self toggleActionMenu:NO checkedIn:YES];
}

- (void)toggleActionMenu:(BOOL)showingMenu checkedIn:(BOOL)checkedIn
{
    // if the user is not checkedIn we should be hiding the menu
    if (!checkedIn) {
        showingMenu = NO;
    }
    
    // set the state of isActionMenuShowing
    self.isActionMenuShowing = showingMenu;
    
    // show or hide the action menu
    CGFloat leftButtonTransform = showingMenu ? M_PI : (M_PI*2)-0.0001;
    
    // if we're showing the menu the action menu background needs to grow
    // otherwise drop height to 0
    CGRect newMenuBackgroundFrame = self.actionMenu.frame;
    newMenuBackgroundFrame.size.height = showingMenu ? ACTION_MENU_HEIGHT : 0;
    newMenuBackgroundFrame.origin.y = showingMenu ? self.actionButton.center.y - ACTION_MENU_HEIGHT : self.actionButton.center.y;
    
    // animate the spinning of the plus button and replacement by the minus button
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        self.actionButton.transform = CGAffineTransformMakeRotation(leftButtonTransform);
        
        // hide/show the right buttons
        [self.actionButton viewWithTag:FIRST_IMAGE_VIEW_TAG].alpha = (!self.isActionMenuShowing && checkedIn);
        [self.actionButton viewWithTag:FIRST_IMAGE_VIEW_TAG + 1].alpha = self.isActionMenuShowing;
        [self.actionButton viewWithTag:FIRST_IMAGE_VIEW_TAG + 2].alpha = (!self.isActionMenuShowing &&!checkedIn);
        
    } completion: NULL];
    
    // animation of menu buttons shooting out
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        // give the actionMenu its new frame
        self.actionMenu.frame = newMenuBackgroundFrame;
    } completion:^(BOOL finished){
        
    }];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.actionButton.frame, point)) {
        return self.actionButton;
    } else if (CGRectContainsPoint(self.actionMenu.frame, point)) {
        return [self.actionMenu hitTest:[self.actionMenu convertPoint:point fromView:self] withEvent:event];
    } else {
        return [super hitTest:point withEvent:event];
    }
}


@end
