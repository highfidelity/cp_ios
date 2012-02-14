//
//  OneOnOneChatViewController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

extern float const CHAT_PADDING_Y;
extern float const CHAT_PADDING_X;
extern float const CHAT_BOX_HEIGHT;
extern float const CHAT_BOX_WIDTH;

@interface OneOnOneChatViewController : UIViewController <UITextFieldDelegate> {
    UITextField *chatEntryField;
    CGRect      nextChatBoxRect;
}

@property (strong)          User     *user;
@property (assign)          CGRect   nextChatBoxRect;
@property (weak, nonatomic) IBOutlet UITextField *chatEntryField;
@property (weak, nonatomic) IBOutlet UIScrollView *chatContents;

- (id)initWithUserId:(NSString *)userId
          andMessage:(NSString *)message;
- (void)receiveChatMessage:(NSString *)message;

@end
