//
//  OneOnOneChatViewController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OneOnOneChatViewController.h"
#import "CPapi.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "CPUIHelper.h"
#import "ChatMessage.h"
#import "ChatMessageCell.h"

float const CHAT_CELL_PADDING_Y = 12.0f;
float const CHAT_PADDING_Y = 5.0f;
float const CHAT_PADDING_X = 5.0f;
// TODO: make this determined by the amount of text in the chat
float const CHAT_BOX_HEIGHT = 30.0f;
// TODO: make this determined by the containing view's width
float const CHAT_BOX_WIDTH = 280.0f;

static CGFloat const FONTSIZE = 14.0;
static int const DATELABEL_TAG = 1;
static int const MESSAGELABEL_TAG = 2;
static int const IMAGEVIEW_TAG_1 = 3;
static int const IMAGEVIEW_TAG_2 = 4;
static int const IMAGEVIEW_TAG_3 = 5;

UIColor *MY_CHAT_COLOR = nil;
UIColor *THEIR_CHAT_COLOR = nil;

@interface OneOnOneChatViewController()

- (CGFloat)labelHeight:(ChatMessage *)message;
- (void)scrollToLastChat;

@end

@implementation OneOnOneChatViewController

@synthesize user = _user;
@synthesize me = _me;
@synthesize history = _history;

@synthesize chatEntryField = _chatEntryField;
@synthesize chatContents = _chatContents;
@synthesize backgroundView = _backgroundView;
@synthesize chatInputs = _chatInputs;


#pragma mark - Misc Functions

- (void)closeModalView
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addCloseButton
{
    NSLog(@"attempting to add close button");
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Close"
                                    style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(closeModalView)];
    
    self.navigationItem.leftBarButtonItem = closeButton;
}

- (void)scrollToLastChat
{
    if ([self.history count] - 1 >= 0) {
        // Scroll to the bottom of the table view
        NSIndexPath *lastCell = [NSIndexPath indexPathForRow:[self.history count] - 1
                                                   inSection:0];
        [self.chatContents scrollToRowAtIndexPath:lastCell
                                 atScrollPosition:UITableViewScrollPositionBottom
                                         animated:NO];

    }
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double scrollSpeed = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // Save original positions
    originalChatContentsRect = self.chatContents.frame;
    originalChatInputsRect = self.chatInputs.frame;
    
    // Shrink the height of the table view by the # of points that the keyboard
    // will occupy
    CGRect newChatContentsRect = CGRectMake(self.chatContents.frame.origin.x,
                                            self.chatContents.frame.origin.y,
                                            self.chatContents.frame.size.width, 
                                            self.chatContents.frame.size.height - keyboardRect.size.height);
    
    // Raise the inputs by the # of points that the keyboard will occupy
    CGRect newChatInputRect = CGRectMake(self.chatInputs.frame.origin.x,
                                         self.chatInputs.frame.origin.y - keyboardRect.size.height, 
                                         self.chatInputs.frame.size.width, 
                                         self.chatInputs.frame.size.height);
    
    [UIView animateWithDuration:scrollSpeed
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.chatContents.frame = newChatContentsRect;
                         self.chatInputs.frame = newChatInputRect;
                     }
                     completion:nil];
    [self scrollToLastChat];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    // Return the chatContents and the inputs to their original position
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.chatContents.frame = originalChatContentsRect;
                         self.chatInputs.frame = originalChatInputsRect;
                     }
                     completion:nil];
    [self scrollToLastChat];
}


#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    return [self.history count];
}

// We only have 1 section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)labelHeight:(ChatMessage *)message
{
    CGSize maximumLabelSize = CGSizeMake(CHAT_BOX_WIDTH, 9999);
    CGSize expectedLabelSize = [message.message sizeWithFont:[UIFont systemFontOfSize: FONTSIZE]
                                constrainedToSize:maximumLabelSize
                                    lineBreakMode:UILineBreakModeWordWrap];
    return expectedLabelSize.height;
}

