//
//  LogViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LogViewController.h"
#import "CPLogEntry.h"
#import "LogUpdateCell.h"
#import "LogNewEntryCell.h"
#import "LogLoveCell.h"
#import "CheckInListTableViewController.h"
#import "CPCheckinHandler.h"

#define LOWER_BUTTON_LABEL_TAG 5463

typedef enum {
    LogVCStateDefault,
    LogVCStateAddingOrRemovingPendingEntry,
    LogVCStateTogglingHiddenTVC,
    LogVCStateSentNewLogEntry    
} LogVCState;

@interface LogViewController () <HPGrowingTextViewDelegate>

@property (nonatomic, strong) NSMutableArray *logEntries;
@property (nonatomic, assign) float newEditableCellHeight;
@property (nonatomic, strong) CPLogEntry *pendingLogEntry;
@property (nonatomic, strong) LogNewEntryCell *pendingLogEntryCell;
@property (nonatomic, strong) UIView *keyboardBackground;
@property (nonatomic, strong) UITextView *fakeTextView;
@property (nonatomic, strong) UIButton *logBarButton;
@property (nonatomic, strong) CheckInListTableViewController *venueListVC;
@property (nonatomic, assign) LogVCState currentState;

@end

@implementation LogViewController 

@synthesize tableView = _tableView;
@synthesize newLogEntryAfterLoad = _newLogEntryAfterLoad;
@synthesize logEntries = _logEntries;
@synthesize newEditableCellHeight = _newEditableCellHeight;
@synthesize pendingLogEntry = _pendingLogEntry;
@synthesize pendingLogEntryCell = _pendingLogEntryCell;
@synthesize keyboardBackground = _keyboardBackground;
@synthesize fakeTextView = _fakeTextView;
@synthesize logBarButton = _lowerButton;
@synthesize venueListVC = _venueListVC;
@synthesize currentState = _currentState;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // refresh button in top right
    [self addRefreshButtonToNavigationItem];
    
    // setup a background view that uses the texture
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
    backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-lightpaperfibers"]];
    
    // add the timeline to the backgroundView
    UIView *timeLine = [[UIView alloc] initWithFrame:CGRectMake(50, 0, 2, backgroundView.frame.size.height)];
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
    
    // grab the venue list view controller
    self.venueListVC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"FoursquareVenuesTVC"];
    
    // be the delegate of that view controller
    self.venueListVC.delegate = self;
    
    // add its view to the window
    self.venueListVC.view.frame = baseRect;
    [[CPAppDelegate window] addSubview:self.venueListVC.view];
    
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
    [self.venueListVC.view removeFromSuperview];
    
    // unsubscribe from the applicationDidBecomeActive notification
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"applicationDidBecomeActive"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // dismiss our progress HUD if it's up
    [SVProgressHUD dismiss];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self getUserLogEntries];
}

- (NSMutableArray *)logEntries
{
    if (!_logEntries) {
        _logEntries = [NSMutableArray array];
    }
    return _logEntries;
}

#pragma mark - Table view delegate

#define MIN_CELL_HEIGHT 38
#define UPDATE_LABEL_WIDTH 228
#define LOVE_LABEL_WIDTH 178
#define LOVE_PLUS_ONE_LABEL_WIDTH 178

- (NSString *)textForLogEntry:(CPLogEntry *)logEntry
{
    if (logEntry.type == CPLogEntryTypeUpdate && logEntry.author.userID != [CPAppDelegate currentUser].userID) {
        return [NSString stringWithFormat:@"%@ logged: %@", logEntry.author.firstName, logEntry.entry];
    } else {
        if (logEntry.type == CPLogEntryTypeLove && logEntry.originalLogID > 0) {
            return [NSString stringWithFormat:@"%@ +1'd recognition: %@", logEntry.author.firstName, logEntry.entry];
        } else {
            return logEntry.entry;
        }
    }
}

- (UIFont *)fontForLogEntry:(CPLogEntry *)logEntry
{
    if (logEntry.type == CPLogEntryTypeUpdate) {
        return [UIFont systemFontOfSize:12];
    } else {
        return [UIFont boldSystemFontOfSize:10];
    }
}

