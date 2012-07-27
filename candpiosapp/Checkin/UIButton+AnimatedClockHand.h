//
//  UIButton+AnimatedClockHand.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/4/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (AnimatedClockHand)

-(void)addClockHand;
-(void)toggleAnimationOfClockHand:(BOOL)animating;
-(void)refreshButtonStateFromCheckinStatus;
-(void)refreshButtonStateWithBoolean:(BOOL)checkedIn;

@end
