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

@property (nonatomic, strong) User   *user;
@property (nonatomic, strong) User   *me;
@property (nonatomic, strong) OneOnOneChatHistory *history;
@property (nonatomic, weak) IBOutlet UITextField *chatEntryField;
@property (nonatomic, weak) IBOutlet UITableView *chatContents;
@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UIView *chatInputs;
@property (nonatomic, weak) IBOutlet UIButton *chatButton;
@property CGRect originalChatContentsRect;
@property CGRect originalChatInputsRect;


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