- (CGFloat)widthForLabelForLogEntry:(CPLogEntry *)logEntry
{
    if (logEntry.type == CPLogEntryTypeUpdate) {
        return UPDATE_LABEL_WIDTH;
    } else {
        if (logEntry.originalLogID > 0) {
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
    if (self.pendingLogEntry && indexPath.row == self.logEntries.count - 1) {
        // this is an editable cell
        // for which we might have a changed height
        
        // check if we have a new cell height which is larger than our min height and grow to that size
        labelHeight = self.newEditableCellHeight > MIN_CELL_HEIGHT ? self.newEditableCellHeight : MIN_CELL_HEIGHT;
        
        // reset the newEditableCellHeight to 0
        self.newEditableCellHeight = 0;
    } else {
        // we need to check here if we have multiline text
        // grab the entry this is for so we can change the height of the cell accordingly
        CPLogEntry *logEntry = [self.logEntries objectAtIndex:indexPath.row];
        
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
    return self.logEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // pull the right log entry from the array
    CPLogEntry *logEntry = [self.logEntries objectAtIndex:indexPath.row];
    
    LogBaseEntryCell *cell;
    // check if this is a pending entry cell
    if (self.pendingLogEntry && !logEntry.entry) {
        
        static NSString *NewEntryCellIdentifier = @"NewLogEntryCell";
        LogNewEntryCell *newEntryCell = [tableView dequeueReusableCellWithIdentifier:NewEntryCellIdentifier];
        
        newEntryCell.entryLabel.text = @"Update:";
        newEntryCell.entryLabel.textColor = [CPUIHelper CPTealColor];
        
        // NOTE: we're resetting attributes on the HPGrowingTextView here that only need to be set once
        // if the tableView is sluggish it's probably worth laying out the NewLogEntryCell and LogEntryCell
        // programatically so that it's only done once.
        
        // set the required properties on the HPGrowingTextView
        newEntryCell.logTextView.internalTextView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
        newEntryCell.logTextView.delegate = self;
        newEntryCell.logTextView.font = [UIFont systemFontOfSize:12];
        newEntryCell.logTextView.textColor = [UIColor colorWithR:100 G:100 B:100 A:1];
        newEntryCell.logTextView.backgroundColor = [UIColor clearColor];
        newEntryCell.logTextView.minNumberOfLines = 1;
        newEntryCell.logTextView.maxNumberOfLines = 20;
        newEntryCell.logTextView.returnKeyType = UIReturnKeyDone;
        newEntryCell.logTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
        
        // get the cursor to the right place
        // by padding it with leading spaces
        newEntryCell.logTextView.text = @"               ";
        
        // this is our pending entry cell
        self.pendingLogEntryCell = newEntryCell;
        
        // the cell to be returned is the newEntryCell
        cell = newEntryCell;
        
    } else {        
        // check which type of cell we are dealing with
        if (logEntry.type == CPLogEntryTypeUpdate) {
            
            // this is an update cell
            // so check if it's this user's or somebody else's
            LogUpdateCell *updateCell;
            
            if (logEntry.author.userID == [CPAppDelegate currentUser].userID){
                static NSString *EntryCellIdentifier = @"LogEntryCell";
                updateCell = [tableView dequeueReusableCellWithIdentifier:EntryCellIdentifier];
                
                // create a singleton NSDateFormatter that we'll keep using
                static NSDateFormatter *logFormatter = nil;
                
                if (!logFormatter) {
                    logFormatter = [[NSDateFormatter alloc] init];
                    [logFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                }
                
                // setup the format for the time label
                logFormatter.dateFormat = @"h:mma";
                updateCell.timeLabel.text = [logFormatter stringFromDate:logEntry.date];
                // replace either AM or PM with lowercase a or p
                updateCell.timeLabel.text = [updateCell.timeLabel.text stringByReplacingOccurrencesOfString:@"AM" withString:@"a"];
                updateCell.timeLabel.text = [updateCell.timeLabel.text stringByReplacingOccurrencesOfString:@"PM" withString:@"p"];        
                
                // setup the format for the date label
                logFormatter.dateFormat = @"MMM d";
                updateCell.dateLabel.text = [logFormatter stringFromDate:logEntry.date];
                
            } else {
                // this is an update from another user
                static NSString *OtherUserEntryCellIdentifier = @"LogEntryOtherUserCell";
                updateCell = [tableView dequeueReusableCellWithIdentifier:OtherUserEntryCellIdentifier];        
            }
            
            // the cell to return is the updateCell
            cell = updateCell;
            
        } else {
            // this is a love cell
            static NSString *loveCellIdentifier = @"LogLoveCell";
            LogLoveCell *loveCell = [tableView dequeueReusableCellWithIdentifier:loveCellIdentifier];
            
            // lazy load the receiver's profile image
            [loveCell.receiverProfileImageView setImageWithURL:logEntry.receiver.photoURL placeholderImage:[CPUIHelper defaultProfileImage]];
            
            loveCell.entryLabel.text = logEntry.entry.description;
            
            // if this is a plus one we need to make the label wider
            // or reset it if it's not
            CGRect loveLabelFrame = loveCell.entryLabel.frame;
            loveLabelFrame.size.width = logEntry.originalLogID > 0 ? LOVE_PLUS_ONE_LABEL_WIDTH : LOVE_LABEL_WIDTH;
            loveCell.entryLabel.frame = loveLabelFrame;
            
            // rounded style for receiver's UIImageView
            [self roundedStyleForImageView:loveCell.receiverProfileImageView];

            // the cell to return is the loveCell
            cell = loveCell;
        } 
        
        // the text for this entry is prepended with NICKNAME logged:
        cell.entryLabel.text = [self textForLogEntry:logEntry];
        
        // make the frame of the label larger if required for a multi-line entry
        CGRect entryFrame = cell.entryLabel.frame;
        entryFrame.size.height = [self labelHeightWithText:cell.entryLabel.text labelWidth:[self widthForLabelForLogEntry:logEntry] labelFont:[self fontForLogEntry:logEntry]];
        cell.entryLabel.frame = entryFrame;
    }
    
    // every cell has the log entry author's profile image as the senderProfileImageView
    [cell.senderProfileImageView setImageWithURL:logEntry.author.photoURL placeholderImage:[CPUIHelper defaultProfileImage]];
    [self roundedStyleForImageView:cell.senderProfileImageView];
    
    // return the cell
    return cell;
}

#pragma mark - Delegate methods
- (void)setSelectedVenue:(CPVenue *)selectedVenue
{
    // we're going to hide the hidden TVC so set that as our current state
    self.currentState = LogVCStateTogglingHiddenTVC;
    
    // we should have a pending log entry if we are here
    // if we've recieved a venue then make that the venue for the log entry
    if (self.pendingLogEntry && selectedVenue) {
        // give the selectedVenue to that log entry
        self.pendingLogEntry.venue = selectedVenue;
    }
    
    // grab the HPGrowingTextView for the selectedVenue and make it the first responder
    [[self pendingLogEntryCell].logTextView becomeFirstResponder];
}

#pragma mark - VC Helper Methods
- (void)roundedStyleForImageView:(UIImageView *)imageView
{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
}

- (void)addRefreshButtonToNavigationItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getUserLogEntries)];
}

- (void)getUserLogEntries
{    
    [SVProgressHUD showWithStatus:@"Loading..."];
    // make the request with CPapi to get log entries for this user
    [CPapi getLogEntriesWithCompletion:^(NSDictionary *json, NSError *error) { 
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                // clear all current log entries
                [self.logEntries removeAllObjects];
                
                for (NSDictionary *logDict in [json objectForKey:@"payload"]) {
                    // alloc-init a log entry from the dictionary representation
                    CPLogEntry *logEntry = [[CPLogEntry alloc] initFromDictionary:logDict];
                    
                    // add that log entry to our array of log entries
                    // add it at the beginning so the newest entries are first in the array
                    [self.logEntries addObject:logEntry];
                }
                
                [SVProgressHUD dismiss];
                
                // reload the tableView
                [self.tableView reloadData];
                
                // check if we were loaded because the user immediately wants to add a new entry
                if (self.newLogEntryAfterLoad) {
                    // if that's the case then pull let the user add a new entry
                    [self newLogEntry];
                    // reset the newLogEntryAfterLoad property so it doesn't fire again
                    self.newLogEntryAfterLoad = NO;
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
    self.pendingLogEntry.entry = [self.pendingLogEntryCell.logTextView.text stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
    
    // send a log entry as long as it's not blank
    // and we're not in the process of sending a log entry
    if (![self.pendingLogEntry.entry isEqualToString:@""] && ![self.navigationItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
        
        // create a spinner to use in the top right of the navigation controller
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        [CPapi sendLogUpdate:self.pendingLogEntry.entry atVenue:self.pendingLogEntry.venue completion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                    self.currentState = LogVCStateSentNewLogEntry;
                    
                    // if the user chose a venue for the log we need to check them in there
                    // unless it's the same venue that we already have them checked into
                    if (self.pendingLogEntry.venue && ![self.pendingLogEntry.venue.foursquareID isEqualToString:[CPAppDelegate currentVenue].foursquareID]) {
                        [self checkinUserToVenue:self.pendingLogEntry.venue];
                    }
                    
                    // drop the self.pendingLogEntry to the pending entry now that it's sent
                    CPLogEntry *sentEntry = self.pendingLogEntry;
                    self.pendingLogEntry = nil;
                    
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
                [CPCheckinHandler handleSuccessfulCheckinToVenue:venue checkoutTime:checkoutTime];
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
- (void)newLogEntry
{   
    // only try to add a new log if we aren't in the middle of adding one now
    if (!self.pendingLogEntry) {
        // we need to add a new cell to the table with a textView that the user can edit
        // first create a new CPLogEntry object
        self.pendingLogEntry = [[CPLogEntry alloc] init];
        
        // the author for this log message is the current user
        self.pendingLogEntry.author = [CPAppDelegate currentUser];
        
        // if the user is currently at a venue then use that as the venue for this log
        self.pendingLogEntry.venue = [CPAppDelegate currentVenue];
        
        [self.logEntries addObject:self.pendingLogEntry];
        
        // we need the keyboard to know that we're asking for this change
        self.currentState = LogVCStateAddingOrRemovingPendingEntry;
        
        // add a cancel button to our nav bar so the user can drop out of creation
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelLogEntry:)];
        
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

- (IBAction)cancelLogEntry:(id)sender {
    // user is cancelling log entry
    
    // if the user has hit cancel
    // and our pending log entry cell's textView isn't the first responder
    // then our hidden TVC is showing and we need to hide that first
    if (!self.pendingLogEntryCell.logTextView.isFirstResponder) {
        // this is done by just giving the pendingLogEntry the venue it already has
        [self setSelectedVenue:self.pendingLogEntry.venue];
    }
    
    // remove the pending log entry from our array of entries
    [self.logEntries removeObject:self.pendingLogEntry];
    
    // we need the keyboard to know that we're asking for this change
    self.currentState = LogVCStateAddingOrRemovingPendingEntry;

    // switch first responder to our fake textView and then resign it so we can drop the keyboard
    [self.fakeTextView becomeFirstResponder];
    [self.fakeTextView resignFirstResponder];
}

- (IBAction)showVenueList:(id)sender
{
    // the hidden TVC is being shown or hidden
    self.currentState = LogVCStateTogglingHiddenTVC;
    
    // check if the keyboard is around
    if (self.pendingLogEntryCell.logTextView.isFirstResponder) {
        // we need to have the keyboard drop
        // but we do not want to move everything else down as we normally would, just drop the black backdrop and show the venue list
        
        // tell the HPGrowingTextView to resign first responder
        [self.pendingLogEntryCell.logTextView resignFirstResponder];
    } else {
        // no venue selected, just bring the keyboard back up
        [self setSelectedVenue:nil];
    }
}

- (void)addLogBarButtonIfRequired
{
    if (!self.logBarButton) {
        CPThinTabBar *thinBar = [CPAppDelegate tabBarController].thinBar;
        self.logBarButton = [[UIButton alloc] initWithFrame:CGRectMake(LEFT_AREA_WIDTH + 10, 0, thinBar.frame.size.width - (LEFT_AREA_WIDTH + 10), thinBar.frame.size.height)];
        
        // add a line on the left of the button
        UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.logBarButton.frame.size.height)];
        seperator.backgroundColor = [UIColor colorWithR:148 G:148 B:148 A:0.3];
        [self.logBarButton addSubview:seperator];
        
        // add the small down arrow
        UIImage *downArrow = [UIImage imageNamed:@"expand-arrow-down"];
        UIImageView *smallArrow = [[UIImageView alloc] initWithImage:downArrow];
        smallArrow.center = CGPointMake(20, self.logBarButton.frame.size.height / 2);
        [self.logBarButton addSubview:smallArrow];
        
        // add the label for the chosen venue name
        UILabel *venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, self.logBarButton.frame.size.width - 45, self.logBarButton.frame.size.height)];
        venueLabel.tag = LOWER_BUTTON_LABEL_TAG;
        venueLabel.backgroundColor = [UIColor clearColor];
        venueLabel.textColor = [UIColor colorWithR:224 G:222 B:212 A:1.0];
        venueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
        venueLabel.shadowColor = [UIColor colorWithR:51 G:51 B:51 A:0.40];
        venueLabel.shadowOffset = CGSizeMake(0, -2);
        
        [self.logBarButton addTarget:self action:@selector(showVenueList:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.logBarButton addSubview:venueLabel];
    }
}

# pragma mark - Keyboard hide/show notification

- (void) keyboardWillShow:(NSNotification *)notification{
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:YES];
}

- (void) keyboardWillHide:(NSNotification *)notification {
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:NO];
}

- (void)fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:(NSNotification *)notification beingShown:(BOOL)beingShown
{    
    // NOTE: it's pretty odd to be moving the UITabBar up and down and using it in our view
    // it's convenient though because it gives us the background and the log button
    
    
    // don't move anything if the keyboard isn't being moved because of us
    if (self.currentState != LogVCStateDefault) {
        // Grab the dimensions of the keyboard
        CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardHeight = beingShown ? keyboardRect.size.height : -keyboardRect.size.height;
        
        // create the indexPath for the last row
        int row = self.logEntries.count - (beingShown ? 1 : 0);
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
        
        // new CGRect for the hidden TVC
        CGRect newHiddenTVCViewFrame = self.venueListVC.view.frame;
        newHiddenTVCViewFrame.origin.y -= keyboardHeight;
        newHiddenTVCViewFrame.size.height += keyboardHeight;
        
        if (beingShown) {
            // we want to show the button to choose location
            // so make sure it exists
            [self addLogBarButtonIfRequired];

            // add the selectedVenueButton to the thinBar
            [thinBar addSubview:self.logBarButton];
        }
        
        // update the logBar label with the right text
        ((UILabel *)[self.logBarButton viewWithTag:LOWER_BUTTON_LABEL_TAG]).text = self.pendingLogEntry.venue ? self.pendingLogEntry.venue.name : @"Choose Venue";
        
        // only try and update the tableView if we've asked for this change by adding or removing an entry
        if (self.currentState == LogVCStateAddingOrRemovingPendingEntry) {
            [self.tableView beginUpdates];
            
            // if the keyboard is being shown then we need to add an entry
            if (beingShown) {
                [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
            } else {
                // otherwise  we're removing one
                [self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
                
                // remove our pointer to the previous pendingLogEntry object now that the row is gone
                self.pendingLogEntry = nil;
            }
            [self.tableView endUpdates];
        }
        
        [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             if (self.currentState == LogVCStateAddingOrRemovingPendingEntry ||
                                 self.currentState == LogVCStateSentNewLogEntry) {
                                 // give the tabBar its new frame
                                 tabBar.frame = newTabBarFrame;
                                 
                                 // toggle the alpha of the right side buttons and green line
                                 [thinBar toggleRightSide:!beingShown];
                                 
                                 // give the tableView its new Frame
                                 self.tableView.frame = newTableViewFrame;
                                 
                                 // show the button to allow selection of venue (if required)
                                 self.logBarButton.alpha = beingShown;
                                 
                                 // give the new frame to the hidden TVC
                                 self.venueListVC.view.frame = newHiddenTVCViewFrame;
                                 
                                 if (beingShown) {
                                     // get the tableView to scroll while the keyboard is appearing
                                     [self scrollTableViewToBottomAnimated:NO];
                                 }
                             }
                             
                             // give the keyboard background its new frame
                             self.keyboardBackground.frame = newBackgroundFrame;                         
                         }
                         completion:^(BOOL finished){
                             if (self.currentState != LogVCStateTogglingHiddenTVC) {
                                 if (beingShown) {
                                     // call scrollTableViewToBottomAnimated again because otherwise its off by a couple of points
                                     [self scrollTableViewToBottomAnimated:NO];
                                     // grab the new cell and make its growingTextView the first responder
                                     if (self.pendingLogEntry) {
                                         [[self pendingLogEntryCell].logTextView becomeFirstResponder];
                                     }
                                 } else {
                                     [self.logBarButton removeFromSuperview];
                                     // remove the cancel button and replace it with the reload button
                                     [self addRefreshButtonToNavigationItem];
                                 }
                             }
                             
                             // reset the LogVCState
                             self.currentState = LogVCStateDefault;
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
