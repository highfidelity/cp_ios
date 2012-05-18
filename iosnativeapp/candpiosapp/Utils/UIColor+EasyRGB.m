//
//  UIColor+EasyRGB.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UIColor+EasyRGB.h"

@implementation UIColor (EasyRGB)

+ (UIColor *)colorWithR:(CGFloat)red G:(CGFloat)green B:(CGFloat)blue A:(CGFloat)alpha {
    return [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:alpha];
}

@end
