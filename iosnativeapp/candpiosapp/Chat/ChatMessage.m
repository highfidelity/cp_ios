//
//  ChatMessage.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatMessage.h"
#import "AppDelegate.h"

@implementation ChatMessage

@synthesize fromMe = _fromMe;
@synthesize fromUser = _fromUser;
@synthesize toUser = _toUser;
@synthesize message = _message;
@synthesize date = _date;

- (id)init {
    self = [super init];
    return self;
}

- (id)initWithMessage:(NSString *)newMessage
               toUser:(User *)toUser
             fromUser:(User *)fromUser
{
    self = [super init];
        
    self.message = newMessage;
    self.fromUser = fromUser;
    self.toUser = toUser;
    self.date = [NSDate date];
    
    // Automatically determine if this is my message
    if ([[AppDelegate instance].settings.candpUserId intValue] ==
        fromUser.userID)
    {
        self.fromMe = YES;
    }
    else 
    {
        self.fromMe = NO;
    }
    
    return self;
}

- (id) initWithMessage:(NSString *)newMessage
                toUser:(User *)toUser
              fromUser:(User *)fromUser
                  date:(NSDate *)date
{
    self = [self initWithMessage:newMessage
                          toUser:toUser
                        fromUser:fromUser];
    
    self.date = date;
    
    return self;
}


@end
