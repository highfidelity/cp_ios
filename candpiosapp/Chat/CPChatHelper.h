//
//  CPChatHelper.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/23.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OneOnOneChatViewController.h"

@interface CPChatHelper : NSObject <UIAlertViewDelegate>

@property (weak, nonatomic) OneOnOneChatViewController *activeChatViewController;

+ (CPChatHelper *)sharedHelper;
+ (void)respondToIncomingChatNotification:(NSString *)message
                             fromNickname:(NSString *)nickname
                               fromUserId:(NSInteger)userId;

@end
