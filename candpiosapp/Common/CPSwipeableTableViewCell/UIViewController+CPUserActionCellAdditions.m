//
//  UIViewController+CPUserActionCellAdditions.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 8/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UIViewController+CPUserActionCellAdditions.h"

@implementation UIViewController (CPUserActionCellAdditions)

- (void)animateSlideWaveWithCPUserActionCells:(NSArray *)cells {
    NSTimeInterval delay = 0.5;
    for (UITableViewCell *cell in cells) {
        cell.contentView.transform = CGAffineTransformMakeTranslation(160, 0);
        [UIView animateWithDuration:0.3
                              delay:delay
                            options:kNilOptions
                         animations:^{
                             cell.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
                         }
                         completion:nil];
        delay += 0.1;
    }
}

@end
