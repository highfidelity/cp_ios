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

@property (nonatomic, strong) NSMutableDictionary* messages;

- (void)addMessage:(ChatMessage*) message
        fromUserId:(User*) user;

@end
