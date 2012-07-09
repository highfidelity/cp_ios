//
//  FeedViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FeedViewController.h"
#import "CPPost.h"
#import "PostUpdateCell.h"
#import "NewPostCell.h"
#import "PostLoveCell.h"
#import "CPCheckinHandler.h"
#import "UserProfileViewController.h"

#define LOWER_BUTTON_LABEL_TAG 5463
#define TIMELINE_ORIGIN_X 50

typedef enum {
    FeedVCStateDefault,
    FeedVCStateReloadingFeed,
    FeedVCStateAddingOrRemovingPendingPost,
    FeedVCStateSentNewPost
} FeedVCState;

@interface FeedViewController () <HPGrowingTextViewDelegate>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, assign) float newEditableCellHeight;
@property (nonatomic, strong) CPPost *pendingPost;
@property (nonatomic, strong) NewPostCell *pendingPostCell;
@property (nonatomic, strong) UIView *keyboardBackground;
@property (nonatomic, strong) UITextView *fakeTextView;
@property (nonatomic, assign) FeedVCState currentState;

@end

@implementation FeedViewController 

@synthesize tableView = _tableView;
@synthesize venue = _venue;
@synthesize newPostAfterLoad = _newPostAfterLoad;
@synthesize posts = _posts;
@synthesize newEditableCellHeight = _newEditableCellHeight;
@synthesize pendingPost = _pendingPost;
@synthesize pendingPostCell = _pendingPostCell;
@synthesize keyboardBackground = _keyboardBackground;
@synthesize fakeTextView = _fakeTextView;
@synthesize currentState = _currentState;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // refresh button in top right
    [self addRefreshButtonToNavigationItem];
    
    // our title is our venue's name
    self.title = self.venue.name;
    
    // setup a background view
    // and add the timeline to the backgroundView
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
    UIView *timeLine = [[UIView alloc] initWithFrame:CGRectMake(TIMELINE_ORIGIN_X, 0, 2, backgroundView.frame.size.height)];
    timeLine.backgroundColor = [UIColor colorWithR:234 G:234 B:234 A:1];
    [backgroundView addSubview:timeLine];
    
    // use that background view as the tableView's background 
    self.tableView.backgroundView = backgroundView;
    
    // we need a footer a the bottom of the tableView so the bottom log entry clears the button
    CGFloat buttonHalf = [CPAppDelegate tabBarController].thinBar.leftButton.frame.size.width / 2;
    UIView *tableFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, buttonHalf)];
    self.tableView.tableFooterView = tableFooter;
    
    // add a hidden UITextView so we can use it to become the first responder
    self.fakeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.fakeTextView.hidden = YES;
    self.fakeTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.fakeTextView.returnKeyType = UIReturnKeyDone;
    [self.view insertSubview:self.fakeTextView belowSubview:self.tableView];
    
    // Add notifications for keyboard showing / hiding
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // create a CGRect for the base of our view
    // we're going to hide things there
    CGRect baseRect = CGRectMake(0, [CPAppDelegate window].bounds.size.height, self.view.frame.size.width, 0);
    
    // add a view so we can have a background behind the keyboard
    self.keyboardBackground = [[UIView alloc] initWithFrame:baseRect];
    self.keyboardBackground.backgroundColor = [UIColor colorWithR:51 G:51 B:51 A:1];

    // add the keyboardBackground to the view
    [[CPAppDelegate window] addSubview:self.keyboardBackground];
    
    // subscribe to the applicationDidBecomeActive notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getUserLogEntries) name:@"applicationDidBecomeActive" object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // remove the two views we added to the window
    [self.keyboardBackground removeFromSuperview];

    // unsubscribe from the applicationDidBecomeActive notification
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"applicationDidBecomeActive"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // dismiss our progress HUD if it's up
    [SVProgressHUD dismiss];
    
    if (self.pendingPost) {
        // if we have a pending post
        // make sure the keyboard isn't up anymore
        [self cancelPost:nil];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self getUserLogEntries];
}

- (NSMutableArray *)posts
{
    if (!_posts) {
        _posts = [NSMutableArray array];
    }
    return _posts;
}

#pragma mark - Table view delegate

