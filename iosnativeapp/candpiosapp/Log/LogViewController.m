//
//  LogViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogViewController.h"
#import "CPLogEntry.h"
#import "LogEntryCell.h"
#import "LogEntryOtherUserCell.h"
#import "NewLogEntryCell.h"
#import "CheckInListTableViewController.h"

#define LOWER_BUTTON_LABEL_TAG 5463

@interface LogViewController () <HPGrowingTextViewDelegate>

@property (nonatomic, strong) NSMutableArray *logEntries;
@property (nonatomic, assign) float newEditableCellHeight;
@property (nonatomic, strong) CPLogEntry *pendingLogEntry;
@property (nonatomic, strong) UIView *keyboardBackground;
@property (nonatomic, strong) UITextView *fakeTextView;
@property (nonatomic, strong) UIButton *lowerButton;
@property (nonatomic, assign) BOOL pendingEntryRemovedOrAdded;
@property (nonatomic, strong) CheckInListTableViewController *venueListVC;
@property (nonatomic, assign) BOOL showingOrHidingHiddenTVC;

@end

@implementation LogViewController 

@synthesize tableView = _tableView;
@synthesize logEntries = _logEntries;
@synthesize newEditableCellHeight = _newEditableCellHeight;
@synthesize pendingLogEntry = _pendingLogEntry;
@synthesize keyboardBackground = _keyboardBackground;
@synthesize fakeTextView = _fakeTextView;
@synthesize lowerButton = _lowerButton;
@synthesize pendingEntryRemovedOrAdded = _pendingEntryRemovedOrAdded;
@synthesize venueListVC = _venueListVC;
@synthesize showingOrHidingHiddenTVC = _showingOrHidingHiddenTVC;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // the left button on the CPTabBarController has no current target
    // we need to be the target of that button
    [[CPAppDelegate tabBarController].thinBar.leftButton addTarget:self action:@selector(addLogButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
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
    
    // add a hidden UITextView so we can use it to become the first responder
    self.fakeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.fakeTextView.hidden = YES;
    self.fakeTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.fakeTextView.returnKeyType = UIReturnKeyDone;
    [tableFooter addSubview:self.fakeTextView];
    
    self.tableView.tableFooterView = tableFooter;
    
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // remove the two views we added to the window
    [self.keyboardBackground removeFromSuperview];
    [self.venueListVC.view removeFromSuperview];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
    
    if (!self.pendingLogEntry) {
        [self getUserLogEntries];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.pendingLogEntry) {
        // if we have a pending log entry then show the keyboard
        [self.fakeTextView becomeFirstResponder];
    }
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
#define MY_ENTRY_LABEL_WIDTH 234
#define THEIR_ENTRY_LABEL_WIDTH 201

- (NSString *)textForLogEntry:(CPLogEntry *)logEntry
{
    if (logEntry.author.userID == [CPAppDelegate currentUser].userID) {
        return logEntry.entry;
    } else {
        return [NSString stringWithFormat:@"%@ logged: %@", logEntry.author.nickname, logEntry.entry];
    }
}

- (CGFloat)labelHeightWithText:(NSString *)text labelWidth:(CGFloat)labelWidth
{
    return [text sizeWithFont:[UIFont systemFontOfSize:12] 
            constrainedToSize:CGSizeMake(labelWidth, MAXFLOAT) 
                lineBreakMode:UILineBreakModeWordWrap].height;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelHeight;
    
    if (indexPath.row == self.logEntries.count - 1) {
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
        
        CGFloat labelWidth = logEntry.author.userID == [CPAppDelegate currentUser].userID ? MY_ENTRY_LABEL_WIDTH : THEIR_ENTRY_LABEL_WIDTH;
        labelHeight = [self labelHeightWithText:[self textForLogEntry:logEntry] labelWidth:labelWidth];
                
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
    NSLog(@"Returning %d rows", self.logEntries.count);
    // Return the number of rows in the section.
    return self.logEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Trying to get cell at row %d", indexPath.row);
    // pull the right log entry from the array
    CPLogEntry *logEntry = [self.logEntries objectAtIndex:indexPath.row];
    
    LogEntryCell *cell;
    // for our current implementation an empty entry means this is a fresh entry the user is adding
    if (!logEntry.entry) {
        
        static NSString *NewEntryCellIdentifier = @"NewLogEntryCell";
        NewLogEntryCell *newEntryCell = [tableView dequeueReusableCellWithIdentifier:NewEntryCellIdentifier];
        
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
        
        // the cell to be returned is the newEntryCell
        cell = newEntryCell;
        
    } else {
        CGFloat labelWidth;
        if (logEntry.author.userID == [CPAppDelegate currentUser].userID){
            static NSString *EntryCellIdentifier = @"LogEntryCell";
            cell = [tableView dequeueReusableCellWithIdentifier:EntryCellIdentifier];
            
            // create a singleton NSDateFormatter that we'll keep using
            static NSDateFormatter *logFormatter = nil;
            
            if (!logFormatter) {
                logFormatter = [[NSDateFormatter alloc] init];
                [logFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            }
            
            // setup the format for the time label
            logFormatter.dateFormat = @"h:mma";
            cell.timeLabel.text = [logFormatter stringFromDate:logEntry.date];
            // replace either AM or PM with lowercase a or p
            cell.timeLabel.text = [cell.timeLabel.text stringByReplacingOccurrencesOfString:@"AM" withString:@"a"];
            cell.timeLabel.text = [cell.timeLabel.text stringByReplacingOccurrencesOfString:@"PM" withString:@"p"];        
            
            // setup the format for the date label
            logFormatter.dateFormat = @"MMM d";
            cell.dateLabel.text = [logFormatter stringFromDate:logEntry.date];
            
            labelWidth = MY_ENTRY_LABEL_WIDTH;
        } else {
            // this is an update from another user
            static NSString *OtherUserEntryCellIdentifier = @"LogEntryOtherUserCell";
            cell = [tableView dequeueReusableCellWithIdentifier:OtherUserEntryCellIdentifier];
            
            // set the profile image for this log entry
            [((LogEntryOtherUserCell *)cell).profileImageView setImageWithURL:logEntry.author.photoURL placeholderImage:[CPUIHelper defaultProfileImage]];            
            
            labelWidth = THEIR_ENTRY_LABEL_WIDTH;
        }
        
        // the text for this entry is prepended with NICKNAME logged:
        cell.entryLabel.text = [self textForLogEntry:logEntry];
        
        // make the frame of the label larger if required for a multi-line entry
        CGRect entryFrame = cell.entryLabel.frame;
        entryFrame.size.height = [self labelHeightWithText:cell.entryLabel.text labelWidth:labelWidth];
        cell.entryLabel.frame = entryFrame;
    }
    
    // return the cell
    return cell;
}

#pragma mark - Delegate methods
- (void)setSelectedVenue:(CPVenue *)selectedVenue
{
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
- (void)addRefreshButtonToNavigationItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getUserLogEntries)];
}

- (NewLogEntryCell *)pendingLogEntryCell
{
    if (self.pendingLogEntry) {
        NSLog(@"Pending Log Entry Cell row is %d", self.logEntries.count - 1);
        return (NewLogEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(self.logEntries.count - 1) inSection:0]];
    } else {
        return nil;
    }
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
                
                // go to the bottom of the tableView
                [self scrollTableViewToBottomAnimated:YES];
            }
        }
    }];
}

