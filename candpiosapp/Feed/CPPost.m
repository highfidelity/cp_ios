//
//  CPPost.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPPost.h"
#import "GTMNSString+HTML.h"

@implementation CPPost

@synthesize postID = _postID;
@synthesize entry = _entry;
@synthesize author = _author;
@synthesize date = _date;
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize receiver = _receiver;
@synthesize skill = _skill;
@synthesize type = _type;
@synthesize replies = _replies;
@synthesize originalPostID = _originalPostID;
@synthesize likeCount = _likeCount;
@synthesize userHasLiked = _userHasLiked;

static NSDateFormatter *postDateFormatter;

+ (void)initialize
{
    if (!postDateFormatter) {
        postDateFormatter = [[NSDateFormatter alloc] init];
        postDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        postDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
}

- (id)initFromDictionary:(NSDictionary *)postDict
{
    if (self = [self init]) {
        self.postID = [[postDict objectForKey:@"id"] integerValue];
        self.entry = [postDict objectForKey:@"entry"];
        self.date = [postDateFormatter dateFromString:[postDict objectForKey:@"date"]];
        self.likeCount = [[postDict objectForKey:@"like_count"] integerValue];
        self.userHasLiked = [[postDict objectForKey:@"user_has_liked"] boolValue];
        
        // alloc-init user objects for author and receiver if we have them
        // we should always have an author
        if ([postDict objectForKey:@"author"]) {
            self.author = [[User alloc] initFromDictionary:[postDict objectForKey:@"author"]];
        } 
        
        // only attempt to pull the receiver if the key exists and the object for that key isn't null
        // if it's null we don't have that user in the database anymore
        if ([postDict objectForKey:@"receiver"] && ![[postDict objectForKey:@"receiver"] isKindOfClass:[NSNull class]]) {
            self.receiver = [[User alloc] initFromDictionary:[postDict objectForKey:@"receiver"]];
        }
        
        // if we have a skill
        // then alloc-init one using the dictionary
        if ([postDict objectForKey:@"skill"]) {
            self.skill = [[CPSkill alloc] initFromDictionary:[postDict objectForKey:@"skill"]];
        }
        
        self.type = [self enumLogEntryTypeForString:[postDict objectForKey:@"type"]];
        self.originalPostID = [[postDict objectForKey:@"original_log_id"] integerValue];
    }
    return self;
}

- (void)setEntry:(NSString *)entry
{
    _entry = [entry gtm_stringByUnescapingFromHTML];
}

- (NSMutableArray *)replies
{
    if (!_replies) {
        _replies = [NSMutableArray array];
    }
    
    return _replies;
}

- (CPPostType)enumLogEntryTypeForString:(NSString *)typeString
{
    if ([typeString isEqualToString:@"update"]) {
        return CPPostTypeUpdate;
    } else if ([typeString isEqualToString:@"love"]) {
        return CPPostTypeLove;
    } else if ([typeString isEqualToString:@"question"]) {
        return CPPostTypeQuestion;
    } else if ([typeString isEqualToString:@"checkin"]) {
        return CPPostTypeCheckin;
    } else {
        // this shouldn't ever happen
        // always expect a type from API
        return -1;
    }
}

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    } else if (![object isKindOfClass:[self class]]) {
        return NO;
    } else if (self.postID == [object postID]) {
        return YES;
    } else {
        return NO;
    }
}

@end