#define MIN_CELL_HEIGHT 38
#define UPDATE_LABEL_WIDTH 228
#define LOVE_LABEL_WIDTH 178
#define LOVE_PLUS_ONE_LABEL_WIDTH 178

- (NSString *)textForLogEntry:(CPPost *)logEntry
{
    if (logEntry.type == CPPostTypeUpdate && logEntry.author.userID != [CPUserDefaultsHandler currentUser].userID) {
        return [NSString stringWithFormat:@"%@: %@", logEntry.author.firstName, logEntry.entry];
    } else {
        if (logEntry.type == CPPostTypeLove && logEntry.originalPostID > 0) {
            return [NSString stringWithFormat:@"%@ +1'd recognition: %@", logEntry.author.firstName, logEntry.entry];
        } else {
            return logEntry.entry;
        }
    }
}

- (UIFont *)fontForLogEntry:(CPPost *)logEntry
{
    if (logEntry.type == CPPostTypeUpdate) {
        return [UIFont systemFontOfSize:(logEntry.author.userID == [CPUserDefaultsHandler currentUser].userID ? 13 : 12)];
    } else {
        return [UIFont boldSystemFontOfSize:10];
    }
}

- (CGFloat)widthForLabelForLogEntry:(CPPost *)logEntry
{
    if (logEntry.type == CPPostTypeUpdate) {
        return UPDATE_LABEL_WIDTH;
    } else {
        if (logEntry.originalPostID > 0) {
            return LOVE_PLUS_ONE_LABEL_WIDTH;
        } else {
            return LOVE_LABEL_WIDTH;
        }
    }
}

