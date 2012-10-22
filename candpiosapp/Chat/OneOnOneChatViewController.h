//
//  OneOnOneChatViewController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OneOnOneChatHistory.h"

@interface OneOnOneChatViewController : UIViewController
    <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CPUser *user;
@property (strong, nonatomic) CPUser *me;
@property (strong, nonatomic) OneOnOneChatHistory *history;
@property (weak, nonatomic) IBOutlet UITextField *chatEntryField;
@property (weak, nonatomic) IBOutlet UITableView *chatContents;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *chatInputs;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic) CGRect originalChatContentsRect;
@property (nonatomic) CGRect originalChatInputsRect;

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
