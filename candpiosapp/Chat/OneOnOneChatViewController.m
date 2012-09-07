//
//  OneOnOneChatViewController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OneOnOneChatViewController.h"
#import "ChatMessage.h"
#import "ChatMessageCell.h"
#import "CPChatHelper.h"

float const CHAT_CELL_PADDING_Y           = 12.0f;
float const CHAT_BUBBLE_PADDING_TOP       = 5.0f;
float const CHAT_BUBBLE_PADDING_BOTTOM    = 5.0f;
float const CHAT_BUBBLE_IMG_TOP_HEIGHT    = 14.0f;
float const CHAT_BUBBLE_IMG_MIDDLE_HEIGHT = 13.0f;
float const CHAT_BUBBLE_IMG_BOTTOM_HEIGHT = 14.0f;
float const CHAT_MESSAGE_LABEL_Y          = 14.0;
float const CHAT_MESSAGE_LABEL_BOTTOM_PADDING = 4.0;
float const CHAT_MESSAGE_LABEL_WIDTH      = 220.0f;
float const TIMESTAMP_CELL_WIDTH          = 304.0f;
float const TIMESTAMP_CELL_HEIGHT         = 18.0f;

static CGFloat const FONTSIZE = 14.0;

@interface OneOnOneChatViewController()
- (CGFloat)labelHeight:(ChatMessage *)message;
- (void)scrollToLastChat;
@end

@implementation OneOnOneChatViewController


#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the "me" object. It's a wonder why we don't just hae
    self.me = [CPUserDefaultsHandler currentUser];
    
    self.title = self.user.nickname;
    
    self.history = [[OneOnOneChatHistory alloc] initWithMyUser:self.me
                                                  andOtherUser:self.user];
    
    // Load the last few lines of chat
    void (^afterLoadingHistory)() = ^() {
        [self.chatContents reloadData];
        [self scrollToLastChat];
    };
    [self.history loadChatHistoryWithSuccessBlock:afterLoadingHistory];
    
    // Set up the fancy background on view
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-light.png"]];
    
    // Make our chat button FANCY!
    UIImage *chatButtonImage = [[UIImage imageNamed:@"button-turquoise-32pt.png"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7, 0, 9)];
    
    [self.chatButton setBackgroundImage:chatButtonImage forState:UIControlStateNormal];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // be the activeChatViewController of the CPChatHelper
    [CPChatHelper sharedHelper].activeChatViewController = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // no longer the activeChatViewController of the CPChatHelper
    [CPChatHelper sharedHelper].activeChatViewController = nil;
}

#pragma mark - Misc Functions

