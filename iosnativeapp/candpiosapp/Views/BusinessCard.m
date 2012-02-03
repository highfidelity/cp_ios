//
//  BusinessCard.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "BusinessCard.h"
#import "QuartzCore/QuartzCore.h"

@implementation BusinessCard

@synthesize imageView = _imageView;
@synthesize status = _status;
@synthesize nickname = _nickname;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(2,2);
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.38;
}

@end
