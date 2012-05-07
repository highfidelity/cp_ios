//
//  UIButton+AnimatedClockHand.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/4/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UIButton+AnimatedClockHand.h"

#define CLOCK_HAND_TAG 903

@implementation UIButton (AnimatedClockHand)

-(void)addClockHand
{
    if (![self viewWithTag:CLOCK_HAND_TAG]) {
        // add the clock hand to the button
        // this is seperate so we can spin it when the person is checked out
        
        UIImageView *clockHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab-check-in-clock-hand.png"]];
        CGRect handFrame = clockHand.frame;
        handFrame.origin.x = 30;
        handFrame.origin.y = 23;
        clockHand.frame = handFrame;
        clockHand.tag = CLOCK_HAND_TAG;
        [self addSubview:clockHand];
    }
}

-(void)toggleAnimationOfClockHand:(BOOL)animating
{
    if (animating) {
        // spin the clock hand
        [CPUIHelper spinView:[self viewWithTag:CLOCK_HAND_TAG] duration:15 repeatCount:MAXFLOAT clockwise:YES timingFunction:nil];
    } else {
        [[self viewWithTag:CLOCK_HAND_TAG].layer removeAllAnimations];
    }
}

-(void)refreshButtonStateFromCheckinStatus
{
    // change the image and the text on the button
    if ([CPAppDelegate userCheckedIn]) {
        [self refreshButtonStateWithBoolean:YES];
    } else {
        [self refreshButtonStateWithBoolean:NO];
    }
}

-(void)refreshButtonStateWithBoolean:(BOOL)checkedIn
{
    // make sure we have a clock hand
    [self addClockHand];
    if (checkedIn) {
        // start animating the clock hand
        [self toggleAnimationOfClockHand:YES];
        [self setBackgroundImage:[UIImage imageNamed:@"tab-check-out.png"] forState:UIControlStateNormal];
    } else {
        // stop animating the clock hand
        [self toggleAnimationOfClockHand:NO];
        [self setBackgroundImage:[UIImage imageNamed:@"tab-check-in.png"] forState:UIControlStateNormal];
    }
}

-(UIImage *)checkinImage
{
    return [UIImage imageNamed:@"tab-check-in.png"];
}

-(UIImage *)checkoutImage
{
    return [UIImage imageNamed:@"tab-check-out.png"];
}

@end
