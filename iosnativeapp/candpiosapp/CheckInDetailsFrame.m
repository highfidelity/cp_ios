//
//  CheckInDetailsFrame.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckInDetailsFrame.h"

@implementation CheckInDetailsFrame

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// drawRect that will draw the frame and the ticks in the check in details box
- (void)drawRect:(CGRect)rect
{
    // get the current context and save it so we can restore it after
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    CGContextSaveGState(context);
    
    // set our line width and color
    CGContextSetLineWidth(context, 0.5);
    CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 0.2);
    
    // draw the frame
    CGContextMoveToPoint(context, self.frame.size.width - 85, 30);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, 1, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, 1, self.frame.size.height - 65);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 65);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 65);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 65);
    CGContextMoveToPoint(context, self.frame.size.width - 85, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 65);   
    CGContextStrokePath(context);    
    CGContextClosePath(context);
    
    // draw the tick marks for the slider
    CGContextBeginPath(context);
    CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1.0);
    for (NSNumber *point in [NSArray arrayWithObjects:[NSNumber numberWithInt:30], [NSNumber numberWithInt:78], [NSNumber numberWithInt:125], [NSNumber numberWithInt:172], nil]) {
        CGContextMoveToPoint(context, [point floatValue], 68);
        CGContextAddLineToPoint(context, [point floatValue], 58);
    }    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);    
}

@end
