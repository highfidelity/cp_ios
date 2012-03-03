//
//  ChatHistory.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "ChatMessage.h"

@interface ChatHistory : NSObject

@property (nonatomic, strong) NSMutableArray* messages;

#pragma mark - Add to history
- (void)addMessage:(ChatMessage *)message;

#pragma mark - Retrieve from history
- (id)messageAtIndex:(NSUInteger)index;
- (NSInteger)count;

@end