//---returns the height for the table view row---
- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int labelHeight = [self labelHeight:[self.history
                                         messageAtIndex:indexPath.row]];
    
    // TODO: account for graphics
    //labelHeight -= bubbleFragment_height;
    if (labelHeight < 0) labelHeight = 0;
    
    //return (bubble_y + bubbleFragment_height * 2 + labelHeight) + 5;
    return labelHeight + 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatMessageCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:@"MyChatCell"];
    
    if (cell == nil)
    {
        // We're making our cell template in the storyboard, so just crash
        // if we get here.
        @throw [NSException exceptionWithName:@"Chat Cell ID is incorrect."
                                       reason:nil
                                     userInfo:nil];
    }
    
    // Set up the message bubble for the particular message
    ChatMessage *message = [self.history messageAtIndex:indexPath.row];
    
    if (message.fromMe)
    {
        cell.chatMessageLabel.textAlignment = UITextAlignmentRight;
        cell.chatMessageLabel.backgroundColor = MY_CHAT_COLOR;
    }
    else
    {
        cell.chatMessageLabel.textAlignment = UITextAlignmentLeft;
        cell.chatMessageLabel.backgroundColor = THEIR_CHAT_COLOR;
    }
    
    CGRect labelRect = CGRectMake(cell.chatMessageLabel.frame.origin.x, 
                                  cell.chatMessageLabel.frame.origin.y,
                                  cell.chatMessageLabel.frame.size.width,
                                  [self labelHeight:message]);
    cell.chatMessageLabel.frame = labelRect;
    cell.chatMessageLabel.text = message.message;
    
    
    return cell;
}


/*********************************************************************/
#pragma mark - Chat Logic methods

// We received a string of text for the current chat. The far-end
// user should already be known in our model
- (void)receiveChatText:(NSString *)messageText {
    ChatMessage *message = [[ChatMessage alloc] initWithMessage:messageText
                                                         toUser:self.me
                                                       fromUser:self.user];
    [self.history addMessage:message];
    [self.chatContents reloadData];
    [self scrollToLastChat];
}

- (void)deliverChatMessage:(ChatMessage *)message
{
    [CPapi sendOneOnOneChatMessage:message.message
                            toUser:message.toUser.userID];
    [self.history addMessage:message];
    [self.chatContents reloadData];
    [self scrollToLastChat];
}

- (IBAction)sendChat {
    if (![self.chatEntryField.text isEqualToString:@""]) {
        // Don't do squat on empty chat entries
        ChatMessage *message = [[ChatMessage alloc]
                                initWithMessage:self.chatEntryField.text
                                         toUser:self.user
                                       fromUser:self.me];
        
        [self deliverChatMessage:message];
        // Clear chat box text
        self.chatEntryField.text = @"";
    }
}


#pragma mark - Delegate & Outlet functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {    
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[AppDelegate instance] hideCheckInButton];
        
    MY_CHAT_COLOR = [CPUIHelper colorForCPColor:CPColorGreen];
    THEIR_CHAT_COLOR = [CPUIHelper colorForCPColor:CPColorGrey];
    
    // Setup the "me" object. It's a wonder why we don't just hae
    self.me = [[User alloc] init];
    self.me.userID = [[AppDelegate instance].settings.candpUserId intValue];
    self.me.nickname = [AppDelegate instance].settings.userNickname;

    self.history = [[ChatHistory alloc] init];
    
    NSLog(@"Preparing to chat with user %@ (id: %d)",
          self.user.nickname,
          self.user.userID);
    
    self.title = self.user.nickname;
        
    // Set up the fancy background on view
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-dark.png"]];
    
    // Set up the chat entry field
    self.chatEntryField.delegate = self;
    
    // Add notifications for keyboard showing / hiding
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)viewDidUnload
{
    [[AppDelegate instance] showCheckInButton];
    [self setChatEntryField:nil];
    [self setChatContents:nil];
    [self setBackgroundView:nil];
    [self setChatInputs:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/* PROBABLY GONNA DELETE THIS, THOUGHT I LIKE THE IDEA.
   It doesn't seem to work as intended.
 
- (void)loadWithUserId:(NSString *)userId
            andMessage:(NSString *)message {
    
    self.user.userID = [userId intValue];
    
    [SVProgressHUD showWithStatus:@"Starting Chat"];
    
    [self.user loadUserResumeData:^(User *user, NSError *error) {
        NSLog(@"We're in here doing something...");
        if (!error) {
            self.user = user;   
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD dismissWithError:[error localizedDescription]];
        }
    }];
    
    [self addChatMessageToView:message
                      sentByMe:NO];
}
*/

@end
