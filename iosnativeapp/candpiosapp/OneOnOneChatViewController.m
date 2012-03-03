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

float const CHAT_CELL_PADDING_Y           = 12.0f;
float const CHAT_BUBBLE_PADDING_TOP       = 6.0f;
float const CHAT_BUBBLE_PADDING_BOTTOM    = 6.0f;
float const CHAT_BUBBLE_IMG_TOP_HEIGHT    = 10.0f;
float const CHAT_BUBBLE_IMG_MIDDLE_HEIGHT = 13.0f;
float const CHAT_BUBBLE_IMG_BOTTOM_HEIGHT = 10.0f;
float const CHAT_MESSAGE_LABEL_Y          = 14.0;
float const CHAT_MESSAGE_LABEL_WIDTH      = 220.0f;
float const TIMESTAMP_CELL_WIDTH          = 304.0f;
float const TIMESTAMP_CELL_HEIGHT         = 24.0f;

static CGFloat const FONTSIZE = 14.0;


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
    CGSize maximumLabelSize = CGSizeMake(CHAT_MESSAGE_LABEL_WIDTH, 9999);
    CGSize expectedLabelSize = [message.message sizeWithFont:[UIFont systemFontOfSize: FONTSIZE]
                                           constrainedToSize:maximumLabelSize
                                               lineBreakMode:UILineBreakModeWordWrap];
    return expectedLabelSize.height;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.history messageAtIndex:indexPath.row] isKindOfClass:[NSDate class]])
    {
        return TIMESTAMP_CELL_HEIGHT;
    }
    else
    {
        int labelHeight = [self labelHeight:[self.history
                                             messageAtIndex:indexPath.row]];
        
        if (labelHeight < CHAT_BUBBLE_IMG_MIDDLE_HEIGHT)
            labelHeight = CHAT_BUBBLE_IMG_MIDDLE_HEIGHT;
        
        return CHAT_BUBBLE_PADDING_TOP +
               CHAT_BUBBLE_IMG_TOP_HEIGHT +
               labelHeight +
               CHAT_BUBBLE_IMG_BOTTOM_HEIGHT;
        //CHAT_BUBBLE_PADDING_BOTTOM;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
    ChatMessageCell *cell = nil;
    
    // Set up the message bubble for the particular message
    id historyItem = [self.history messageAtIndex:indexPath.row];
        
    if ([historyItem isKindOfClass:[NSDate class]])
    // This means we're drawing a timestamp cell
    {
        NSDate *timestamp = (NSDate *)historyItem;
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"TimestampCell"];
        UILabel *timestampLabel = (UILabel *)[cell viewWithTag:TIMESTAMP_TAG];
        
        // Get our date format. Ex: "Feb 27, 2012 — 10:04am"
        NSString *timeString;
        NSDateFormatter *timestampFormat = [[NSDateFormatter alloc] init];
        
        // Get the first half of the timestamp
        timestampFormat.dateFormat = @"LLL d, YYYY";
        timeString = [timestampFormat stringFromDate:timestamp];

        // Get the second half of the timestamp. Note that we have to lowercase
        // the AM/PM portion
        timestampFormat.dateFormat = @" — HH:MMa";        
        timeString = [timeString stringByAppendingString:
                      [[timestampFormat stringFromDate:timestamp] lowercaseString]];
        
        // Size the cell & text area to match
        CGRect timestampCellRect = CGRectMake(0,
                                              0,
                                              TIMESTAMP_CELL_WIDTH,
                                              TIMESTAMP_CELL_HEIGHT);
        
        timestampLabel.frame = timestampCellRect;
        timestampLabel.text = timeString;
        
        return cell;
    }
    
    // If we're here, then the historyItem is a chat message
    
    ChatMessage *message = (ChatMessage *)historyItem;
    
    UILabel *chatMessageLabel = nil;
    UIImageView *topBubble = nil;
    UIImageView *middleBubble = nil;
    UIImageView *bottomBubble = nil;
    
    NSString *imageFilenamePrefix = nil;
    
    if (message.fromMe)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MyChatCell"];
        imageFilenamePrefix = @"chat-bubble-right-";
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TheirChatCell"];
        imageFilenamePrefix = @"chat-bubble-left-";
    }
    
    if (cell == nil)
    {
        @throw [NSException exceptionWithName:@"Chat Cell ID is incorrect."
                                       reason:nil
                                     userInfo:nil];
    }        
    
    chatMessageLabel = (UILabel *)[cell viewWithTag:CHAT_LABEL_TAG];
    topBubble        = (UIImageView *)[cell viewWithTag:BUBBLE_TOP_TAG];
    middleBubble     = (UIImageView *)[cell viewWithTag:BUBBLE_MIDDLE_TAG];
    bottomBubble     = (UIImageView *)[cell viewWithTag:BUBBLE_BOTTOM_TAG];
    
    // Create scalable images
    UIImage *topBubbleImg = [[UIImage imageNamed:
                              [imageFilenamePrefix stringByAppendingString:@"top.png"]]  
                            resizableImageWithCapInsets:UIEdgeInsetsMake(9, 0, 0, 0)];
    topBubble.image = topBubbleImg;
    UIImage *middleBubbleImg = [UIImage imageNamed:
                                [imageFilenamePrefix stringByAppendingString:@"middle.png"]];
    middleBubble.image = middleBubbleImg;
    UIImage *bottomBubbleImg = [[UIImage imageNamed:
                                 [imageFilenamePrefix stringByAppendingString:@"bottom.png"]]  
                             resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 9, 0)];
    bottomBubble.image = bottomBubbleImg;
    
    CGRect labelRect = CGRectMake(chatMessageLabel.frame.origin.x,
                                  CHAT_MESSAGE_LABEL_Y,
                                  CHAT_MESSAGE_LABEL_WIDTH,
                                  [self labelHeight:message]);
    
    NSLog(@"Label height is: %f", [self labelHeight:message]);
    
    // Figure out the height of the top and bottom bubble
    CGFloat newTopAndBottomHeight = [self labelHeight:message] / 2;
    
    CGRect newTopBubbleRect = CGRectMake(topBubble.frame.origin.x, 
                                         topBubble.frame.origin.y, 
                                         topBubble.frame.size.width, 
                                         newTopAndBottomHeight + CHAT_BUBBLE_PADDING_TOP);
    topBubble.frame = newTopBubbleRect;
    
    // The middle bubble's Y is the top bubble's X + the top bubble's height
    CGFloat newMiddleButtonY = topBubble.frame.origin.y + newTopAndBottomHeight;
    CGRect newMiddleBubbleRect = CGRectMake(middleBubble.frame.origin.x, 
                                            newMiddleButtonY, 
                                            middleBubble.frame.size.width, 
                                            middleBubble.frame.size.height);
    middleBubble.frame = newMiddleBubbleRect;
    
    // Add the top bubble's new height & the middle bubble's height to get
    // the new bottom bubble's Y
    CGFloat newBottomBubbleY = newTopAndBottomHeight + middleBubble.frame.size.height;
    CGRect newBottomBubbleRect = CGRectMake(bottomBubble.frame.origin.x, 
                                            newBottomBubbleY, 
                                            bottomBubble.frame.size.width, 
                                            newTopAndBottomHeight + CHAT_BUBBLE_PADDING_BOTTOM);
    bottomBubble.frame = newBottomBubbleRect;
    
    chatMessageLabel.frame = labelRect;
    chatMessageLabel.text = message.message;
    
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
    
    // Setup the "me" object. It's a wonder why we don't just hae
    self.me = [[User alloc] init];
    self.me.userID = [[AppDelegate instance].settings.candpUserId intValue];
    self.me.nickname = [AppDelegate instance].settings.userNickname;

    self.history = [[ChatHistory alloc] init];
        
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
