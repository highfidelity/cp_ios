//
//  InviteLinkedInConnectionsTableViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "InviteLinkedInConnectionsTableViewController.h"

@interface InviteLinkedInConnectionsTableViewController ()

@end

@implementation InviteLinkedInConnectionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LinkedInConnectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
