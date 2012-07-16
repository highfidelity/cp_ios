//
//  CPThinTabBar.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPThinTabBar.h"

@interface CPThinTabBar()


@property (nonatomic, strong) UIView *actionMenu;
@property (nonatomic, strong) UIView *greenLine;
@property (nonatomic, strong) UIImageView *actionMenuBackground;

@property (nonatomic, strong) UIImageView *plusIconImageView;
@property (nonatomic, strong) UIImageView *minusIconImageView;
@property (nonatomic, strong) UIImageView *updateIconImageView;
@property (nonatomic, strong) UIButton *updateButton;

@end

@implementation CPThinTabBar

@synthesize thinBarBackground = _thinBarBackground;
@synthesize tabBarController = _tabBarController;
@synthesize actionButtonState = _actionButtonState;
@synthesize actionButton = _actionButton;
@synthesize actionMenu = _actionMenu;
@synthesize greenLine = _greenLine;
@synthesize actionMenuBackground = _actionMenuBackground;
@synthesize plusIconImageView = _plusImageView;
@synthesize minusIconImageView = _minusImageView;
@synthesize updateIconImageView = _updateIconImageView;
@synthesize updateButton = _updateButton;
@synthesize barButton1 = _barButton1;
@synthesize barButton2 = _barButton2;
@synthesize barButton3 = _barButton3;
@synthesize barButton4 = _barButton4;

static NSArray *tabBarIcons;

+ (void)initialize
{
    // setup our array of tab bar icons to be called when creating the custom buttons
    if (!tabBarIcons) {
        tabBarIcons = [NSArray arrayWithObjects:[UIImage imageNamed:@"tab-logbook"], 
                       [UIImage imageNamed:@"tab-venues"], 
                       [UIImage imageNamed:@"tab-people"], 
                       [UIImage imageNamed:@"tab-contacts"],
                       [UIImage imageNamed:@"tab-login"], nil];
    }
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
    
    // setup the action menu
    [self actionMenuSetup];
}

- (void)setActionButtonState:(CPThinTabBarActionButtonState)actionButtonState
{
    if (_actionButtonState != actionButtonState) {
        _actionButtonState = actionButtonState;
        
        // set the alpha of the UIImageView subviews of the leftButton based on the new state
        self.plusIconImageView.alpha = (actionButtonState == CPThinTabBarActionButtonStatePlus);
        self.minusIconImageView.alpha = (actionButtonState == CPThinTabBarActionButtonStateMinus);
        self.updateIconImageView.alpha = (actionButtonState == CPThinTabBarActionButtonStateUpdate);
        
        self.actionButton.userInteractionEnabled = (self.actionButtonState == CPThinTabBarActionButtonStatePlus || 
                                                    self.actionButtonState == CPThinTabBarActionButtonStateMinus);
    }
}

- (UIImageView *)iconImageView:(NSString *)imageSuffix
{
    // alloc-init an imageView and add it to the actionButton
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"action-menu-button-%@", imageSuffix]]];
    iconImageView.alpha = 0.0;
    [self.actionButton addSubview:iconImageView];
    
    // return the iconImageView
    return iconImageView;
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
    UIImage *newImage = [tabBarIcons objectAtIndex:(loggedIn ? 3 : 4)];
    // give the new image to the button
    [self.barButton4 setImage:newImage forState:UIControlStateNormal];
}

- (void)addCustomButtons 
{
    CGFloat xOrigin = LEFT_AREA_WIDTH;
    
    // create the four buttons that will be added
    for (int i = 0; i < 4; i++) {
        // alloc-init the button
        UIButton *tabBarButton = [[UIButton alloc] initWithFrame:CGRectMake(xOrigin, 0, BUTTON_WIDTH, self.frame.size.height)];
        tabBarButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        // make the the tag of this button the index of the VC it corresponds to
        tabBarButton.tag = i;
        
        // give this button the right icon image
        [tabBarButton setImage:[tabBarIcons objectAtIndex:i] forState:UIControlStateNormal];
        
        // add a a seperator line on the left of the button
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, tabBarButton.frame.size.height)];
        sepLine.backgroundColor = [UIColor colorWithR:152 G:152 B:152 A:0.3];
        
        // add the seperator line to the button
        [tabBarButton addSubview:sepLine];
        
        // add the button to the thinBackground imageView
        [self.thinBarBackground addSubview:tabBarButton];
        
        // the target for this button is the CPTabBarController
        [tabBarButton addTarget:self.tabBarController action:@selector(tabBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                
        // this is our ith button so set that property
        // we need this to hide the buttons later
        NSString *setter = [NSString stringWithFormat:@"setBarButton%d:", i+1];
        
        // ignoring a warning here about performingSelector without a compile-time set selector, it's dynamic because of the for loop
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(setter) withObject:tabBarButton];
#pragma clang diagnostic pop
        
        
        // add the right padding for the next button
        xOrigin += BUTTON_WIDTH;
    }
}

