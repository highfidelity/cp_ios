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
    
    // render a box with a vertical divider
    CGFloat verticalDividerX = self.frame.size.width - 111;
    CGFloat boxTopY = self.frame.size.height - 57;
    CGFloat boxBottomY = self.frame.size.height - 1;
    CGFloat boxLeftX = 1;
    CGFloat boxRightX = self.frame.size.width - 1;
    CGContextMoveToPoint(context, verticalDividerX, boxTopY);
    CGContextAddLineToPoint(context, verticalDividerX, boxBottomY);
    CGContextAddLineToPoint(context, boxLeftX, boxBottomY);
    CGContextAddLineToPoint(context, boxLeftX, boxTopY);
    CGContextAddLineToPoint(context, verticalDividerX, boxTopY);
    CGContextAddLineToPoint(context, boxRightX, boxTopY);
    CGContextMoveToPoint(context, verticalDividerX, boxBottomY);
    CGContextAddLineToPoint(context, boxRightX, boxBottomY);
    CGContextAddLineToPoint(context, boxRightX, boxTopY);
    CGContextStrokePath(context);    
    CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1.0);
    
    // draw the slider ticks
    for (NSNumber *point in @[@25, @73, @120, @167]) {
        CGContextMoveToPoint(context, [point floatValue], 68);
        CGContextAddLineToPoint(context, [point floatValue], 58);
    }    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);    
}

@end
