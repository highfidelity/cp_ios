//
//  CPUIHelper.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
    CPButtonTurquoise = 0,
    CPButtonGrey = 1,
} CPButtonColor;

typedef enum {
    CPColorGreen = 0,
    CPColorGrey = 1,
} CPColor;

// TODO: import this and other files we are always using in the prefix.pch file
// Ex: CPUtils.h, SVProgressHUD.h, maybe AppDelegate too

@interface CPUIHelper : NSObject

// UI elements
+ (void)addShadowToView:(UIView *)view
                  color:(UIColor *)color
                 offset:(CGSize)offset
                 radius:(double)radius
                opacity:(double)opacity;

+ (UIButton *)CPButtonWithText:(NSString *)buttonText 
             color:(CPButtonColor)buttonColor
             frame:(CGRect)buttonFrame;

+ (UIButton *)makeButtonCPButton:(UIButton *)button withCPButtonColor:(CPButtonColor)buttonColor;

// C&P Color scheme
+ (UIColor *)colorForCPColor:(CPColor)cpColor;
+ (UIImage *)imageForCPColor:(CPButtonColor)buttonColor;

// Font changes (League Gothic)
+ (void)changeFontForLabel:(UILabel *)label toLeagueGothicOfSize:(CGFloat)size;

// Animations
+ (void)rotateImage:(UIImageView *)image
           duration:(NSTimeInterval)duration
              curve:(int)curve 
            degrees:(CGFloat)degrees;

+(void)spinView:(UIView *)view 
    duration:(NSTimeInterval)duration 
    repeatCount:(float)repeatCount 
    clockwise:(BOOL)clockwise
 timingFunction:(CAMediaTimingFunction *)timingFunction;

@end