//
//  OneOnOneChatHistory.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/03/09.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatHistory.h"

@interface OneOnOneChatHistory : ChatHistory

@property (strong, nonatomic) CPUser *myUser;
@property (strong, nonatomic) CPUser *otherUser;

- (id)initWithMyUser:(CPUser *)myUser
        andOtherUser:(CPUser *)otherUser;

- (void)loadChatHistoryWithSuccessBlock:(void (^)())successfulLoading;

@end
