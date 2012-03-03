//
//  ChatHistory.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatHistory.h"

// Timestamp interval in seconds (15 minutes)
#define ADD_TIMESTAMP_INTERVAL  900

@interface ChatHistory()

- (void)addTimestamp:(NSDate *)date;

@end


@implementation ChatHistory

@synthesize messages = _messages;

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    self.messages = [[NSMutableArray alloc] init];
    
    return self;
}


#pragma mark - Add to history

- (void)addTimestamp:(NSDate *)date
{
    [self.messages addObject:date];
}

// Add a message to the messages array for the given user
- (void)addMessage:(ChatMessage *)message
{    
    // If we have more than 2 items, see if we need to insert a timestamp
    if ([self count] >= 2) {
        NSLog(@"Adding timestmap.");
        ChatMessage *oldMessage   = [self.messages objectAtIndex:[self count] - 1];
        
        NSTimeInterval delta = [message.date
                                timeIntervalSinceDate:oldMessage.date];
        
        // If it's been more than 30 minutes since the last message, put in a
        // timestamp
        if ( delta >= ADD_TIMESTAMP_INTERVAL ) {
            [self addTimestamp:[NSDate date]];
        }
    }
    
    [self.messages addObject:message];
}


#pragma mark - Retrieve from history

// Can return either a ChatMessage or NSDate object
- (id)messageAtIndex:(NSUInteger)index
{
    return [self.messages objectAtIndex:index];
}

- (NSInteger)count
{
    return [self.messages count];
}

@end
