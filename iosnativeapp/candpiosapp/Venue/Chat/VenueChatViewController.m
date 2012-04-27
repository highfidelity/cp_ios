//
//  VenueChatViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueChatViewController.h"
#import "VenueChatCell.h"
#import "UIImageView+AFNetworking.h"
#import "HPGrowingTextView.h"
#import "HPTextViewInternal.h"
#import "TimestampCell.h"
#import "MapTabController.h"
#import "UserProfileCheckedInViewController.h"

#define BLANKSHEET_VIEW_TAG 6582

@interface VenueChatViewController () <UITableViewDelegate, UITableViewDataSource, HPGrowingTextViewDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) IBOutlet UILabel *activeChatters;
@property (strong, nonatomic) UIView *chatBox;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) HPGrowingTextView *growingTextView;
@property (strong, nonatomic) UIButton *sendButton;
@property (assign, nonatomic) CGRect originalChatBoxFrame;
@property (assign, nonatomic) CGRect originalTableViewFrame;
@property (strong, nonatomic) UIActivityIndicatorView *sendingSpinner;
@property (strong, nonatomic) NSTimer *chatReloadTimer;
@property (strong, nonatomic) UIView *blankSheet;
@property (nonatomic, assign) BOOL completedFirstChatLoad;

- (void)updateActiveChattingUserCount;

@end

@implementation VenueChatViewController

// TODO: Make this a more abstract class that we can use for chat in all places in the app (One-to-One)
// That's not the case right now because the design for each is different and the model is different

@synthesize venue = _venue;
@synthesize venueChat = _venueChat;
@synthesize activeChatters = _activeChatters;
@synthesize chatBox = _chatBox;
@synthesize tableView = _tableView;
@synthesize growingTextView = _growingTextView;
@synthesize sendButton = _sendButton;
@synthesize originalChatBoxFrame = _originalChatBoxFrame;
@synthesize originalTableViewFrame = _originalTableViewFrame;
@synthesize sendingSpinner = _sendingSpinner;
@synthesize chatReloadTimer = _chatReloadTimer;
@synthesize blankSheet = _blankSheet;
@synthesize completedFirstChatLoad = _completedFirstChatLoad;


