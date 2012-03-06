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
@property (weak, nonatomic) IBOutlet UIButton *chatButton;


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
