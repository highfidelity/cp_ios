//
//  GeofenceLogTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 12/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "GeofenceLogTableViewController.h"
#import "GeofenceLogEntryCell.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface GeofenceLogTableViewController () <MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) NSArray *logEntries;
@property (strong, nonatomic) NSDateFormatter *entryDateFormatter;

@end

@implementation GeofenceLogTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.logEntries = [CPUserDefaultsHandler geofenceRequestLog];
    
    if (![MFMailComposeViewController canSendMail] || self.logEntries.count == 0) {
        // hide the email button
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (NSDateFormatter *)entryDateFormatter
{
    if (!_entryDateFormatter) {
        _entryDateFormatter = [[NSDateFormatter alloc] init];
        _entryDateFormatter.dateFormat = @"MMMM d - h:mm:ss a";
    }
    
    return _entryDateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.logEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GeofenceLogEntryCell";
    GeofenceLogEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *logEntryDict = [self.logEntries objectAtIndex:indexPath.row];
    
    cell.venueNameLabel.text = logEntryDict[@"venueName"];
    cell.entryDateLabel.text = [self.entryDateFormatter stringFromDate:logEntryDict[@"date"]];
    
    NSString *imageName = [logEntryDict[@"type"] isEqualToString:@"checkIn"] ? @"check-in-for-list" : @"check-out-for-list";
    cell.iconImageView.image = [UIImage imageNamed:imageName];
    
    return cell;
}

#pragma mark - IBActions
- (IBAction)emailLogButtonPressed:(id)sender
{
    MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
    composeVC.mailComposeDelegate = self;
    [composeVC setSubject:[NSString stringWithFormat:@"Geofence log for %@ (%@)",
                           [CPUserDefaultsHandler currentUser].nickname,
                           [CPUserDefaultsHandler currentUser].userID]];
    
    NSMutableString *emailBody = [NSMutableString stringWithString:@""];
    
    for (NSDictionary *logEntryDict in self.logEntries) {
        [emailBody appendString:[NSString stringWithFormat:@"%@, %@, %@, %@, %@\n",
                                logEntryDict[@"venueID"],
                                logEntryDict[@"lat"],
                                logEntryDict[@"lng"],
                                [self.entryDateFormatter stringFromDate:logEntryDict[@"date"]],
                                logEntryDict[@"type"]]];
    }
    
    [composeVC setMessageBody:emailBody isHTML:NO];
    [composeVC setToRecipients:@[@"support@coffeeandpower.com"]];
    [self presentModalViewController:composeVC animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
