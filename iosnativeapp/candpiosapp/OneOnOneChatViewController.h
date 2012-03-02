//
//  OneOnOneChatViewController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "ChatHistory.h"

extern float const CHAT_CELL_PADDING_Y;
extern float const CHAT_PADDING_Y;
extern float const CHAT_PADDING_X;
extern float const CHAT_BOX_HEIGHT;
extern float const CHAT_BOX_WIDTH;

extern UIColor *MY_CHAT_COLOR;
extern UIColor *THEIR_CHAT_COLOR;

@interface OneOnOneChatViewController : UIViewController
    <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UITableView *chatContents;
    UITextField *chatEntryField;
    CGRect      originalChatContentsRect;
    CGRect      originalChatInputsRect;
}

@property (strong, nonatomic) User   *user;
@property (strong, nonatomic) User   *me;
@property (strong, nonatomic) ChatHistory *history;

@property (weak, nonatomic) IBOutlet UITextField *chatEntryField;
@property (weak, nonatomic) IBOutlet UITableView *chatContents;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *chatInputs;

/*
- (void)loadWithUserId:(NSString *)userId
            andMessage:(NSString *)message;
*/

// Send message via UrbanAirship push notification
// Add message to the message history & reload the table view
- (void)deliverChatMessage:(ChatMessage *)message;
// Add message to message history & reload the table view
- (void)receiveChatText:(NSString *)message;
// The action taken when the user hits the SEND button on the chat view
- (IBAction)sendChat;

// Modal view functions
- (void)addCloseButton;
- (void)closeModalView;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
