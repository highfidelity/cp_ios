//
//  CPLogEntry.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPLogEntry.h"
#import "GTMNSString+HTML.h"

@implementation CPLogEntry

@synthesize logID = _logID;
@synthesize entry = _entry;
@synthesize author = _author;
@synthesize date = _date;
@synthesize venue = _venue;
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize receiver = _receiver;
@synthesize skill = _skill;

static NSDateFormatter *logDateFormatter;

+ (void)initialize
{
    if (!logDateFormatter) {
        logDateFormatter = [[NSDateFormatter alloc] init];
        logDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        logDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
}

- (id)initFromDictionary:(NSDictionary *)logDict
{
    if (self = [self init]) {
        self.logID = [[logDict objectForKey:@"id"] integerValue];
        self.entry = [logDict objectForKey:@"entry"];
        self.date = [logDateFormatter dateFromString:[logDict objectForKey:@"date"]];
        
        if ([logDict objectForKey:@"author"]) {
            self.author = [[User alloc] initFromDictionary:[logDict objectForKey:@"author"]];
        } else if ([logDict objectForKey:@"receiver"]) {
            self.receiver = [[User alloc] initFromDictionary:[logDict objectForKey:@"receiver"]];
        }
    }
    return self;
}

- (void)setEntry:(NSString *)entry
{
    _entry = [entry gtm_stringByUnescapingFromHTML];
}

@end
