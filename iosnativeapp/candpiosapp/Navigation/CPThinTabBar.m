//
//  CPThinTabBar.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPThinTabBar.h"

@implementation CPThinTabBar

@synthesize leftButton = _leftButton;
@synthesize greenLine = _greenLine;
@synthesize tabBarController = _tabBarController;
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
                       [UIImage imageNamed:@"tab-contacts"], nil];
    }
}

- (id)initWithFrame:(CGRect)frame backgroundImage:(UIImage *)backgroundImage
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *thinImage = [UIImage imageNamed:@"thin-nav-bg.png"];
        
        self.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin);
        
        // use the image as the background color
        self.backgroundColor = [UIColor colorWithPatternImage:thinImage];
        
        // set user interaction enabled to yes so the buttons actually work
        self.userInteractionEnabled = YES;
        
        // add the other tab bar buttons
        [self addCustomButtons];
        // add the left button
        [self addLeftButtonWithImage:[UIImage imageNamed:@"add-log-button"]];
        // add the little green line on the bottom
        [self addBottomGreenLine];
    }
    return self;
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
    [self addSubview:self.greenLine];
}

- (void)addLeftButtonWithImage:(UIImage *)buttonImage
{
    // setup a UIButton with the image
    self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.leftButton.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
    [self.leftButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    // place the center of the button on the top of the CPThinBar at the center of LEFT_AREA_WIDTH
    self.leftButton.center = CGPointMake(LEFT_AREA_WIDTH / 2, 0);
    
    // add the button to the tab bar controller
    [self addSubview:self.leftButton];    
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
        
        [tabBarButton addTarget:self.tabBarController action:@selector(tabBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        // add the button to the thinBackground imageView
        [self addSubview:tabBarButton];
                
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

@end
