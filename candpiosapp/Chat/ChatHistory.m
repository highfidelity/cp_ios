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

@implementation ChatHistory

#pragma mark - Initializers

- (id)init {
    if (self = [super init]) {
        self.messages = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - History inspection methods

- (BOOL)isTimestampNecessaryBetween:(ChatMessage *)prevMessage
                         andMessage:(ChatMessage *)nextMessage
{
    
    NSTimeInterval delta = [nextMessage.date
                            timeIntervalSinceDate:prevMessage.date];
    
    // If it's been more than X minutes since the last message,
    // throw in a timestamp
    if ( delta >= ADD_TIMESTAMP_INTERVAL )
    {
        return YES;
    }
    
    return NO;
}

- (NSInteger)count
{
    return [self.messages count];
}


#pragma mark - Add to history

// Inserts a message to the message array based on the timestamp
- (void)insertMessage:(ChatMessage *)message
{
    NSInteger insertLocation = 1;
    
    for (ChatMessage *checkMessage in self.messages)
    {
        if ([message.date compare:checkMessage.date] == NSOrderedAscending)
        {
            break;
        }
        insertLocation++;
    }
    
    // insert the message if it's in the middle of the array, otherwise
    // append that sucker
    if (insertLocation < [self count])
    {
        [self.messages insertObject:message
                            atIndex:insertLocation];
    }
    else
    {
        [self addMessage:message];
    }
}

// Add a message to the messages array for the given user
- (void)addMessage:(ChatMessage *)message
{    
    [self.messages addObject:message];
    
    //[self addTimestamps];
}


#pragma mark - Retrieve from history

// Can return either a ChatMessage or NSDate object
- (id)messageAtIndex:(NSUInteger)index
{
    return [self.messages objectAtIndex:index];
}


#pragma mark - Misc functions

- (void)sort
{
    [self.messages sortUsingSelector:@selector(compareDateWith:)];
}


@end
