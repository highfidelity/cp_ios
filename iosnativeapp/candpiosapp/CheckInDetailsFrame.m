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

- (void)drawRect:(CGRect)rect
{
    // get the current context and save it so we can restore it after
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 0.2);
    CGContextMoveToPoint(context, self.frame.size.width - 85, 30);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, 1, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, 1, self.frame.size.height - 55);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 55);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 55);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 85, self.frame.size.height - 55);
    CGContextMoveToPoint(context, self.frame.size.width - 85, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 1);
    CGContextAddLineToPoint(context, self.frame.size.width - 1, self.frame.size.height - 55);   
    CGContextStrokePath(context);    
    CGContextRestoreGState(context);    
}

@end