- (void)closeModalView
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addCloseButton
{
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Close"
                                    style:UIBarButtonItemStyleBordered
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
    self.originalChatContentsRect = self.chatContents.frame;
    self.originalChatInputsRect = self.chatInputs.frame;
    
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
                         self.chatContents.frame = self.originalChatContentsRect;
                         self.chatInputs.frame = self.originalChatInputsRect;
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

- (BOOL)shouldRowHaveTimestamp:(NSUInteger) row
{
    if (row == 0)
    {
        return YES;
    }
    else
    {
        ChatMessage *prevMessage = [self.history messageAtIndex:row - 1];
        ChatMessage *nextMessage = [self.history messageAtIndex:row];
        
        if ([self.history isTimestampNecessaryBetween:prevMessage
                                           andMessage:nextMessage])
        {
            return YES;
        }
    }
    
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    
    // Optionally add a timestamp height if we need one
    if ([self shouldRowHaveTimestamp:indexPath.row])
    {
        height += TIMESTAMP_CELL_HEIGHT;
    }
        
    // Figure out what the top and bottom bubble heights are
    int labelHeight = [self labelHeight:[self.history
                                         messageAtIndex:indexPath.row]];
    int topAndBottomBubbleHeight;    
    if (labelHeight > CHAT_BUBBLE_IMG_TOP_HEIGHT)
    {
        topAndBottomBubbleHeight = labelHeight / 2;
    }
    else
    {
        topAndBottomBubbleHeight = CHAT_BUBBLE_IMG_TOP_HEIGHT;
    }
        
    height += CHAT_BUBBLE_PADDING_TOP;
    height += topAndBottomBubbleHeight;
    height += CHAT_BUBBLE_IMG_MIDDLE_HEIGHT;
    height += topAndBottomBubbleHeight;
    height += CHAT_MESSAGE_LABEL_BOTTOM_PADDING;
    height += CHAT_BUBBLE_PADDING_BOTTOM;
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatMessageCell *cell = nil;
    ChatMessage *message = [self.history messageAtIndex:indexPath.row];
    
    UILabel *chatMessageLabel = nil;
    UIImageView *topBubble = nil;
    UIImageView *middleBubble = nil;
    UIImageView *bottomBubble = nil;
    NSString *imageFilenamePrefix = nil;
    UILabel *timestampLabel = nil;
    NSString *cellIdentifier = @"";
    
    if (message.fromMe)
    {
        cellIdentifier = @"MyChatCell";
        imageFilenamePrefix = @"chat-bubble-right-";
    }
    else
    {
        cellIdentifier = @"TheirChatCell";
        imageFilenamePrefix = @"chat-bubble-left-";
    }
    // Check to see if we should have a timestamp
    if ([self shouldRowHaveTimestamp:indexPath.row])
    {
        cellIdentifier = [cellIdentifier stringByAppendingString: @"withTimestamp"];
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        @throw [NSException exceptionWithName:@"Chat Cell ID is incorrect."
                                       reason:nil
                                     userInfo:nil];
    }        
        
    // See if we should draw a timestamp cell
    if ([self shouldRowHaveTimestamp:indexPath.row])
    {
        timestampLabel = (UILabel *)[cell viewWithTag:TIMESTAMP_TAG];
        NSDate *timestamp = message.date;
                
        // Get our date format. Ex: "Feb 27, 2012 — 10:04am"
        NSString *timeString;
        NSDateFormatter *timestampFormat = [[NSDateFormatter alloc] init];
        
        // Get the first half of the timestamp
        timestampFormat.dateFormat = @"LLL d, YYYY";
        timeString = [timestampFormat stringFromDate:timestamp];
        
        // Get the second half of the timestamp. Note that we have to lowercase
        // the AM/PM portion
        timestampFormat.dateFormat = @" — h:mm a";        
        timeString = [timeString stringByAppendingString:
                      [[timestampFormat stringFromDate:timestamp] lowercaseString]];
                
        timestampLabel.text = timeString;
    }
        
    chatMessageLabel = (UILabel *)[cell viewWithTag:CHAT_LABEL_TAG];
    topBubble        = (UIImageView *)[cell viewWithTag:BUBBLE_TOP_TAG];
    middleBubble     = (UIImageView *)[cell viewWithTag:BUBBLE_MIDDLE_TAG];
    bottomBubble     = (UIImageView *)[cell viewWithTag:BUBBLE_BOTTOM_TAG];
    
    // Create scalable images
    UIImage *topBubbleImg = [[UIImage imageNamed:[imageFilenamePrefix stringByAppendingString:@"top.png"]] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 0, 0, 0)];
    topBubble.image = topBubbleImg;
    
    UIImage *middleBubbleImg = [UIImage imageNamed:[imageFilenamePrefix stringByAppendingString:@"middle.png"]];
    middleBubble.image = middleBubbleImg;
    
    UIImage *bottomBubbleImg = [[UIImage imageNamed:[imageFilenamePrefix stringByAppendingString:@"bottom.png"]] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 13, 0)];
    bottomBubble.image = bottomBubbleImg;
        
    CGRect labelRect = CGRectMake(chatMessageLabel.frame.origin.x,
                                  chatMessageLabel.frame.origin.y,
                                  CHAT_MESSAGE_LABEL_WIDTH,
                                  [self labelHeight:message]);
    
    chatMessageLabel.frame = labelRect;
    chatMessageLabel.text = message.message;
        
    // Figure out the dynamic height portion of the top and bottom bubble
    CGFloat topAndBottomHeight = [self labelHeight:message] / 2 +CHAT_MESSAGE_LABEL_BOTTOM_PADDING;
    
    // Calculate the Y and HEIGHT of the top bubble
    CGFloat topBubbleHeight = CHAT_BUBBLE_IMG_TOP_HEIGHT;
    if (topAndBottomHeight > CHAT_BUBBLE_IMG_TOP_HEIGHT)
    {
        topBubbleHeight = topAndBottomHeight;
    }
    
    CGRect topBubbleRect = CGRectMake(topBubble.frame.origin.x,
                                      topBubble.frame.origin.y,
                                      topBubble.frame.size.width,
                                      topBubbleHeight);
    topBubble.frame = topBubbleRect;
    
    // Calculate the Y and HEIGHT of the middle bubble
    CGFloat middleButtonY = topBubble.frame.origin.y +
                            topBubble.frame.size.height;
    
    CGRect middleBubbleRect = CGRectMake(middleBubble.frame.origin.x, 
                                         middleButtonY, 
                                         middleBubble.frame.size.width, 
                                         middleBubble.frame.size.height);
    middleBubble.frame = middleBubbleRect;
    
    // Calculate the Y and HEIGHT of the bottm bubble
    CGFloat bottomBubbleY = middleBubble.frame.origin.y +
                            middleBubble.frame.size.height;
    
    CGFloat bottomBubbleHeight = CHAT_BUBBLE_IMG_BOTTOM_HEIGHT;
    if (topAndBottomHeight > CHAT_BUBBLE_IMG_BOTTOM_HEIGHT)
    {
        bottomBubbleHeight = topAndBottomHeight;
    }    
    CGRect bottomBubbleRect = CGRectMake(bottomBubble.frame.origin.x, 
                                         bottomBubbleY, 
                                         bottomBubble.frame.size.width, 
                                         bottomBubbleHeight);
    bottomBubble.frame = bottomBubbleRect;
        
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

@end
