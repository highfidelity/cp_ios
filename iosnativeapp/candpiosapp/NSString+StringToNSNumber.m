//
//  NSString+StringToNSNumber.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "NSString+StringToNSNumber.h"

@implementation NSString (StringToNSNumber)

- (NSNumber *)numberFromIntString
{
    return [NSNumber numberWithInt:[self intValue]];
}

@end