-(VenueChat *)venueChat
{
    if (!_venueChat) {
        _venueChat = [[VenueChat alloc] initWithVenueID:self.venue.venueID];
    }
    return _venueChat;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // set the title of the navigation controller to the venue name
    self.title = self.venue.name;
    
    // add NSNotificationCenter observers for when the keyboard will appear and dissapear
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];
    
    // league gothic the number of active chatters
    // and put a shadow on the text
    [CPUIHelper changeFontForLabel:self.activeChatters toLeagueGothicOfSize:self.activeChatters.font.pointSize];
    self.activeChatters.layer.shadowOffset = CGSizeMake(1, 0);
    self.activeChatters.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];

    // setup the box that will hold the chat input
    self.chatBox = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 39, [[UIScreen mainScreen] bounds].size.width, 39)];
    
    // setup the gray background on the chat box
    UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
    imageView.frame = CGRectMake(0, 0, self.chatBox.frame.size.width, self.chatBox.frame.size.height);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // Setup our fancy orange send button
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.chatBox.frame.size.width - 65, 4, 60, 32)];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.sendButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [self.sendButton setTitleShadowColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]  forState:UIControlStateNormal];
    
    UIImage *chatButtonImage = [[UIImage imageNamed:@"button-orange-32pt.png"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7, 0, 9)];
    
    [self.sendButton addTarget:self action:@selector(sendChat) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setBackgroundImage:chatButtonImage forState:UIControlStateNormal];
    self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    // chatBox autoresizing
    self.chatBox.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    // setup the view hierarchy of the chatBox
    [self.view addSubview:self.chatBox];
    [self.chatBox addSubview:imageView];
    
    [self.chatBox addSubview:self.sendButton];
    
    NSLog(@"%d, %d", [CPAppDelegate userCheckedIn], DEFAULTS(integer, kUDCheckedInVenueID));
    if ([CPAppDelegate userCheckedIn] && DEFAULTS(integer, kUDCheckedInVenueID) == self.venue.venueID) {
        // this user is checked in here
        // show them the textView and an enabled send button
        
        // setup an HPGrowingTextView to hold inputted chat
        self.growingTextView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 3, 240, 40)];
        self.growingTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        self.growingTextView.minNumberOfLines = 1;
        self.growingTextView.maxNumberOfLines = 6;
        self.growingTextView.returnKeyType = UIReturnKeyDefault;
        self.growingTextView.font = [VenueChatCell chatEntryFont];
        self.growingTextView.delegate = self;
        self.growingTextView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        self.growingTextView.backgroundColor = [UIColor whiteColor];
        self.growingTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // setup the white chat box with rounded corners
        UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
        UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
        entryImageView.frame = CGRectMake(5, 0, 248, 40);
        entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // setup a spinner centered on the send button that we will show when sending the chat
        self.sendingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.sendingSpinner.color = [UIColor colorWithRed:(181.0/255.0) green:(107.0/255.0) blue:(0/255.0) alpha:1.0];
        self.sendingSpinner.hidesWhenStopped = YES;
        CGRect spinnerFrame = self.sendingSpinner.frame;
        spinnerFrame.origin.x = self.sendButton.frame.origin.x + (self.sendButton.frame.size.width / 2) - (spinnerFrame.size.width / 2);
        spinnerFrame.origin.y = self.sendButton.frame.origin.y + (self.sendButton.frame.size.height / 2) - (spinnerFrame.size.height / 2);
        self.sendingSpinner.frame = spinnerFrame;
        self.sendingSpinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        [self.chatBox addSubview:self.growingTextView];
        [self.chatBox addSubview:entryImageView];
        
        [self.chatBox addSubview:self.sendingSpinner];
        
    } else {
        // setup a UILabel to tell the user they have to check in to chat here
        UILabel *notifyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 280, 39)];
        notifyLabel.text = @"Please check in to chat here";
        notifyLabel.backgroundColor = [UIColor clearColor];
        notifyLabel.textColor = [UIColor colorWithRed:(196.0/255.0) green:(102.0/255.0) blue:0 alpha:1.0];
        notifyLabel.font = self.sendButton.titleLabel.font;
        notifyLabel.shadowOffset = CGSizeMake(0, -1);
        notifyLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
        
        [self.chatBox addSubview:notifyLabel];
        self.sendButton.enabled = NO;
    }
    
    if (!self.venueChat.hasLoaded) {
        // the chat hasn't loaded so we need to show the blank background
        [self placeBlankSheetOverTableView];
        [SVProgressHUD showWithStatus:@"Loading Venue Chat..."];
    }
    
    if (self.venueChat.hasLoaded) {
        // update with the venueChat
        [self updateTableAndHeaderWithNewVenueChat];
        // force a scroll to the last chat
        [self scrollToLastChat:YES animated:NO];
    } 
    
    // setup a pending timestamp with the VenueChat model
    self.venueChat.pendingTimestamp = [NSDate date];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start calling a timer that reloads chat every VENUE_CHAT_RELOAD_INTERVAL seconds
    [self reloadVenueChat];
    self.chatReloadTimer = [NSTimer scheduledTimerWithTimeInterval:VENUE_CHAT_RELOAD_INTERVAL target:self selector:@selector(reloadVenueChat) userInfo:nil repeats:YES];
}

- (void)viewDidUnload
{
    [self setChatBox:nil];
    [self setGrowingTextView:nil];
    [self setTableView:nil];
    [self setActiveChatters:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.chatReloadTimer) {
        [self.chatReloadTimer invalidate];
        self.chatReloadTimer = nil;
    }   
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)placeBlankSheetOverTableView
{
    // make sure the blankSheet is sitting in front of the tableView
    if (!self.blankSheet) {
        self.blankSheet = [[UIView alloc] initWithFrame:self.tableView.frame];
        self.blankSheet.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.blankSheet];
    }
}

- (void)scrollToLastChat:(BOOL)forced animated:(BOOL)animated
{
    if (self.venueChat.chatEntries.count > 0) { 
        if (forced) {
            NSIndexPath *lastCell = [NSIndexPath indexPathForRow:[self.venueChat.chatEntries count] - 1
                                                       inSection:0];
            [self.tableView scrollToRowAtIndexPath:lastCell
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:animated];
        }        
    }  
}

