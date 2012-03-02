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
    
    self.messages = [[NSMutableArray alloc] init];
    
    return self;
}

// Add a message to the messages array for the given user
- (void)addMessage:(ChatMessage *)message
{
    [self.messages addObject:message];
}

- (ChatMessage *)messageAtIndex:(NSUInteger)index
{
    return [self.messages objectAtIndex:index];
}

- (NSInteger)count
{
    return [self.messages count];
}

@end
