//
//  LoveChatEntry.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveChatEntry.h"

@implementation LoveChatEntry

@synthesize recipient = _reciever;

- (LoveChatEntry *)initFromJSON:(NSDictionary *)json 
                  dateFormatter:(NSDateFormatter *)dateFormatter
{
    if (self = [super initFromJSON:json dateFormatter:dateFormatter]) {
        // the user for this chat entry should be the sender of love
        self.user = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"system_data.sender"]];
        // set our recipient property
        self.recipient = [super userFromDictionaryOrActiveUsers:[json valueForKeyPath:@"system_data.recipient"]];
    }
    return self;
}

@end
