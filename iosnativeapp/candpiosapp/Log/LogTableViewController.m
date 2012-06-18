//
//  LogTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogTableViewController.h"
#import "CPLogEntry.h"
#import "LogEntryCell.h"
#import "NewLogEntryCell.h"

@interface LogTableViewController () <HPGrowingTextViewDelegate>

@property (nonatomic, strong) NSMutableArray *logEntries;
@property (nonatomic, assign) float newEditableCellHeight;
@property (nonatomic, strong) CPLogEntry *pendingLogEntry;
@property (nonatomic, strong) UIView *keyboardBackground;
@property (nonatomic, strong) UITextView *fakeTextView;

@end

@implementation LogTableViewController 

@synthesize logEntries = _logEntries;
@synthesize newEditableCellHeight = _newEditableCellHeight;
@synthesize pendingLogEntry = _pendingLogEntry;
@synthesize keyboardBackground = _keyboardBackground;
@synthesize fakeTextView = _fakeTextView;

#pragma mark - Initializer

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // the left button on the CPTabBarController has no current target
    // we need to be the target of that button
    [[CPAppDelegate tabBarController].thinBar.leftButton addTarget:self action:@selector(addLogButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // use the lightpaperfibers texture as the background pattern image
    
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
    
    // add a view so we can have a background behind the keyboard
    self.keyboardBackground = [[UIView alloc] initWithFrame:CGRectMake(0, [CPAppDelegate window].frame.size.height, [CPAppDelegate window].frame.size.height, 0)];
    self.keyboardBackground.backgroundColor = [UIColor colorWithR:51 G:51 B:51 A:1];

    // add the keyboardBackground to the view
    [[CPAppDelegate window] addSubview:self.keyboardBackground];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (CGFloat)labelHeightWithText:(NSString *)text
{
    return [text sizeWithFont:[UIFont systemFontOfSize:12] 
            constrainedToSize:CGSizeMake(234, MAXFLOAT) 
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
        
        labelHeight = [self labelHeightWithText:logEntry.entry];
                
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
        static NSString *EntryCellIdentifier = @"LogEntryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:EntryCellIdentifier];
        
        // make the frame of the label larger if required for a multi-line entry
        CGRect entryFrame = cell.entryLabel.frame;
        entryFrame.size.height = [self labelHeightWithText:logEntry.entry];
        cell.entryLabel.frame = entryFrame;
        
        cell.entryLabel.text = logEntry.entry; 

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
    }
    
    // return the cell
    return cell;
}

#pragma mark - VC Helper Methods

- (void)getUserLogEntries
{
    [self showCorrectLoadingSpinnerForCount:self.logEntries.count];
    
    // make the request with CPapi to get log entries for this user
    [CPapi getLogEntriesWithCompletion:^(NSDictionary *json, NSError *error) { 
        [self stopAppropriateLoadingSpinner];
        
        // clear all current log entries
        [self.logEntries removeAllObjects];
        
        for (NSDictionary *logDict in [json objectForKey:@"payload"]) {
            // alloc-init a log entry from the dictionary representation
            CPLogEntry *logEntry = [[CPLogEntry alloc] initFromDictionary:logDict];
            
            // add that log entry to our array of log entries
            // add it at the beginning so the newest entries are first in the array
            [self.logEntries addObject:logEntry];
        }
        
        // reload the tableView
        [self.tableView reloadData];
        
        // go to the bottom of the tableView
        [self scrollTableViewToBottomAnimated:YES];
    }];
}

- (void)sendNewLog
{
    // let's grab the cell that this entry is for
    NewLogEntryCell *newEntryCell = (NewLogEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.logEntries.count - 1 inSection:0]];
    self.pendingLogEntry.entry = [newEntryCell.logTextView.text stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
    
    // send a log entry as long as it's not blank
    if (![self.pendingLogEntry.entry isEqualToString:@""]) {
        [CPapi sendLogUpdate:self.pendingLogEntry.entry completion:^(NSDictionary *json, NSError *error) {
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

#pragma mark - IBActions
- (IBAction)addLogButtonPressed:(id)sender
{
    if (self.tabBarController.selectedIndex != 0) {
        // let's make sure the selected index of the CPTabBarController is the logbook's
        // before allowing update
        self.tabBarController.selectedIndex = 0;
    } else {
        // we need to add a new cell to the table with a textView that the user can edit
        // first create a new CPLogEntry object
        self.pendingLogEntry = [[CPLogEntry alloc] init];
        
        [self.logEntries addObject:self.pendingLogEntry];
        
        // add a cancel button to our nav bar so the user can drop out of creation
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelLogEntry:)];
        
        // show the keyboard so the user can start input
        // by using our fakeTextView to slide up the keyboard
        [self.fakeTextView becomeFirstResponder];
    }
}

- (IBAction)cancelLogEntry:(id)sender {
    // user is cancelling log entry
    
    // remove the cancel button
    [self placeSpinnerOnRightBarButtonItem];
    
    // remove the pending log entry from our array of entries
    [self.logEntries removeObject:self.pendingLogEntry];

    // switch first responder to our fake textView and then resign it so we can drop the keyboard
    [self.fakeTextView becomeFirstResponder];
    [self.fakeTextView resignFirstResponder];
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
    // Grab the dimensions of the keyboard
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = beingShown ? keyboardRect.size.height : -keyboardRect.size.height;
    
    // create the indexPath for the last row
    int row = self.logEntries.count - (beingShown ? 1 : 0);
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    NSArray *indexPathArray = [NSArray arrayWithObject:lastIndexPath];
    
    CPThinTabBar *thinBar = [CPAppDelegate tabBarController].thinBar;
    
    // new CGRect for the CPThinTabBar
    CGRect newThinBarFrame = thinBar.frame;
    newThinBarFrame.origin.y -= keyboardHeight;
    
    // setup a new CGRect for the tableView
    CGRect newTableViewFrame = self.tableView.frame;
    newTableViewFrame.size.height -= keyboardHeight;
    
    // new CGRect for keyboardBackground
    CGRect newBackgroundFrame = self.keyboardBackground.frame;
    newBackgroundFrame.origin.y -= keyboardHeight;
    newBackgroundFrame.size.height += keyboardHeight;
    
    [self.tableView beginUpdates];
    if (beingShown) {
        [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
    } else if (self.pendingLogEntry) {
        [self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    
    [UIView animateWithDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         // give the thinBar its new frame
                         thinBar.frame = newThinBarFrame;
                         
                         // toggle the alpha of the right side buttons and green line
                         [thinBar toggleRightSide:!beingShown];
                         
                         // give the tableView its new Frame
                         self.tableView.frame = newTableViewFrame;
                         
                         // give the keyboard background its new frame
                         self.keyboardBackground.frame = newBackgroundFrame;
                         
                         if (beingShown) {
                             // get the tableView to scroll while the keyboard is appearing
                             [self scrollTableViewToBottomAnimated:NO];
                         }
                     }
                     completion:^(BOOL finished){
                         if (beingShown) {
                             // call scrollTableViewToBottomAnimated again because otherwise its off by a couple of points
                             [self scrollTableViewToBottomAnimated:NO];
                             // grab the new cell and make its growingTextView the first responder
                             [((NewLogEntryCell *)[self.tableView cellForRowAtIndexPath:lastIndexPath]).logTextView becomeFirstResponder];
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
