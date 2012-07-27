//
//  ChatMessage.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatMessage.h"

@implementation ChatMessage

- (id)initWithMessage:(NSString *)newMessage
               toUser:(User *)toUser
             fromUser:(User *)fromUser
{
    if (self = [super init]) {
        self.message = newMessage;
        self.fromUser = fromUser;
        self.toUser = toUser;
        self.date = [NSDate date];
        
        // Automatically determine if this is my message
        if ([CPUserDefaultsHandler currentUser].userID == fromUser.userID) {
            self.fromMe = YES;
        } else {
            self.fromMe = NO;
        }
    }
    
    return self;
}

- (id) initWithMessage:(NSString *)newMessage
                toUser:(User *)toUser
              fromUser:(User *)fromUser
                  date:(NSDate *)date
{
    if (self = [self initWithMessage:newMessage
                              toUser:toUser
                            fromUser:fromUser]) {
        self.date = date;
    }
    return self;
}

- (NSComparisonResult)compareDateWith:(ChatMessage *)message
{
    return [self.date compare: message.date];
}

@end
