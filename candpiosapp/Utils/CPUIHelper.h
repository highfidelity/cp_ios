//
//  CPUIHelper.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "UIColor+EasyRGB.h"

typedef enum {
    CPButtonTurquoise = 0,
    CPButtonGrey = 1,
} CPButtonColor;

typedef enum {
    CPColorGreen = 0,
    CPColorGrey = 1,
} CPColor;

@interface CPUIHelper : NSObject

# pragma mark - UI Elements
+ (void)addShadowToView:(UIView *)view
                  color:(UIColor *)color
                 offset:(CGSize)offset
                 radius:(double)radius
                opacity:(double)opacity;

+ (void)setDefaultCorners:(UIView *)view andAlpha:(CGFloat)alpha;
+ (void)setCorners:(UIView *)view withBorder:(UIColor *)borderColor Radius: (CGFloat)radius andBackgroundColor:(UIColor *)color;

+ (CGFloat)expectedHeightForLabel:(UILabel *)label;

+ (UIButton *)CPButtonWithText:(NSString *)buttonText 
             color:(CPButtonColor)buttonColor
             frame:(CGRect)buttonFrame;

+ (UIButton *)makeButtonCPButton:(UIButton *)button withCPButtonColor:(CPButtonColor)buttonColor;

# pragma mark - Color schemes
+ (UIColor *)CPTealColor;
+ (UIColor *)colorForCPColor:(CPColor)cpColor;
+ (UIImage *)imageForCPColor:(CPButtonColor)buttonColor;

# pragma mark - League Gothic Helper
+ (void)changeFontForLabel:(UILabel *)label toLeagueGothicOfSize:(CGFloat)size;
+ (void)changeFontForTextField:(UITextField *)textField toLeagueGothicOfSize:(CGFloat)size;

#pragma mark - Animations
+ (void)rotateImage:(UIImageView *)image
           duration:(NSTimeInterval)duration
              curve:(int)curve 
            degrees:(CGFloat)degrees;

+(void)spinView:(UIView *)view 
    duration:(NSTimeInterval)duration 
    repeatCount:(float)repeatCount 
    clockwise:(BOOL)clockwise
 timingFunction:(CAMediaTimingFunction *)timingFunction;

+ (void)animatedEllipsisAfterLabel:(UILabel *)label
                              start:(BOOL)startAnimation;

#pragma mark - App-wide images
+ (UIImage *)defaultProfileImage;

+ (void)profileImageView:(UIImageView *)imageView
     withProfileImageUrl:(NSURL *)photoUrl;

+ (NSString *)profileNickname:(NSString *)nickname;

# pragma mark - Settings Button
+ (void)settingsButtonForNavigationItem:(UINavigationItem *)navigationItem;

@end
