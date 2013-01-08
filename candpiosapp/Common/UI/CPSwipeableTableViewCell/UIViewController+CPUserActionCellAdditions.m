//
//  UIViewController+CPUserActionCellAdditions.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 8/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UIViewController+CPUserActionCellAdditions.h"
#import "CPUserActionCell.h"

@implementation UIViewController (CPUserActionCellAdditions)

- (void)animateSlideWaveWithCPUserActionCells:(NSArray *)cells {
    NSTimeInterval delay = 0.5;
    for (UITableViewCell *cell in cells) {
        if ([cell isKindOfClass:[CPUserActionCell class]]) {
            CPUserActionCell *userActionCell = (CPUserActionCell *)cell;
            [userActionCell animateSlideButtonsWithNewCenter:userActionCell.originalCenter + 130
                                                       delay:0
                                                    duration:0
                                                    animated:NO];
            
            [userActionCell animateSlideButtonsWithNewCenter:userActionCell.originalCenter
                                                       delay:delay
                                                    duration:0.3
                                                    animated:YES];
        }
        
        delay += 0.1;
    }
}

@end