- (void)sendNewLog
{
    // let's grab the cell that this entry is for
    NewLogEntryCell *newEntryCell = (NewLogEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.logEntries.count - 1 inSection:0]];
    self.pendingLogEntry.entry = [newEntryCell.logTextView.text stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
    
    // send a log entry as long as it's not blank
    if (![self.pendingLogEntry.entry isEqualToString:@""]) {
        [CPapi sendLogUpdate:self.pendingLogEntry.entry atVenue:self.pendingLogEntry.venue completion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                    
                    // drop the self.pendingLogEntry to the pending entry now that it's sent
                    CPLogEntry *sentEntry = self.pendingLogEntry;
                    self.pendingLogEntry = nil;
                    
                    // no error, log sent sucessfully. let's add the completed log object to the array and reload the table
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

#pragma mark - IBActions
- (IBAction)addLogButtonPressed:(id)sender
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
        self.pendingEntryRemovedOrAdded = YES;
        
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
    
    // remove the cancel button and replace it with the reload button
    [self addRefreshButtonToNavigationItem];
    
    // remove the pending log entry from our array of entries
    [self.logEntries removeObject:self.pendingLogEntry];
    // we need the keyboard to know that we're asking for this change
    self.pendingEntryRemovedOrAdded = YES;

    // switch first responder to our fake textView and then resign it so we can drop the keyboard
    [self.fakeTextView becomeFirstResponder];
    [self.fakeTextView resignFirstResponder];
}

- (IBAction)showVenueList:(id)sender
{
    // check if the keyboard is around
    if ([self pendingLogEntryCell].logTextView.isFirstResponder) {
        // we need to have the keyboard drop
        // but we do not want to move everything else down as we normally would, just drop the black backdrop and show the venue list
        self.showingOrHidingHiddenTVC = YES;
        
        // tell the HPGrowingTextView to resign first responder
        [((NewLogEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.logEntries.count - 1 inSection:0]]).logTextView resignFirstResponder];
    } else {
        // no venue selected, just bring the keyboard back up
        [self setSelectedVenue:nil];
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
    
    CGRect newHiddenTVCViewFrame = self.venueListVC.view.frame;
    
    if (self.showingOrHidingHiddenTVC) {        
        // we are showing our hidden TVC
        // so get a new frame ready to put it in the right spot
                
        newHiddenTVCViewFrame.origin.y += keyboardHeight;
        newHiddenTVCViewFrame.size.height -= keyboardHeight;
        
        if (!beingShown) {
            // give the new frame to the venueListVC right away so its waiting when the keyboard drops
            self.venueListVC.view.frame = newHiddenTVCViewFrame;
        }        
    } else if (beingShown) {
        // we want to show the button to choose location
        // so make sure it exists
        if (!self.lowerButton) {
            self.lowerButton = [[UIButton alloc] initWithFrame:CGRectMake(LEFT_AREA_WIDTH + 10, 0, thinBar.frame.size.width - (LEFT_AREA_WIDTH + 10), thinBar.frame.size.height)];
            
            // add a line on the left of the button
            UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.lowerButton.frame.size.height)];
            seperator.backgroundColor = [UIColor colorWithR:148 G:148 B:148 A:0.3];
            [self.lowerButton addSubview:seperator];
            
            // add the small down arrow
            UIImage *downArrow = [UIImage imageNamed:@"expand-arrow-down"];
            UIImageView *smallArrow = [[UIImageView alloc] initWithImage:downArrow];
            smallArrow.center = CGPointMake(20, self.lowerButton.frame.size.height / 2);
            [self.lowerButton addSubview:smallArrow];
            
            // add the label for the chosen venue name
            UILabel *venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.lowerButton.frame.size.width - 45, self.lowerButton.frame.size.height)];
            venueLabel.tag = LOWER_BUTTON_LABEL_TAG;
            venueLabel.backgroundColor = [UIColor clearColor];
            venueLabel.textColor = [UIColor colorWithR:224 G:222 B:212 A:1.0];
            venueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
            venueLabel.shadowColor = [UIColor colorWithR:51 G:51 B:51 A:0.40];
            venueLabel.shadowOffset = CGSizeMake(0, -2);
            venueLabel.text = self.pendingLogEntry.venue ? self.pendingLogEntry.venue.name : @"Choose Venue";
            
            [self.lowerButton addTarget:self action:@selector(showVenueList:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.lowerButton addSubview:venueLabel];
        }
        // add the selectedVenueButton to the thinBar
        [thinBar addSubview:self.lowerButton];
    }
    
    // update the logBar label with the right text
    ((UILabel *)[self.lowerButton viewWithTag:LOWER_BUTTON_LABEL_TAG]).text = self.pendingLogEntry.venue ? self.pendingLogEntry.venue.name : @"Choose Venue";
    
    // only try and update the tableView if we've asked for this change by adding or removing an entry
    if (self.pendingEntryRemovedOrAdded) {
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
        
        // reset the boolean so if something else moves the keyboard the tableView doesn't freak out
        self.pendingEntryRemovedOrAdded = NO;
    }
    
    
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         if (!self.showingOrHidingHiddenTVC) {
                             // give the tabBar its new frame
                             tabBar.frame = newTabBarFrame;
                             
                             // toggle the alpha of the right side buttons and green line
                             [thinBar toggleRightSide:!beingShown];
                             
                             // give the tableView its new Frame
                             self.tableView.frame = newTableViewFrame;
                             
                             // show the button to allow selection of venue (if required)
                             self.lowerButton.alpha = beingShown;
                             
                             if (beingShown) {
                                 // get the tableView to scroll while the keyboard is appearing
                                 [self scrollTableViewToBottomAnimated:NO];
                             }
                         }
                                                  
                         // give the keyboard background its new frame
                         self.keyboardBackground.frame = newBackgroundFrame;                         
                     }
                     completion:^(BOOL finished){
                         if (self.showingOrHidingHiddenTVC) {
                             
                             // if we're being shown again the process with the hidden TVC is complete
                             // so reset the boolean
                             if (beingShown) {
                                 // now that the keyboard is up push the hidden TVC to the bottom again
                                 self.venueListVC.view.frame = newHiddenTVCViewFrame;
                                 self.showingOrHidingHiddenTVC = NO;
                             }
                         } else if (beingShown) {
                             // call scrollTableViewToBottomAnimated again because otherwise its off by a couple of points
                             [self scrollTableViewToBottomAnimated:NO];
                             // grab the new cell and make its growingTextView the first responder
                             if (self.pendingLogEntry) {
                                 [[self pendingLogEntryCell].logTextView becomeFirstResponder];
                             }
                         } else {
                             [self.lowerButton removeFromSuperview];
                         }
                     }];
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


@end
