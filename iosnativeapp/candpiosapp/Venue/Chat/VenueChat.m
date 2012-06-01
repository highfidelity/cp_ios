//
//  VenueChat.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueChat.h"
#import "VenueChatEntry.h"
#import "LoveChatEntry.h"
#import "CheckinChatEntry.h"


#define MAJOR_TIMESTAMP_INTERVAL_FORMAT @"MMMM dd, yyyy"
#define MINOR_TIMESTAMP_INTERVAL_FORMAT @"h:mma - MMMM dd, yyyy"

@interface VenueChat ()
@property (nonatomic, strong) NSMutableSet *usersCounted;
@property (nonatomic, strong) NSString *previousTimestamp;
@end

@implementation VenueChat

@synthesize venueID = _venueID;
@synthesize lastChatID = _lastChatID;
@synthesize chatEntries = _chatEntries;
@synthesize entryDateFormatter = _entryDateFormatter;
@synthesize activeChattersDuringInterval = _activeChattersDuringInterval;
@synthesize usersCounted = _usersCounted;
@synthesize chatQueue = _chatQueue;
@synthesize hasLoaded = _hasLoaded;
@synthesize timestampDateFormatter = _timestampDateFormatter;
@synthesize previousTimestamp = _previousTimestamp;
@synthesize pendingTimestamp = _pendingTimestamp;

- (VenueChat *)init
{
    if (self = [super init]) {
        self.activeChattersDuringInterval = 0;
        self.hasLoaded = NO;
    }
    return self;
}

- (VenueChat *)initWithVenueID:(int)venueID
{
    if (self = [self init]) {
        self.venueID = venueID;
    }
    return self;
}

- (NSOperationQueue *)chatQueue
{
    if (!_chatQueue) {
        _chatQueue = [NSOperationQueue new];
		[_chatQueue setSuspended:NO];
		// serialize requests, please
		[_chatQueue setMaxConcurrentOperationCount:1];
    }
    return _chatQueue;
}

