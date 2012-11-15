//
//  CPTouchableView.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 29.6.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTouchableView.h"

@interface CPTouchableView()

@property (strong, nonatomic) UIColor *oldBackgroundColor;

@end

@implementation CPTouchableView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate touchUp:self];
    [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.backgroundColor = self.oldBackgroundColor;
    } completion:nil];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.oldBackgroundColor = self.backgroundColor;
    const CGFloat *rgb = CGColorGetComponents(self.oldBackgroundColor.CGColor);
    
    float red = rgb[0];
    float green = rgb[1];
    float blue = rgb[2];
    float alpha = rgb[3];
    
    int colorChange = 30;

    CGFloat colorBrightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000;
    if (colorBrightness > 0.5)
    {
        colorChange = -30;
    }

    self.backgroundColor = [UIColor colorWithR:red + colorChange
                                             G:green + colorChange
                                             B:blue + colorChange
                                             A:alpha];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundColor = self.oldBackgroundColor;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundColor = self.oldBackgroundColor;
}

@end