- (CGFloat)labelHeightWithText:(NSString *)text labelWidth:(CGFloat)labelWidth labelFont:(UIFont *)labelFont
{
    return [text sizeWithFont:labelFont
            constrainedToSize:CGSizeMake(labelWidth, MAXFLOAT) 
                lineBreakMode:UILineBreakModeWordWrap].height;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelHeight;
    if (self.pendingPost && indexPath.row == self.posts.count - 1) {
        // this is an editable cell
        // for which we might have a changed height
        
        // check if we have a new cell height which is larger than our min height and grow to that size
        labelHeight = self.newEditableCellHeight > MIN_CELL_HEIGHT ? self.newEditableCellHeight : MIN_CELL_HEIGHT;
        
        // reset the newEditableCellHeight to 0
        self.newEditableCellHeight = 0;
    } else {
        // we need to check here if we have multiline text
        // grab the entry this is for so we can change the height of the cell accordingly
        CPPost *logEntry = [self.posts objectAtIndex:indexPath.row];
        
        labelHeight = [self labelHeightWithText:[self textForLogEntry:logEntry] labelWidth:[self widthForLabelForLogEntry:logEntry] labelFont:[self fontForLogEntry:logEntry]];
                
        // keep a 17 pt margin
        labelHeight += 17;
        
        // make sure labelHeight isn't smaller than our min cell height
        labelHeight = labelHeight > MIN_CELL_HEIGHT ? labelHeight : MIN_CELL_HEIGHT;
    }
    
    // return the calculated labelHeight
    return labelHeight;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // pull the right log entry from the array
    CPPost *post = [self.posts objectAtIndex:indexPath.row];
    
    PostBaseCell *cell;
    // check if this is a pending entry cell
    if (self.pendingPost && !post.entry) {
        
        static NSString *NewEntryCellIdentifier = @"NewPostCell";
        NewPostCell *newEntryCell = [tableView dequeueReusableCellWithIdentifier:NewEntryCellIdentifier];
        
        newEntryCell.entryLabel.text = @"Update:";
        newEntryCell.entryLabel.textColor = [CPUIHelper CPTealColor];
        
        // NOTE: we're resetting attributes on the HPGrowingTextView here that only need to be set once
        // if the tableView is sluggish it's probably worth laying out the NewLogEntryCell and LogEntryCell
        // programatically so that it's only done once.
        
        // set the required properties on the HPGrowingTextView
        newEntryCell.growingTextView.internalTextView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
        newEntryCell.growingTextView.delegate = self;
        newEntryCell.growingTextView.font = [UIFont systemFontOfSize:12];
        newEntryCell.growingTextView.textColor = [UIColor colorWithR:100 G:100 B:100 A:1];
        newEntryCell.growingTextView.backgroundColor = [UIColor clearColor];
        newEntryCell.growingTextView.minNumberOfLines = 1;
        newEntryCell.growingTextView.maxNumberOfLines = 20;
        newEntryCell.growingTextView.returnKeyType = UIReturnKeyDone;
        newEntryCell.growingTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
        
        // get the cursor to the right place
        // by padding it with leading spaces
        newEntryCell.growingTextView.text = @"               ";
        
        // this is our pending entry cell
        self.pendingPostCell = newEntryCell;
        
        // the cell to be returned is the newEntryCell
        cell = newEntryCell;
        
    } else {        
        // check which type of cell we are dealing with
        if (post.type == CPPostTypeUpdate) {
            
            // this is an update cell
            // so check if it's this user's or somebody else's
            PostUpdateCell *updateCell;
            
            if (post.author.userID == [CPUserDefaultsHandler currentUser].userID){
                static NSString *EntryCellIdentifier = @"MyPostUpdateCell";
                updateCell = [tableView dequeueReusableCellWithIdentifier:EntryCellIdentifier];
                
                // create a singleton NSDateFormatter that we'll keep using
                static NSDateFormatter *logFormatter = nil;
                
                if (!logFormatter) {
                    logFormatter = [[NSDateFormatter alloc] init];
                    [logFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                }
                
                // setup the format for the time label
                logFormatter.dateFormat = @"h:mma";
                updateCell.timeLabel.text = [logFormatter stringFromDate:post.date];
                // replace either AM or PM with lowercase a or p
                updateCell.timeLabel.text = [updateCell.timeLabel.text stringByReplacingOccurrencesOfString:@"AM" withString:@"a"];
                updateCell.timeLabel.text = [updateCell.timeLabel.text stringByReplacingOccurrencesOfString:@"PM" withString:@"p"];        
                
                // setup the format for the date label
                logFormatter.dateFormat = @"MMM d";
                updateCell.dateLabel.text = [logFormatter stringFromDate:post.date];
                
            } else {
                // this is an update from another user
                static NSString *OtherUserEntryCellIdentifier = @"PostUpdateCell";
                updateCell = [tableView dequeueReusableCellWithIdentifier:OtherUserEntryCellIdentifier];        
            }
            
            // the cell to return is the updateCell
            cell = updateCell;
            
        } else {
            // this is a love cell
            static NSString *loveCellIdentifier = @"PostLoveCell";
            PostLoveCell *loveCell = [tableView dequeueReusableCellWithIdentifier:loveCellIdentifier];
            
            // setup the receiver's profile button
            [self loadProfileImageForButton:loveCell.receiverProfileButton photoURL:post.receiver.photoURL buttonTag:indexPath.row];
            
            loveCell.entryLabel.text = post.entry.description;
            
            // if this is a plus one we need to make the label wider
            // or reset it if it's not
            CGRect loveLabelFrame = loveCell.entryLabel.frame;
            loveLabelFrame.size.width = post.originalPostID > 0 ? LOVE_PLUS_ONE_LABEL_WIDTH : LOVE_LABEL_WIDTH;
            loveCell.entryLabel.frame = loveLabelFrame;

            // the cell to return is the loveCell
            cell = loveCell;
        } 
        
        // the text for this entry is prepended with NICKNAME logged:
        cell.entryLabel.text = [self textForLogEntry:post];
        
        // make the frame of the label larger if required for a multi-line entry
        CGRect entryFrame = cell.entryLabel.frame;
        entryFrame.size.height = [self labelHeightWithText:cell.entryLabel.text labelWidth:[self widthForLabelForLogEntry:post] labelFont:[self fontForLogEntry:post]];
        cell.entryLabel.frame = entryFrame;
    }
    
    // setup the entry sender's profile button
    [self loadProfileImageForButton:cell.senderProfileButton photoURL:post.author.photoURL buttonTag:indexPath.row];
    
    // return the cell
    return cell;
}

#pragma mark - VC Helper Methods
- (void)loadProfileImageForButton:(UIButton *)button photoURL:(NSURL *)photoURL buttonTag:(NSInteger)buttonTag
{   
    __block UIButton *profileButton = button;
    
    // call setImageWithURLRequest and use the success block to set the downloaded image as the background image of the button
    // on failure do nothing since the background image on the button has been reset to the default profile image in prepare for reuse
    
    // we use the button's read-only imageView just to be able to peform the request using AFNetworking's caching
    [button.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:photoURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        // give the downloaded image to the button
        [profileButton setBackgroundImage:image forState:UIControlStateNormal];
    } failure:nil];
    
    // the row of this cell is the tag for the button
    // we need to be able to grab the cell later and go to the user's profile
    button.tag = buttonTag;
    
    // be the target of the button
    [button addTarget:self action:@selector(pushToUserProfileFromButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)pushToUserProfileFromButton:(UIButton *)button
{
    // grab the log entry that is associated to this button
    CPPost *userEntry = [self.posts objectAtIndex:button.tag];
    
    // grab a UserProfileViewController from the UserStoryboard
    UserProfileViewController *userProfileVC = (UserProfileViewController *)[[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfileViewController"];
    
    // give the log's user object to the UserProfileVC
    
    // if this button's origin is left of the timeline then it's the log's author
    // otherwise it's the log's receiver
    userProfileVC.user = button.frame.origin.x < TIMELINE_ORIGIN_X ? userEntry.author : userEntry.receiver;
    
    // ask our navigation controller to push to the UserProfileVC
    [self.navigationController pushViewController:userProfileVC animated:YES];
}

- (void)addRefreshButtonToNavigationItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getUserLogEntries)];
}

- (void)toggleLoadingState:(BOOL)loading
{
    if (loading) {
        // our current state is log reload
        self.currentState = FeedVCStateReloadingFeed;
        // show a progress HUD
        [SVProgressHUD showWithStatus:@"Loading..."];
    } else {
        // our current state is now the default
        self.currentState = FeedVCStateDefault;
        
        // dismiss the progress HUD
        [SVProgressHUD dismiss];
    } 
}

- (void)getUserLogEntries
{   
    [self toggleLoadingState:YES];
    // make the request with CPapi to get log entries for this user
    [CPapi getFeedForVenueID:self.venue.venueID withCompletion:^(NSDictionary *json, NSError *error) { 
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                // clear all current log entries
                [self.posts removeAllObjects];
                
                for (NSDictionary *logDict in [json objectForKey:@"payload"]) {
                    // alloc-init a log entry from the dictionary representation
                    CPPost *logEntry = [[CPPost alloc] initFromDictionary:logDict];
                    
                    // add that log entry to our array of log entries
                    // add it at the beginning so the newest entries are first in the array
                    [self.posts addObject:logEntry];
                }
                
                [self toggleLoadingState:NO];
                
                // reload the tableView
                [self.tableView reloadData];
                
                // check if we were loaded because the user immediately wants to add a new entry
                if (self.newPostAfterLoad) {
                    // if that's the case then pull let the user add a new entry
                    [self newPost];
                    // reset the newLogEntryAfterLoad property so it doesn't fire again
                    self.newPostAfterLoad = NO;
                } else {
                    // go to the bottom of the tableView
                    [self scrollTableViewToBottomAnimated:YES];
                }
            }
        }
    }];
}

