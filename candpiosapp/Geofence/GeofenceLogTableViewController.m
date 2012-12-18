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
}

- (NSDateFormatter *)entryDateFormatter
{
    if (!_entryDateFormatter) {
        _entryDateFormatter = [[NSDateFormatter alloc] init];
        _entryDateFormatter.dateFormat = @"MMMM d - h:mma";
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
    
    return cell;
}

#pragma mark - IBActions
- (IBAction)emailLogButtonPressed:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeVC = [[MFMailComposeViewController alloc] init];
        composeVC.mailComposeDelegate = self;
        [composeVC setSubject:@"Geofence Log"];
        [composeVC setMessageBody:@"Hello World!" isHTML:NO];
        [self presentModalViewController:composeVC animated:YES];
    } else {
        
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
