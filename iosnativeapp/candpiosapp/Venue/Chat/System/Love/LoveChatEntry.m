//
//  LoveChatEntry.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveChatEntry.h"

@implementation LoveChatEntry

@synthesize sender = _lover;
@synthesize recipient = _reciever;

- (LoveChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter
{
    if (self = [super initFromJSON:json dateFormatter:dateFormatter]) {
        self.sender = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"is_system.sender"]];
        self.recipient = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"is_system.recipient"]];
    }
    return self;
}

@end