- (void)sendNewLog
{
    // let's grab the cell that this entry is for
    self.pendingPost.entry = [self.pendingPostCell.growingTextView.text stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
    
    // send a log entry as long as it's not blank
    // and we're not in the process of sending a log entry
    if (![self.pendingPost.entry isEqualToString:@""] && ![self.navigationItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
        
        // create a spinner to use in the top right of the navigation controller
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        [CPapi sendUpdate:self.pendingPost.entry atVenue:self.venue completion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                    self.currentState = FeedVCStateSentNewPost;
                    
                    // if the user chose a venue for the log we need to check them in there
                    // unless it's the same venue that we already have them checked into
                    if (self.venue && ![self.venue.foursquareID isEqualToString:[CPUserDefaultsHandler currentVenue].foursquareID]) {
                        [self checkinUserToVenue:self.venue];
                    }
                    
                    // drop the self.pendingPost to the pending entry now that it's sent
                    CPPost *sentEntry = self.pendingPost;
                    self.pendingPost = nil;
                    
                    // no error, log sent successfully. let's add the completed log object to the array and reload the table
                    sentEntry.date = [NSDate date];
                    [self.tableView reloadData];
                } else {
                    
                }
            }
        }];
    }
}

- (void)scrollTableViewToBottomAnimated:(BOOL)animated
{
    // scroll to the bottom of the tableView
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height) animated:animated];
}