- (void)updateTableAndHeaderWithNewVenueChat
{
    BOOL forceScroll = NO;
    BOOL animatedScroll = NO;
    
    if (self.tableView.contentOffset.y + self.tableView.frame.size.height == self.tableView.contentSize.height) {
        forceScroll = YES;
        animatedScroll = YES;
    } else if (!self.completedFirstChatLoad) {
        forceScroll = YES;
    }
    
    [self.tableView reloadData];
    [self scrollToLastChat:forceScroll animated:animatedScroll];
    
    // setup the little orange man in the navigation item
    [self updateActiveChattingUserCount];
    
    if (self.venueChat.hasLoaded) {
        if (!self.completedFirstChatLoad) {
            [SVProgressHUD dismiss];
            if (self.venueChat.chatEntries.count > 0) {
                [self.blankSheet removeFromSuperview];
                self.blankSheet = nil;
            } else {
                [self placeBlankSheetOverTableView];
                // zero chat entries so put the bubble to prompt the user to chat
                UIImageView *bubbleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"venue-chat-blank-slate.png"]];
                
                // put the bubble in the right spot
                CGRect bubbleFrame = bubbleImage.frame;
                bubbleFrame.origin.y = self.blankSheet.frame.size.height - bubbleFrame.size.height;
                bubbleImage.frame = bubbleFrame;
                
                // add the bubble to the blank sheet
                [self.blankSheet addSubview:bubbleImage];
            }
            self.completedFirstChatLoad = YES;
        } else if (self.venueChat.chatEntries.count != 0 && self.blankSheet) {
            // slide the blankSheet up and away
            CGRect sheetFrame = self.blankSheet.frame;
            sheetFrame.origin.y = -sheetFrame.size.height;
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.blankSheet.frame = sheetFrame;  
            } completion:^(BOOL finished){
                if (finished) {
                    // kill the blankSheet since we don't need it anymore
                    [self.blankSheet removeFromSuperview];
                    self.blankSheet = nil;
                }
            }];
        }
    }
}

- (void)reloadVenueChat
{    
    [self.venueChat getNewChatEntriesWithCompletion:^(BOOL authenticated, BOOL newEntries){
        if (!authenticated) {
            // this user somehow got here without being logged in
        } else {
            [self updateTableAndHeaderWithNewVenueChat];
        }        
    }];
}

-(void)sendChat
{    
    if (self.growingTextView.text.length > 0) {
        // show the spinner in place of the send button
        [self.sendingSpinner startAnimating];
        self.sendButton.hidden = YES;
        
        __weak VenueChatViewController *chatVC = self;
        
        // send the new chat message
        [CPapi sendVenueChatForVenueWithID:self.venueChat.venueIDString message:self.growingTextView.text lastChatID:self.venueChat.lastChatIDString queue:self.venueChat.chatQueue completion:^(NSDictionary *json, NSError *error) {
            
            // no matter what happens we want to stop the spinner and show the button again
            // also allow the user to click on the text view again
            [self.sendingSpinner stopAnimating];
            self.sendButton.hidden = NO;
            
            NSString *message = nil;
            
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                    [self.venueChat addNewChatEntriesFromDictionary:json completion:^(BOOL newEntries){
                        if (newEntries) {
                            // we better have some new entries here because at the very least we have our new message
                            [chatVC updateTableAndHeaderWithNewVenueChat];
                            
                            // clear the textView now that the chat message has been sent
                            chatVC.growingTextView.text = @"";
                        }
                    }];
                    return;
                } else {
                    // json returned an error
                    // let's present that to the user
                    message = [json objectForKey:@"payload"];
                    
                }
            } else {
                // error in JSON parse (or timeout)
                message = @"There was a problem sending chat.\nPlease try again!";
            }
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Oh No!"
                                  message:message
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }]; 
        
        
    }    
}

-(void) keyboardWillShow:(NSNotification *)notification{
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:YES];
}

-(void) keyboardWillHide:(NSNotification *)notification {
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:NO];
}

