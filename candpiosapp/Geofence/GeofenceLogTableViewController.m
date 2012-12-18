//
//  GeofenceLogTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 12/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "GeofenceLogTableViewController.h"
#import "GeofenceLogEntryCell.h"

@interface GeofenceLogTableViewController ()

@property (strong, nonatomic) NSArray *logEntries;

@end

@implementation GeofenceLogTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.logEntries = [CPUserDefaultsHandler geofenceRequestLog];
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
    
    return cell;
}

@end