- (void)checkinUserToVenue:(CPVenue *)venue
{
    NSInteger hoursHere = 24;
    [CPapi checkInToLocation:venue hoursHere:hoursHere statusText:nil isVirtual:NO isAutomatic:NO completionBlock:^(NSDictionary *json, NSError *error){
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                // give the venue_id that came back with this request to the venue
                venue.venueID = [[json objectForKey:@"venue_id"] intValue];
                
                // tell the CPCheckinHandler to do what it needs for successful checkin
                NSInteger checkoutTime = [[NSDate dateWithTimeIntervalSinceNow:(60*60*hoursHere)] timeIntervalSince1970];
                [CPCheckinHandler handleSuccessfulCheckinToVenue:venue checkoutTime:checkoutTime checkinType:CPCheckinTypeAuto];
            } else {
                // TODO: handle this error
            }
        } else {
            // TODO: handle error here
            // all of these errors (JSON parse, etc.) should be handled by a single method somewhere
        }
    }];
}

#pragma mark - IBActions
- (void)newPost
{   
    if (self.currentState == FeedVCStateReloadingFeed) {
        // if the log is currently reloading
        // or the view isn't yet visible
        // then don't try to add a newLogEntry right away
        // set our property that will pull up the keyboard after the load is complete
        self.newPostAfterLoad = YES;
        
        // don't continue execution of this method, get out of here
        return;
    }
    
    // only try to add a new log if we aren't in the middle of adding one now
    // or if we aren't reloading the user's logs
    if (!self.pendingPost) {
        // we need to add a new cell to the table with a textView that the user can edit
        // first create a new CPLogEntry object
        self.pendingPost = [[CPPost alloc] init];
        
        // the author for this log message is the current user
        self.pendingPost.author = [CPUserDefaultsHandler currentUser];
        
        [self.posts addObject:self.pendingPost];
        
        // we need the keyboard to know that we're asking for this change
        self.currentState = FeedVCStateAddingOrRemovingPendingPost;
        
        // add a cancel button to our nav bar so the user can drop out of creation
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost:)];
        
        // tell the tableView to stop scrolling, it'll be completed by the keyboard being displayed
        self.tableView.contentOffset = self.tableView.contentOffset;
        
        // only become firstResponder if this view is currently on screen
        // otherwise that gets taken care once the view appears
        if (self.tabBarController.selectedIndex != 0) {
            // let's make sure the selected index of the CPTabBarController is the logbook's
            // before allowing update
            self.tabBarController.selectedIndex = 0;
        } else {
            // show the keyboard so the user can start input
            // by using our fakeTextView to slide up the keyboard
            [self.fakeTextView becomeFirstResponder];
        }
    }
}

- (IBAction)cancelPost:(id)sender {
    // user is cancelling log entry
    
    // remove the pending log entry from our array of entries
    [self.posts removeObject:self.pendingPost];
    
    // we need the keyboard to know that we're asking for this change
    self.currentState = FeedVCStateAddingOrRemovingPendingPost;
    
    // switch first responder to our fake textView and then resign it so we can drop the keyboard
    [self.fakeTextView becomeFirstResponder];
    [self.fakeTextView resignFirstResponder];
}

# pragma mark - Keyboard hide/show notification

- (void)keyboardWillShow:(NSNotification *)notification{
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:NO];
}

- (void)fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:(NSNotification *)notification beingShown:(BOOL)beingShown
{    
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // call our helper method to slide the UI elements
    [self slideUIElementsBasedOnKeyboardHeight:keyboardRect.size.height 
                             animationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] 
                                    beingShown:beingShown];
}