- (NSDateFormatter *)entryDateFormatter
{
    if (!_entryDateFormatter) {
        _entryDateFormatter = [[NSDateFormatter alloc] init];
        _entryDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        _entryDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    return _entryDateFormatter;
}

- (NSDateFormatter *)timestampDateFormatter
{
    if (!_timestampDateFormatter) {
        _timestampDateFormatter = [[NSDateFormatter alloc] init];
        _timestampDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    }
    return _timestampDateFormatter;
}


- (NSArray *)chatEntries
{
    if (!_chatEntries) {
        _chatEntries = [NSArray array];
    } 
    return _chatEntries;
}

- (NSMutableSet *)usersCounted
{
    if (!_usersCounted) {
        _usersCounted = [NSMutableSet set];
    }
    return _usersCounted;
}

- (void)getNewChatEntriesWithCompletion:(void (^)(BOOL authenticated, NSArray *newEntries))completion
{
    [CPapi getVenueChatForVenueWithID:self.venueID lastChatID:self.lastChatID queue:self.chatQueue completion:^(NSDictionary *dict, NSError *error) {
        if (!error) {                
            // we have a payload to check out
            if (![[dict objectForKey:@"error"] boolValue]) {
                // no error, parse the chat if there is any
                [self addNewChatEntriesFromDictionary:dict completion:^(NSArray *newEntries){
                    completion(YES, newEntries);
                }];
            }
            else {
                // error, means the user isn't logged in (since we know we passed a venue ID)
                completion(NO, nil);
            }
        }
    }];
}

- (void)addNewChatEntriesFromDictionary:(NSDictionary *)dict completion:(void (^)(NSArray *newEntries))completion
{
    NSMutableArray *entries = [[dict valueForKeyPath:@"payload.entries"] mutableCopy];
    
    if (entries.count > 0) {
        
        if (self.chatEntries.count > 0) {
            for (VenueChatEntry *entry in entries) {
                if ([self.chatEntries containsObject:entry]) {
                    // we already have this one so don't add it
                    [entries removeObject:entry];
                }
            }
        }       
        
#if DEBUG
        NSLog(@"Got %d venue chat entries.", entries.count);
#endif
        // set the lastChatIDString property on the VenueChat object
        // so that the subsequent call can be made for only new chat
        self.lastChatID = [[dict valueForKeyPath:@"payload.lastId"] intValue];
        
        // setup an NSDate object for the time VENUE_CHAT_ACTIVE_INTERVAL days ago
        int interval = -VENUE_CHAT_ACTIVE_INTERVAL * 3600 * 24;
        NSDate *dateAtInterval = [[NSDate alloc] initWithTimeIntervalSinceNow:interval];
        
        // setup the mutableChatEntries array to add new entries
        NSMutableArray *mutableChatEntries = [self.chatEntries mutableCopy];
        // setup the newEntries array to hold just the new entries
        NSMutableArray *newEntries = [NSMutableArray arrayWithCapacity:entries.count];
        
        NSDate *now;
        NSCalendar *cal;
        NSDateComponents *nowComps;
        
        if (!self.hasLoaded) {
            // timestamp shenanigans only happen on firstLoad of chat
            
            // grab the current time now, we'll need this to add timestamps
            // ensures all timestamp creation is done based on the same timestamp
            now = [NSDate date];
            
            // setup an NSCalendarComponents object to grab the day from entry dates
            cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            cal.timeZone = [NSTimeZone systemTimeZone];
            
            // grab month, day, year units from today
            nowComps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:now];
            
        }
        
        // go through the chat entries and add them to the array of chat entries
        for (NSDictionary *entryJSON in entries) {
             
            // check if this is a system entry
            NSString *systemType = [entryJSON objectForKey:@"system_type"];
            
            
            Class entryClass;
            
            if ([systemType isKindOfClass:[NSNull class]]) {
                // create a VenueChatEntry and add it to the array of chat entries
                entryClass = [VenueChatEntry class];
            } else if ([systemType isEqualToString:LOVE_SYSTEM_CHAT_TYPE]) {
                // this is love
                entryClass = [LoveChatEntry class];
            } else if ([systemType isEqualToString:CHECKIN_SYSTEM_CHAT_TYPE]) {
                entryClass = [CheckinChatEntry class];
            } else {
                // we have a system type that is unrecognized
                // maybe because it's being used on web and not here
                // so skip this one
                continue;
            }
            
            VenueChatEntry *entry = [[entryClass alloc] initFromJSON:entryJSON dateFormatter:self.entryDateFormatter];
            
            // if this entry is after the time interval then add it to the count
            // a checkin system chat message should also not be in the active chatter count
            if ([entry.date compare:dateAtInterval] != NSOrderedAscending && ![entry isKindOfClass:[CheckinChatEntry class]]) {
                NSString *userIDString = [NSString stringWithFormat:@"%d", entry.user.userID];
                if (![self.usersCounted containsObject:userIDString]) {
                    self.activeChattersDuringInterval += 1;
                    [self.usersCounted addObject:userIDString];
                }
            }
            
            if (!self.hasLoaded) {
                // only do timestamping on first load
                
                // grab the month, day, year units from this entry
                NSDateComponents *entryComps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:[entry date]];
                
                
                // check if this entry was more than 1 day ago
                if (entryComps.year != nowComps.year || entryComps.month != nowComps.month || entryComps.day != nowComps.day) {
                    // check if we already have a timestamp for this day
                    [self.timestampDateFormatter setDateFormat:MAJOR_TIMESTAMP_INTERVAL_FORMAT];
                    if (![self.previousTimestamp isEqualToString:[self.timestampDateFormatter stringFromDate:entry.date]]) {
                        NSLog(@"%@", entryJSON);
                        self.previousTimestamp = [self.timestampDateFormatter stringFromDate:entry.date];
                        NSLog(@"%@", self.previousTimestamp);
                        [mutableChatEntries addObject:self.previousTimestamp];
                    }
                } else {
                    // same day but we need timestamps every 15 minutes
                    int seconds = [now timeIntervalSinceDate:entry.date];
                    int leftToMinor = 900 - (seconds % 900);
                    NSDate *interval = [NSDate dateWithTimeInterval:-leftToMinor sinceDate:entry.date];
                    
                    [self.timestampDateFormatter setDateFormat:MINOR_TIMESTAMP_INTERVAL_FORMAT];
                    // check if we already have a timestamp for this minor interval
                    if (![self.previousTimestamp isEqualToString:[self.timestampDateFormatter stringFromDate:interval]]) {
                        self.previousTimestamp = [self.timestampDateFormatter stringFromDate:interval];
                        [mutableChatEntries addObject:[self.timestampDateFormatter stringFromDate:entry.date]];
                    }
                }
            } else if (self.pendingTimestamp) {

                // we have a timestamp to add because of a load of the venue chat
                [self.timestampDateFormatter setDateFormat:MINOR_TIMESTAMP_INTERVAL_FORMAT];
                [mutableChatEntries addObject:[self.timestampDateFormatter stringFromDate:self.pendingTimestamp]];
                
                // nil out the pending timestamp now that we've added it
                self.pendingTimestamp = nil;
            }
            
            if ([entry isKindOfClass:[LoveChatEntry class]]) {
                // check if we have an entry in purgatory for this lvoe that should be deleted from our entries
                for (VenueChatEntry *oldEntry in [mutableChatEntries copy]) {
                    if ([oldEntry isKindOfClass:[LoveChatEntry class]]) {
                        if (((LoveChatEntry *)oldEntry).reviewID == ((LoveChatEntry *)entry).reviewID) {
                            [mutableChatEntries removeObject:oldEntry];
                        }
                    }
                    
                }
            }
            
            [newEntries addObject:entry];
            [mutableChatEntries addObject:entry];
        }
    
        
        // set the chatEntries property to the mutableChat we were using
        self.chatEntries = [NSArray arrayWithArray:mutableChatEntries];
        
        // indicate that we have loaded for the first time (if that hasn't already happened)
        if (!self.hasLoaded) {
            self.hasLoaded = YES;
        }
        
        if (completion) {
            completion([NSArray arrayWithArray:newEntries]);
        }
    } else {
        
        // indicate that we have loaded for the first time (if that hasn't already happened)
        if (!self.hasLoaded) {
            self.hasLoaded = YES;
        }
        
        // we didn't get any new entries
        if (completion) {
            completion(nil);
        }
    }
}

@end

