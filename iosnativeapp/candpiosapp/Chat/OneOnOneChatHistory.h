//
//  OneOnOneChatHistory.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/03/09.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatHistory.h"

@interface OneOnOneChatHistory : ChatHistory

@property (nonatomic, strong) User *myUser;
@property (nonatomic, strong) User *otherUser;

- (id)initWithMyUser:(User *)myUser
        andOtherUser:(User *)otherUser;

- (void)loadChatHistory;

@end
