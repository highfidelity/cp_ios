//
//  SettingsMenuView.m
//  candpiosapp
//
//  Created by Stephen Birarda on 12/19/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SettingsMenuView.h"

@implementation SettingsMenuView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return CGRectContainsPoint(self.frame, point) ||
           CGRectContainsPoint(self.menuChildViewControllerView.frame, point);
}

@end
