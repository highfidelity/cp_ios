//
//  ChatHistory.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatHistory.h"

@implementation ChatHistory

@synthesize messages = _messages;

- (id)init {
    self = [super init];
    
    return self;
}

// Add a message to the messages array for the given user
- (void)addMessage:(ChatMessage*) message
        fromUserId:(User*) user
{
    
    NSMutableArray* my_messages = [self.messages objectForKey:user];
    
    if (my_messages) {
        my_messages = [NSMutableArray arrayWithObject:message];
    } else {
        [my_messages addObject:message];
    }
    
    [self.messages setObject:my_messages forKey:user];
}

@end