- (void)fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:(NSNotification *)notification beingShown:(BOOL)beingShown
{
    // Grab the dimensions of the keyboard
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat keyboardHeight = beingShown ? -keyboardRect.size.height : keyboardRect.size.height;
    
    // Shrink the height of the table view by the # of points that the keyboard
    // will occupy
    CGRect newTableViewRect = self.tableView.frame;
    newTableViewRect.size.height += keyboardHeight;
    
    // Raise the inputs by the # of points that the keyboard will occupy
    CGRect newChatBoxRect = self.chatBox.frame;
    newChatBoxRect.origin.y += keyboardHeight;
    
    CGRect newBlankSheetRect = self.blankSheet.frame;
    newBlankSheetRect.origin.y += keyboardHeight;
    
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.chatBox.frame = newChatBoxRect;
                         self.tableView.frame = newTableViewRect;
                         self.blankSheet.frame = newBlankSheetRect;
                     }
                     completion:nil];
    [self scrollToLastChat:YES animated:NO];
    
    if (beingShown) {
        // if the keyboard is being shown then make sure the growing text field grows to the right height again
        // by calling the text setter with the text that's already in the box
        self.growingTextView.text = self.growingTextView.text;
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{    
    float diff = (growingTextView.frame.size.height - height);
    
    // change the frame of the chatBox and the tableView to accomodate for the textView growing
	CGRect box = self.chatBox.frame;
    CGRect table = self.tableView.frame;
    box.size.height -= diff;
    
    // scroll the tableview to maintain position
    CGPoint currentOffset = self.tableView.contentOffset;
    currentOffset.y -= diff;
    [self.tableView setContentOffset:currentOffset animated:NO];
    
    table.size.height += diff;
    box.origin.y += diff;
	self.chatBox.frame = box;
    self.tableView.frame = table;
}

- (void)updateActiveChattingUserCount
{
    if (self.venueChat.activeChattersDuringInterval > 0) {
        self.activeChatters.hidden = NO;
        self.activeChatters.text = [NSString stringWithFormat:@"%d", self.venueChat.activeChattersDuringInterval];
    } else {
        self.activeChatters.hidden = YES;
    } 
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.venueChat.chatEntries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // The font and size values in here are manually pulled from the VenueChatCell spec.
    // They will need to be changed here too if the cell design is changed
    if ([[self.venueChat.chatEntries objectAtIndex:indexPath.row] isKindOfClass:[VenueChatEntry class]]) {
        
        VenueChatEntry *chatEntry = [self.venueChat.chatEntries objectAtIndex:indexPath.row];
        CGSize labelSize = [chatEntry.text sizeWithFont:[VenueChatCell chatEntryFont] constrainedToSize:CGSizeMake([VenueChatCell chatEntryFrame].size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
        
        // keep a 9 point margin on either side of the label
        labelSize.height += 18;
        
        return labelSize.height > 42 ? labelSize.height : 42;
        
    } else {
        // this is a timestamp cell
        return 22;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.venueChat.chatEntries objectAtIndex:indexPath.row] isKindOfClass:[VenueChatEntry class]]) {
        static NSString *ChatCellIdentifier = @"VenueChatCell";
        
        VenueChatCell *cell = [[VenueChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ChatCellIdentifier];
        if (cell == nil) {
            // crash if this cell is nil
            // something's wrong
        }
        
        VenueChatEntry *entry = [self.venueChat.chatEntries objectAtIndex:indexPath.row];
        User *chatUser = entry.user;
        
        cell.chatEntry.text = entry.text;
        
        // change the cell height if required
        CGRect cellHeightFix = cell.chatEntry.frame;
        CGSize labelSize = [cell.chatEntry.text sizeWithFont:[VenueChatCell chatEntryFont] constrainedToSize:CGSizeMake([VenueChatCell chatEntryFrame].size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
        
        cellHeightFix.size.height = labelSize.height;
        
        cell.chatEntry.frame = cellHeightFix;
        
        // make a request for the profile image
        NSURLRequest *thumbnailRequest = [NSURLRequest requestWithURL:chatUser.urlPhoto];
        UIImageView *thumbnail = [[UIImageView alloc] init];
        
        [thumbnail setImageWithURLRequest:thumbnailRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
            [cell.userThumbnail setBackgroundImage:image forState:UIControlStateNormal];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            // nothing to do here, let's just leave it as the default
        }];
        
        // set the tag of the cell button to be row so we can grab the entry when it is tapped
        cell.userThumbnail.tag = indexPath.row;
        
        // add a target on the user thumbnail so we can pull up the user's profile
        [cell.userThumbnail addTarget:self action:@selector(showUserProfileFromThumbnail:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;

    } else {
        static NSString *TimestampCellIdentifier = @"ChatTimestampCell";
        TimestampCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TimestampCellIdentifier];
        
        if (cell == nil) {
            // crash if the cell is nil
            // something terrible has happened
        }
        cell.contentView.backgroundColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-light@2x.png"]] colorWithAlphaComponent:0.5];  
        cell.contentView.opaque = NO;
        cell.contentView.layer.opaque = NO;
        cell.timestampLabel.text =  [self.venueChat.chatEntries objectAtIndex:indexPath.row];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.growingTextView resignFirstResponder];
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // make sure the user can't edit the growingTextView while chat is being sent
    if ([self.sendingSpinner isAnimating]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)showUserProfileFromThumbnail:(UIButton *)sender
{
    VenueChatEntry *entry = [self.venueChat.chatEntries objectAtIndex:sender.tag];
    
    // grab a UserProfileVC and set its user object to the user for the entry
    UserProfileCheckedInViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    
    userVC.user = entry.user;
    
    // push the userVC onto our UINavigationController's stack
    [self.navigationController pushViewController:userVC animated:YES];
}

@end
