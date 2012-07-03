//
//  LogEntryCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogBaseEntryCell.h"

@implementation LogBaseEntryCell

@synthesize senderProfileButton = _senderProfileButton;
@synthesize entryLabel = _entryLabel;

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.senderProfileButton setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
}


@end
