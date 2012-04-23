//
//  VenueChat.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueChat.h"
#import "VenueChatEntry.h"

@interface VenueChat ()
@property (nonatomic, strong) NSMutableSet *usersCounted;
@end

@implementation VenueChat

@synthesize venueIDString = _venueIDString;
@synthesize lastChatIDString = _lastChatIDString;
@synthesize chatEntries = _chatEntries;
@synthesize entryDateFormatter = _entryDateFormatter;
@synthesize activeChattersDuringInterval = _activeChattersDuringInterval;
@synthesize usersCounted = _usersCounted;


- (VenueChat *)init
{
    if (self = [super init]) {
        self.activeChattersDuringInterval = 0;
    }
    return self;
}

- (NSDateFormatter *)entryDateFormatter
{
    if (!_entryDateFormatter) {
        _entryDateFormatter = [[NSDateFormatter alloc] init];
        [_entryDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return _entryDateFormatter;
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

- (void)getNewChatEntriesWithCompletion:(void (^)(BOOL authenticated, BOOL newEntries))completion
{
    [CPapi getVenueChatForVenueWithID:self.venueIDString lastChatID:self.lastChatIDString completion:^(NSDictionary *dict, NSError *error) {
        if (!error) {
            // we have a payload to check out
            if (![[dict objectForKey:@"error"] boolValue]) {
                // no error, parse the chat if there is any
                [self addNewChatEntriesFromDictionary:dict completion:^(BOOL newEntries){
                    completion(YES, newEntries);
                }];
            }
            else {
                // error, means the user isn't logged in (since we know we passed a venue ID)
                completion(NO, NO);
            }
        }
    }];
}

- (void)addNewChatEntriesFromDictionary:(NSDictionary *)dict completion:(void (^)(BOOL newEntries))completion
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
        self.lastChatIDString = [dict valueForKeyPath:@"payload.lastId"];
        
        // setup an NSDate object for the time VENUE_CHAT_ACTIVE_INTERVAL days ago
        int interval = -VENUE_CHAT_ACTIVE_INTERVAL * 3600 * 24;
        NSDate *dateAtInterval = [[NSDate alloc] initWithTimeIntervalSinceNow:interval];
        
        // setup the mutableChatEntries array to hold new entries
        NSMutableArray *mutableChatEntries = [self.chatEntries mutableCopy];
        
        // go through the chat entries and add them to the array of chat entries
        for (NSDictionary *entryJSON in entries) {
            // create a VenueChatEntry and add it to the array of chat entries
            VenueChatEntry *entry = [[VenueChatEntry alloc] initWithJSON:entryJSON dateFormatter:self.entryDateFormatter]; 
            [mutableChatEntries addObject:entry];
            
            // if this entry is after the time interval then add it to the count
            if ([entry.date compare:dateAtInterval] != NSOrderedAscending) {
                // check if we've already counted this user
                NSString *userIDString = [NSString stringWithFormat:@"%d", entry.user.userID];
                if (![self.usersCounted containsObject:userIDString]) {
                    self.activeChattersDuringInterval += 1;
                    [self.usersCounted addObject:userIDString];
                }
                
            }
        }
        
        // set the chatEntries property to the mutableChat we were using
        self.chatEntries = [NSArray arrayWithArray:mutableChatEntries];
        
        if (completion) {
            completion(YES);
        }
    } else {
        // we didn't get any new entries
        if (completion) {
            completion(NO);
        }
    }
}

@end

