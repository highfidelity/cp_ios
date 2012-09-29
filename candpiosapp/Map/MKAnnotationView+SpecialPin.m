//
//  MKAnnotationView+SpecialPin.m
//  candpiosapp
//
//  Created by Stephen Birarda on 9/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "MKAnnotationView+SpecialPin.h"

@implementation MKAnnotationView (SpecialPin)

- (void)setPin:(NSInteger)number hasCheckins:(BOOL)checkins hasVirtual:(BOOL)virtual isSolar:(BOOL)solar withLabel:(BOOL)withLabel {
    CGFloat fontSize = 20;
    NSString *imageName;
    CGRect labelFrame = CGRectNull;
    
    if (solar) {
        imageName = @"pin-solar";
    } else {
        // If no one is currently checked in, use the smaller image
        if (checkins) {
            if(virtual)
            {
                imageName = @"pin-virtual-checkedin";
                labelFrame = CGRectMake(0, 23, 93, 20);
            }
            else
            {
                imageName = @"pin-checkedin";
                labelFrame = CGRectMake(0, 15, 93, 20);
            }
        } else {
            labelFrame = CGRectMake(0, 9, 54, 12);
            imageName = @"pin-checkedout";
            fontSize = 12;
        }
    }
    
    
    [self setImage:[UIImage imageNamed:imageName]];
    
    int subViewCount = self.subviews.count;
    if(subViewCount > 0)
    {
        if(subViewCount > 1)
        {
            //Ideally there would be a better way to identify the subviews
            NSLog(@"MultipleSubviews!  The incorrect subview could be getting hidden!");
        }
        [[self.subviews objectAtIndex:0] removeFromSuperview];
        
    }
    
    // Add number label
    if (withLabel && !CGRectIsNull(labelFrame)) {
        UILabel *numberLabel = [[UILabel alloc] initWithFrame:labelFrame];
        numberLabel.backgroundColor = [UIColor clearColor];
        numberLabel.opaque = NO;
        numberLabel.textColor = [UIColor whiteColor];
        numberLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:fontSize];
        numberLabel.textAlignment = UITextAlignmentCenter;
        
        numberLabel.text = [NSString stringWithFormat:@"%d", number];
        [self addSubview:numberLabel];
    }
}

@end
