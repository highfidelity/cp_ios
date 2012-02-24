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

float const CHAT_PADDING_Y = 5.0f;
float const CHAT_PADDING_X = 5.0f;
// TODO: make this determined by the amount of text in the chat
float const CHAT_BOX_HEIGHT = 30.0f;
// TODO: make this determined by the containing view's width
float const CHAT_BOX_WIDTH = 250.0f;

@interface OneOnOneChatViewController()

-(void)sendChatMessage:(NSString *)message;
-(void)addChatMessageToView:(NSString *)message
                   sentByMe:(BOOL)myMessage;

@end

@implementation OneOnOneChatViewController

@synthesize user = _user;
@synthesize nextChatBoxRect = _nextChatBoxRect;
@synthesize chatEntryField = _chatEntryField;
@synthesize chatContents = _chatContents;


- (void)closeModalView
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Chat Logic functions

- (void)addChatMessageToView:(NSString *)message sentByMe:(BOOL)myMessage{
    NSLog(@"Inserting new chat box at (%f, %f) w(%f) h(%f)",
          self.nextChatBoxRect.origin.x,
          self.nextChatBoxRect.origin.y,
          self.nextChatBoxRect.size.width,
          self.nextChatBoxRect.size.height);
    
    // Insert the chat entry as a UI element
    UILabel *newChatEntry = [[UILabel alloc] initWithFrame:self.nextChatBoxRect];
    
    newChatEntry.text = message;
    
    if (myMessage) {
        newChatEntry.backgroundColor = [UIColor greenColor];
        newChatEntry.textAlignment = UITextAlignmentRight;
    } else {
        newChatEntry.backgroundColor = [UIColor redColor];
        newChatEntry.textAlignment = UITextAlignmentLeft;
    }
    
    [self.chatContents addSubview:newChatEntry];
    
    // Increase size of scroll view if necessary
    float nextChatBoxBottom = self.nextChatBoxRect.origin.y + self.nextChatBoxRect.size.height;
    NSLog(@"Should we resize? chatContents = h(%f) and nextChatBoxBottom = %f",
          self.chatContents.contentSize.height,
          nextChatBoxBottom);
    
    if (self.chatContents.contentSize.height < nextChatBoxBottom) {
        CGSize newSize = CGSizeMake(self.chatContents.contentSize.width,
                                    nextChatBoxBottom + CHAT_PADDING_Y);
        self.chatContents.contentSize = newSize;
        // Scroll to bottom of the chat window
        CGPoint bottomOffset = CGPointMake(0.0f,
                                           self.chatContents.contentSize.height -
                                           self.chatContents.bounds.size.height);
        [self.chatContents setContentOffset: bottomOffset
                                   animated:NO];
        
    }
    
    // Update the lastChatBoxPosition
    self.nextChatBoxRect = CGRectMake(newChatEntry.frame.origin.x,
                                      newChatEntry.frame.origin.y +
                                        newChatEntry.bounds.size.height +
                                      CHAT_PADDING_Y,
                                      CHAT_BOX_WIDTH,
                                      CHAT_BOX_HEIGHT);
}

- (void)receiveChatMessage:(NSString *)message {
    [self addChatMessageToView:message sentByMe:NO];
    
    NSLog(@"Chat entry received: %@", message);
}

- (IBAction)sendChat {
    if (self.chatEntryField.text == @"") {
        // Don't do squat on empty chat entries
    } else {
        [self sendChatMessage:self.chatEntryField.text];
        self.chatEntryField.text = @"";
    }
}

- (void)sendChatMessage:(NSString *)message {
    // Send message via UrbanAirship push notification
    [CPapi sendOneOnOneChatMessage:message toUser:self.user.userID];
    
    [self addChatMessageToView:message sentByMe:YES];
    
    NSLog(@"Chat entry made: %@", message);
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
    
    NSLog(@"Preparing to chat with user %@ (id: %d)", self.user.nickname, self.user.userID);
    self.title = self.user.nickname;
    
    // Set up the chat entry field
    self.chatEntryField.delegate = self;
    
    // Make up the point for the first chat entry
    self.nextChatBoxRect = CGRectMake(self.chatContents.bounds.origin.x + CHAT_PADDING_X,
                                      self.chatContents.bounds.origin.y + CHAT_PADDING_Y,
                                      CHAT_BOX_WIDTH,
                                      CHAT_BOX_HEIGHT);
}

- (void)viewDidUnload
{
    //[self setChatDisplay:nil];
    [self setChatEntryField:nil];
    [self setChatContents:nil];
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


@end
