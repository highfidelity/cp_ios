//
//  ChatHelper.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/23.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatHelper : NSObject <UIAlertViewDelegate>

+ (void)respondToIncomingChatNotification:(NSString *)message
                             fromNickname:(NSString *)nickname
                               fromUserId:(NSInteger)userId
                             withRootView:(UIViewController *)rootView;

@end
