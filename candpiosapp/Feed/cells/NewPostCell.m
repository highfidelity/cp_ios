//
//  NewPostCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "NewPostCell.h"

@implementation NewPostCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // set the required properties on the HPGrowingTextView
    self.growingTextView.internalTextView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
    self.growingTextView.font = [UIFont systemFontOfSize:14];
    self.growingTextView.textColor = [UIColor colorWithR:100 G:100 B:100 A:1];
    self.growingTextView.backgroundColor = [UIColor clearColor];
    self.growingTextView.minNumberOfLines = 1;
    self.growingTextView.maxNumberOfLines = 20;
    self.growingTextView.returnKeyType = UIReturnKeyDone;
    self.growingTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
}

@end