- (void)toggleRightSide:(BOOL)shown
{    
    self.greenLine.alpha = shown;
    self.barButton1.alpha = shown;
    self.barButton2.alpha = shown;
    self.barButton3.alpha = shown;
    self.barButton4.alpha = shown;
}

#define ACTION_MENU_HEIGHT 238
#define UPDATE_BUTTON_TOP_MARGIN 158

- (void)actionMenuSetup
{
    // setup a UIButton with the image
    UIImage *buttonImage = [UIImage imageNamed:@"action-menu-button-base"];
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.actionButton.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
    [self.actionButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    // place the center of the button on the top of the CPThinBar at the center of LEFT_AREA_WIDTH
    self.actionButton.center = CGPointMake(LEFT_AREA_WIDTH / 2, 0);
    
    // add the button to the tab bar controller
    [self.thinBarBackground addSubview:self.actionButton];    
    
    // we are the target for the leftButton
    [self.actionButton addTarget:self action:@selector(actionMenuButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
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
    actionMenuBackground.frame = CGRectMake(0, 0, resizableBackground.size.width, 238);
    [self.actionMenu addSubview:actionMenuBackground];
    
    [self.thinBarBackground insertSubview:self.actionMenu belowSubview:self.actionButton];
    
    // setup the buttons in the action menu
    // and make sure that the plus is shown for the default state of the action menu
    self.plusIconImageView = [self iconImageView:@"plus"];
    self.minusIconImageView = [self iconImageView:@"minus"];
    self.updateIconImageView = [self iconImageView:@"update-selected"];
    self.plusIconImageView.alpha = 1.0;
    
    // add each of the buttons to the action menu
    self.updateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backgroundImage = [UIImage imageNamed:@"action-menu-button-update"];
    [self.updateButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    self.updateButton.frame = CGRectMake((self.actionMenu.frame.size.width / 2) - (backgroundImage.size.width / 2),
                                         UPDATE_BUTTON_TOP_MARGIN,
                                         backgroundImage.size.width, 
                                         backgroundImage.size.height);
    [self.updateButton addTarget:self.tabBarController action:@selector(updateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionMenu addSubview:self.updateButton];
}

- (void)toggleActionMenu:(BOOL)showMenu
{    
    CGFloat leftButtonTransform = showMenu ? M_PI : (M_PI*2)-0.0001;
    
    // if we're showing the menu the action menu background needs to grow
    // otherwise drop height to 0
    CGRect newMenuBackgroundFrame = self.actionMenu.frame;
    newMenuBackgroundFrame.size.height = showMenu ? ACTION_MENU_HEIGHT : 0;
    newMenuBackgroundFrame.origin.y -= showMenu ? ACTION_MENU_HEIGHT : -ACTION_MENU_HEIGHT;
    
    // animate the spinning of the plus button and replacement by the minus button
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{ 
        self.actionButton.transform = CGAffineTransformMakeRotation(leftButtonTransform); 
        self.actionButtonState = (showMenu ? CPThinTabBarActionButtonStateMinus : CPThinTabBarActionButtonStatePlus);
    } completion: NULL];
    
    // animation of menu buttons shooting out
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        // give the actionMenu its new frame
        self.actionMenu.frame = newMenuBackgroundFrame;
    } completion:^(BOOL finished){
        
    }];
}

- (IBAction)actionMenuButtonPressed:(id)sender
{    
    // only toggle the menu if the actionButton is displaying the plus or minus icon
    if (self.actionButtonState == CPThinTabBarActionButtonStatePlus) {
        [self toggleActionMenu:YES];
    } else if (self.actionButtonState == CPThinTabBarActionButtonStateMinus) {
        [self toggleActionMenu:NO];
    }
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
