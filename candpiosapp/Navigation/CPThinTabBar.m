//
//  CPThinTabBar.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPThinTabBar.h"

@interface CPThinTabBar()

@property (nonatomic, strong) UIView *thinBarBackground;
@property (nonatomic, strong) NSMutableArray *customBarButtons;

@property (nonatomic, strong) UIView *actionMenu;
@property (nonatomic, strong) UIView *greenLine;
@property (nonatomic, strong) NSMutableArray *actionButtonIconImageViews;
@property (nonatomic, strong) NSMutableArray *actionMenuButtons;

@end

@implementation CPThinTabBar

@synthesize tabBarController = _tabBarController;
@synthesize actionButton = _actionButton;
@synthesize actionButtonState = _actionButtonState;
@synthesize thinBarBackground = _thinBarBackground;
@synthesize customBarButtons = _customBarButtons;
@synthesize actionMenu = _actionMenu;
@synthesize greenLine = _greenLine;
@synthesize actionButtonIconImageViews = _actionButtonIconImageViews;
@synthesize actionMenuButtons = _actionMenuButtons;

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
        CPThinTabBarActionButtonState previousState = _actionButtonState;
        _actionButtonState = actionButtonState;
        
        // set the alpha of the UIImageView subviews of the leftButton based on the new state
        [[self.actionButtonIconImageViews objectAtIndex:0] setAlpha:(actionButtonState == CPThinTabBarActionButtonStatePlus)];
        [[self.actionButtonIconImageViews objectAtIndex:1] setAlpha:(actionButtonState == CPThinTabBarActionButtonStateMinus)];
        [[self.actionButtonIconImageViews objectAtIndex:2] setAlpha:(actionButtonState == CPThinTabBarActionButtonStateQuestion)];
        [[self.actionButtonIconImageViews objectAtIndex:3] setAlpha:(actionButtonState == CPThinTabBarActionButtonStateUpdate)];
        
        BOOL plusOrMinusState = (self.actionButtonState == CPThinTabBarActionButtonStatePlus || 
                                 self.actionButtonState == CPThinTabBarActionButtonStateMinus);
        BOOL previousPlusOrMinusState = (previousState == CPThinTabBarActionButtonStatePlus ||
                                         previousState == CPThinTabBarActionButtonStateMinus);
        self.actionButton.userInteractionEnabled = plusOrMinusState;
        if (plusOrMinusState && previousPlusOrMinusState) {
            // switching between open and closed interactive menu states
            [self toggleActionMenu:(self.actionButtonState == CPThinTabBarActionButtonStateMinus)];
        }
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
    [[self.customBarButtons objectAtIndex:3] setImage:newImage forState:UIControlStateNormal];
    
    // make sure the thinBar is in front of the new button
    [self bringSubviewToFront:self.thinBarBackground];
}

- (void)addCustomButtons 
{
    CGFloat xOrigin = LEFT_AREA_WIDTH;
    
    self.customBarButtons = [NSMutableArray array];
    
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
        
        // add the tabBarButton to our array of custom buttons
        [self.customBarButtons addObject:tabBarButton];
        
        // add the right padding for the next button
        xOrigin += BUTTON_WIDTH;
    }
}

- (void)toggleRightSide:(BOOL)shown
{    
    self.greenLine.alpha = shown;
    for (UIButton *customBarButton in self.customBarButtons) {
        customBarButton.alpha = shown;
    }
}

#define ACTION_MENU_HEIGHT 193

#define QUESTION_BUTTON_TOP_MARGIN 9
#define CHECKIN_BUTTON_TOP_MARGIN 60
#define UPDATE_BUTTON_TOP_MARGIN 111

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
    actionMenuBackground.frame = CGRectMake(0, 0, resizableBackground.size.width, ACTION_MENU_HEIGHT);
    [self.actionMenu addSubview:actionMenuBackground];
    
    [self.thinBarBackground insertSubview:self.actionMenu belowSubview:self.actionButton];
    
    // setup the buttons in the action menu
    self.actionButtonIconImageViews = [NSMutableArray array];
    [self.actionButtonIconImageViews addObject:[self iconImageView:@"plus"]];
    [self.actionButtonIconImageViews addObject:[self iconImageView:@"minus"]];
    [self.actionButtonIconImageViews addObject:[self iconImageView:@"question-selected"]];
    [self.actionButtonIconImageViews addObject:[self iconImageView:@"update-selected"]];
    
    // make sure that the plus is shown for the default state of the action menu
    // using the actionButtonState setter won't work here because that's the default state
    [[self.actionButtonIconImageViews objectAtIndex:0] setAlpha:1.0];
    
    // add each of the buttons to the action menu
    self.actionMenuButtons = [NSMutableArray array];
    [self.actionMenuButtons addObject:[self actionMenuButtonWithImageSuffix:@"update" topMargin:UPDATE_BUTTON_TOP_MARGIN tabBarControllerAction:@selector(updateButtonPressed:)]];
    [self.actionMenuButtons addObject:[self actionMenuButtonWithImageSuffix:@"question" topMargin:QUESTION_BUTTON_TOP_MARGIN tabBarControllerAction:@selector(questionButtonPressed:)]];
    [self.actionMenuButtons addObject:[self actionMenuButtonWithImageSuffix:@"checkin" topMargin:CHECKIN_BUTTON_TOP_MARGIN tabBarControllerAction:@selector(checkinButtonPressed:)]];
}

- (UIButton *)actionMenuButtonWithImageSuffix:(NSString *)imageSuffix 
                                    topMargin:(CGFloat)topMargin 
                       tabBarControllerAction:(SEL)tabBarControllerAction
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
    [actionMenuButton addTarget:self.tabBarController action:tabBarControllerAction forControlEvents:UIControlEventTouchUpInside];
    
    // add the the button to the actionMenu
    [self.actionMenu addSubview:actionMenuButton];
    
    // return the created button
    return actionMenuButton;
}

- (void)toggleActionMenu:(BOOL)showMenu
{
    // show or hide the action menu
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
