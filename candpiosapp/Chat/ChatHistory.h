//
//  ChatHistory.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"

@interface ChatHistory : NSObject

@property (strong, nonatomic) NSMutableArray* messages;

#pragma mark - Add to history
// Add a message to the messages array for the given user
- (void)addMessage:(ChatMessage *)message;
// Inserts a message to the message array based on the timestamp
- (void)insertMessage:(ChatMessage *)message;

#pragma mark - Retrieve from history
- (id)messageAtIndex:(NSUInteger)index;
- (NSInteger)count;

- (BOOL)isTimestampNecessaryBetween:(ChatMessage *)prevMessage
                         andMessage:(ChatMessage *)nextMessage;

#pragma mark - Misc functions

- (void)sort;

@end
