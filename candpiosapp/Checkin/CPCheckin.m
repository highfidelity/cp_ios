//
//  CPCheckIn.m
//  candpiosapp
//
//  Created by Stephen Birarda on 11/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPCheckIn.h"
#import "GTMNSString+HTML.h"

@implementation CPCheckIn

- (void)setStatusText:(NSString *)statusText
{
    if (statusText.length > 0) {
        statusText = [statusText gtm_stringByUnescapingFromHTML];
        statusText = [statusText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    _statusText = statusText;
}

- (NSDate *)checkoutDate
{
    return [NSDate dateWithTimeIntervalSince1970:[self.checkoutSinceEpoch intValue]];
}

- (BOOL)isCurrentlyCheckedIn
{
    return [self.checkoutDate compare:[NSDate date]] != NSOrderedAscending;
}

@end
