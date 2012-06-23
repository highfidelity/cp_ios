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
@synthesize type = _type;
@synthesize originalLogID = _originalLogID;

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
        
        // alloc-init user objects for author and receiver if we have them
        // we should always have an author
        if ([logDict objectForKey:@"author"]) {
            self.author = [[User alloc] initFromDictionary:[logDict objectForKey:@"author"]];
        } 
        
        // only attempt to pull the receiver if the key exists and the object for that key isn't null
        // if it's null we don't have that user in the database anymore
        if ([logDict objectForKey:@"receiver"] && ![[logDict objectForKey:@"receiver"] isKindOfClass:[NSNull class]]) {
            self.receiver = [[User alloc] initFromDictionary:[logDict objectForKey:@"receiver"]];
        }
        
        // if we have a skill
        // then alloc-init one using the dictionary
        if ([logDict objectForKey:@"skill"]) {
            self.skill = [[CPSkill alloc] initFromDictionary:[logDict objectForKey:@"skill"]];
        }
        
        self.type = [self enumLogEntryTypeForString:[logDict objectForKey:@"type"]];
        self.originalLogID = [[logDict objectForKey:@"original_log_id"] integerValue];
    }
    return self;
}

- (void)setEntry:(NSString *)entry
{
    _entry = [entry gtm_stringByUnescapingFromHTML];
}

- (CPLogEntryType)enumLogEntryTypeForString:(NSString *)typeString
{
    if ([typeString isEqualToString:@"update"]) {
        return CPLogEntryTypeUpdate;
    } else if ([typeString isEqualToString:@"love"]) {
        return CPLogEntryTypeLove;
    } else {
        // this shouldn't ever happen
        // always expect a type from API
        return -1;
    }
}

@end
