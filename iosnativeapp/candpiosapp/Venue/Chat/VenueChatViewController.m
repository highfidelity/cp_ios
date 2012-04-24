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

    // setup the box that will hold the chat input
    self.chatBox = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 39, [[UIScreen mainScreen] bounds].size.width, 39)];
    
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
    
    // setup a spinner centered on the send button that we will show when sending the chat
    self.sendingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.sendingSpinner.color = [UIColor colorWithRed:(181.0/255.0) green:(107.0/255.0) blue:(0/255.0) alpha:1.0];
    self.sendingSpinner.hidesWhenStopped = YES;
    CGRect spinnerFrame = self.sendingSpinner.frame;
    spinnerFrame.origin.x = self.sendButton.frame.origin.x + (self.sendButton.frame.size.width / 2) - (spinnerFrame.size.width / 2);
    spinnerFrame.origin.y = (self.chatBox.frame.size.height / 2) - (spinnerFrame.size.height / 2);
    self.sendingSpinner.frame = spinnerFrame;
    
    // resizing for chatBox
    self.chatBox.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    // setup the view hierarchy of the chatBox
    [self.view addSubview:self.chatBox];
    [self.chatBox addSubview:imageView];
    [self.chatBox addSubview:self.growingTextView];
    [self.chatBox addSubview:entryImageView];
    [self.chatBox addSubview:self.sendButton];
    [self.chatBox addSubview:self.sendingSpinner];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateTableAndHeaderWithNewVenueChat];
    
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

- (void)scrollToLastChat
{
    if (self.venueChat.chatEntries.count > 0) {
        NSIndexPath *lastCell = [NSIndexPath indexPathForRow:[self.venueChat.chatEntries count] - 1
                                                   inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastCell
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];
    }  
}

- (void)updateTableAndHeaderWithNewVenueChat
{
    [self.tableView reloadData];
    [self scrollToLastChat];
    
    // setup the little orange man in the navigation item
    [self updateActiveChattingUserCount];
}

- (void)reloadVenueChat
{    
    [self.venueChat getNewChatEntriesWithCompletion:^(BOOL authenticated, BOOL newEntries){
        if (!authenticated) {
            
        } else {
            [self updateTableAndHeaderWithNewVenueChat];
        }        
    }];
}

-(void)sendChat
{
	// kill the keyboard
    [self.growingTextView resignFirstResponder];
    
    if (self.growingTextView.text.length > 0) {
        // show the spinner in place of the send button
        [self.sendingSpinner startAnimating];
        self.sendButton.hidden = YES;
        
        // don't let the user click on the text field until we've gotten a response back about this entry
        self.growingTextView.userInteractionEnabled = NO;
        
        __weak VenueChatViewController *chatVC = self;
        
        // send the new chat message
        [CPapi sendVenueChatForVenueWithID:self.venueChat.venueIDString message:self.growingTextView.text lastChatID:self.venueChat.lastChatIDString completion:^(NSDictionary *json, NSError *error) {
            
            // no matter what happens we want to stop the spinner and show the button again
            // also allow the user to click on the text view again
            [self.sendingSpinner stopAnimating];
            self.sendButton.hidden = NO;
            self.growingTextView.userInteractionEnabled = YES;
            
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
                } else {
                    // json returned an error
                    // let's present that to the user
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:@"Oh No!"
                                          message:[json objectForKey:@"payload"]
                                          delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                    [alert show];
                }
            } else {
                // error in JSON parse
            }
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
    newTableViewRect.size.height = newTableViewRect.size.height + keyboardHeight;
    
    // Raise the inputs by the # of points that the keyboard will occupy
    CGRect newChatBoxRect = self.chatBox.frame;
    newChatBoxRect.origin.y = newChatBoxRect.origin.y + keyboardHeight;
    
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.chatBox.frame = newChatBoxRect;
                         self.tableView.frame = newTableViewRect;
                     }
                     completion:nil];
    [self scrollToLastChat];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{    
    float diff = (growingTextView.frame.size.height - height);
    
    // change the frame of the chatBox and the tableView to accomodate for the textView growing
	CGRect box = self.chatBox.frame;
    CGRect table = self.tableView.frame;
    box.size.height -= diff;
    
    table.size.height += diff;
    box.origin.y += diff;
	self.chatBox.frame = box;
    self.tableView.frame = table;
    
    // scroll the tableview to maintain position
    CGPoint currentOffset = self.tableView.contentOffset;
    currentOffset.y -= diff;
    [self.tableView setContentOffset:currentOffset animated:NO];
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
    
    VenueChatEntry *chatEntry = [self.venueChat.chatEntries objectAtIndex:indexPath.row];
    CGSize labelSize = [chatEntry.text sizeWithFont:[VenueChatCell chatEntryFont] constrainedToSize:CGSizeMake([VenueChatCell chatEntryFrame].size.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    
    // keep a 9 point margin on either side of the label
    labelSize.height += 18;
    
    return labelSize.height > 42 ? labelSize.height : 42;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VenueChatCell";
    
    VenueChatCell *cell = [[VenueChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
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
    
    
    return cell;
}


@end
