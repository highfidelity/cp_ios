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

extern UIColor *MY_CHAT_COLOR;
extern UIColor *THEIR_CHAT_COLOR;

@interface OneOnOneChatViewController : UIViewController <UITextFieldDelegate> {
    UITextField *chatEntryField;
    CGRect      nextChatBoxRect;
}

@property (strong)          User     *user;
@property (assign)          CGRect   nextChatBoxRect;
@property (weak, nonatomic) IBOutlet UITextField *chatEntryField;
@property (weak, nonatomic) IBOutlet UIScrollView *chatContents;

- (void)loadWithUserId:(NSString *)userId
            andMessage:(NSString *)message;

- (void)deliverChatMessage:(NSString *)message;
- (void)receiveChatMessage:(NSString *)message;
- (void)addCloseButton;
- (IBAction)sendChat;

- (void)closeModalView;

@end