- (void)slideUIElementsBasedOnKeyboardHeight:(CGFloat)keyboardHeight animationDuration:(CGFloat)animationDuration beingShown:(BOOL)beingShown
{
    // NOTE: it's pretty odd to be moving the UITabBar up and down and using it in our view
    // it's convenient though because it gives us the background and the log button
    
    keyboardHeight = beingShown ? keyboardHeight : -keyboardHeight;
    
    // don't move anything if the keyboard isn't being moved because of us
    if (self.currentState != FeedVCStateDefault) {
        
        // create the indexPath for the last row
        int row = self.posts.count - (beingShown ? 1 : 0);
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        NSArray *indexPathArray = [NSArray arrayWithObject:lastIndexPath];
        
        UITabBar *tabBar = [CPAppDelegate tabBarController].tabBar;
        CPThinTabBar *thinBar = [CPAppDelegate tabBarController].thinBar;
        
        // new CGRect for the UITabBar
        CGRect newTabBarFrame = tabBar.frame;
        newTabBarFrame.origin.y -= keyboardHeight;
        
        // setup a new CGRect for the tableView
        CGRect newTableViewFrame = self.tableView.frame;
        newTableViewFrame.size.height -= keyboardHeight;
        
        // new CGRect for keyboardBackground
        CGRect newBackgroundFrame = self.keyboardBackground.frame;
        newBackgroundFrame.origin.y -= keyboardHeight;
        newBackgroundFrame.size.height += keyboardHeight;
    
        
        // only try and update the tableView if we've asked for this change by adding or removing an entry
        if (self.currentState == FeedVCStateAddingOrRemovingPendingPost) {            
            [self.tableView beginUpdates];
            
            // if the keyboard is being shown then we need to add an entry
            if (beingShown) {
                [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
            } else {
                // otherwise  we're removing one
                [self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
                
                // remove our pointer to the previous pendingPost object now that the row is gone
                self.pendingPost = nil;
            }
            [self.tableView endUpdates];
        }
            
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             if (self.currentState == FeedVCStateAddingOrRemovingPendingPost ||
                                 self.currentState == FeedVCStateSentNewPost) {
                                 // give the tabBar its new frame
                                 tabBar.frame = newTabBarFrame;
                                 
                                 // toggle the alpha of the right side buttons and green line
                                 [thinBar toggleRightSide:!beingShown];
                                 
                                 // give the tableView its new Frame
                                 self.tableView.frame = newTableViewFrame;
                                                             
                                 if (beingShown) {
                                     // get the tableView to scroll while the keyboard is appearing
                                     [self scrollTableViewToBottomAnimated:NO];
                                 }
                             }
                             
                             // give the keyboard background its new frame
                             self.keyboardBackground.frame = newBackgroundFrame;                         
                         }
                         completion:^(BOOL finished){
                             if (beingShown) {
                                 // call scrollTableViewToBottomAnimated again because otherwise its off by a couple of points
                                 [self scrollTableViewToBottomAnimated:NO];
                                 
                                 // grab the new cell and make its growingTextView the first responder
                                 if (self.pendingPost) {
                                     [self.pendingPostCell.growingTextView becomeFirstResponder];
                                 }
                             } else {                                     
                                 // remove the cancel button and replace it with the reload button
                                 [self addRefreshButtonToNavigationItem];
                             }
                        
                             // reset the LogVCState
                             self.currentState = FeedVCStateDefault;
                         }];
    }
}

#pragma mark - HPGrowingTextViewDelegate
- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.location < 15) {
        return NO;
    } else {
        if ([text isEqualToString:@"\n"]) {
            // when the user clicks return it's the done button 
            // so send the update
            [self sendNewLog];
            return NO;
        } else {
            return YES;
        }
    }
}

- (void)growingTextViewDidChangeSelection:(HPGrowingTextView *)growingTextView
{
    if (growingTextView.selectedRange.location < 15) {
        // make sure the end point was at least 16
        // if that's the case then allow the selection from 15 to the original end point
        int end = growingTextView.selectedRange.location + growingTextView.selectedRange.length;
        
        growingTextView.selectedRange = NSMakeRange(15, end > 15 ? end - 15 : 0);
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // get the difference in height
    float diff = (growingTextView.frame.size.height - height);
    
    if (diff != 0) {
        // grab the contentView of the cell
        UIView *cellContentView = [growingTextView superview];
        
        // set the newEditableCellHeight property so we can grab it when the tableView asks for the cell height
        self.newEditableCellHeight = cellContentView.frame.size.height - diff;
        
        // call beginUpdates and endUpdates to get the tableView to change the height of the first cell
        [self.tableView beginUpdates];
        if (diff < 0) {
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - diff) animated:YES];
        }
        
        [self.tableView endUpdates];  
    }
}


@end
