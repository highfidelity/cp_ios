//
//  ChatMessage.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessage : NSObject

@property BOOL fromMe;
@property (nonatomic, strong) User *fromUser;
@property (nonatomic, strong) User *toUser;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSDate *date;

- (id)initWithMessage:(NSString *)newMessage
               toUser:(User *)toUser
             fromUser:(User *)fromUser;
- (id)initWithMessage:(NSString *)newMessage
               toUser:(User *)toUser
             fromUser:(User *)fromUser
                 date:(NSDate *)date;

- (NSComparisonResult)compareDateWith:(ChatMessage *)message;

@end
