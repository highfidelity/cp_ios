//
//  ChatMessage.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessage : NSObject

@property (nonatomic) BOOL fromMe;
@property (strong, nonatomic) CPUser *fromUser;
@property (strong, nonatomic) CPUser *toUser;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSDate *date;

- (id)initWithMessage:(NSString *)newMessage
               toUser:(CPUser *)toUser
             fromUser:(CPUser *)fromUser;
- (id)initWithMessage:(NSString *)newMessage
               toUser:(CPUser *)toUser
             fromUser:(CPUser *)fromUser
                 date:(NSDate *)date;

- (NSComparisonResult)compareDateWith:(ChatMessage *)message;

@end
