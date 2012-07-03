//
//  LogLoveCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogLoveCell.h"

@implementation LogLoveCell

@synthesize receiverProfileButton = _receiverProfileButton;

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.receiverProfileButton setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
}

@end
