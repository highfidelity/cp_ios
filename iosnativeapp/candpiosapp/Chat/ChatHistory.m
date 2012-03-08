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

// Method to go through the array and add timestamps where necessary
- (void)addTimestamps;

@end

@implementation ChatHistory

@synthesize messages = _messages;


#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    self.messages = [[NSMutableArray alloc] init];
    
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

- (void)addTimestamps
{
    // Messages can be either timestamps (NSDate) or
    // actual messages (ChatMessage). We need to determine this as we go.
    id prevObject = nil;
    id nextObject = nil;
    
    NSInteger insertLocation = -1;
    
    for (id checkObject in self.messages)
    {
        // Increment at the beginning because we can get bucked out of this
        // loop at a few places
        insertLocation++;
        
        // Handle the case for the first message in the array
        if (prevObject == nil)
        {
            prevObject = checkObject;
            continue;
        }
        
        nextObject = checkObject;
        
        if ([prevObject isKindOfClass:[ChatMessage class]] &&
            [nextObject isKindOfClass:[ChatMessage class]])
        {
            // If both previous and next are ChatMessages, see if we need
            // to insert a timestamp here
            ChatMessage *prevMessage = (ChatMessage *)prevObject;
            ChatMessage *nextMessage = (ChatMessage *)nextObject;
            
            NSTimeInterval delta = [nextMessage.date
                                    timeIntervalSinceDate:prevMessage.date];
                        
            // If it's been more than X minutes since the last message,
            // throw in a timestamp
            if ( delta >= ADD_TIMESTAMP_INTERVAL )
            {
                [self.messages insertObject:nextMessage.date
                                    atIndex:insertLocation];
                
                // Now we do something ugly. Since you're not supposed to
                // modify an array that you're doing fast enumeration on,
                // we start all over again and kill this loop.
                // TODO: feel free to make this less ugly.
                [self addTimestamps];
                break;
            }
        }
        
        prevObject = nextObject;
    }
}

// Inserts a message to the message array based on the timestamp
- (void)insertMessage:(ChatMessage *)message
{
    NSInteger insertLocation = 1;
    
    for (id checkObject in self.messages)
    {
        // Make sure that the current object is 
        if ([checkObject isKindOfClass:[ChatMessage class]])
        {
            ChatMessage *checkMessage = (ChatMessage *)checkObject;
            if (message.date > checkMessage.date)
            {
                break;
            }
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

@end
