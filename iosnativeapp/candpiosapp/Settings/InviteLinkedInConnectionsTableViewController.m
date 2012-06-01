//
//  InviteLinkedInConnectionsTableViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "InviteLinkedInConnectionsTableViewController.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "CPLinkedInAPI.h"
#import "ContactListCell.h"

@interface InviteLinkedInConnectionsTableViewController () {
    NSArray *_connections;
}

@property (nonatomic, strong) NSArray *connections;

- (void)loadLinkedInConnections;

@end

@implementation InviteLinkedInConnectionsTableViewController

@synthesize connections = _connections;

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadLinkedInConnections];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.connections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *connectionData = [self.connections objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"LinkedInConnectionCell";
    ContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.nicknameLabel.text = [connectionData objectForKey:@"formattedName"];
    
    UIImageView *imageView = cell.profilePicture;
    if ([connectionData objectForKey:@"pictureUrl"] != [NSNull null]) {
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [imageView setImageWithURL:[NSURL URLWithString:[connectionData objectForKey:@"pictureUrl"]]
                  placeholderImage:[CPUIHelper defaultProfileImage]];
    } else {
        imageView.image = [CPUIHelper defaultProfileImage];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - private

- (void)loadLinkedInConnections {
    OAMutableURLRequest *request = [[CPLinkedInAPI shared] linkedInJSONAPIRequestWithRelativeURL:
                                    @"v1/people/~/connections:(id,formatted-name,picture-url)"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(loadLinkedInConnectionsResult:didFinish:)
                  didFailSelector:@selector(loadLinkedInConnectionsResult:didFail:)];
    
    [SVProgressHUD showWithStatus:@"Loading..."];
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFinish:(NSData *)data {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    self.connections = [self filterOutInvalidConnections:[json objectForKey:@"values"]];
    [self.tableView reloadData];
    
    [SVProgressHUD dismiss];
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSError *)error {
    [SVProgressHUD dismissWithError:[error localizedDescription]
                         afterDelay:kDefaultDimissDelay];
}

- (NSMutableArray *)filterOutInvalidConnections:(NSArray *)connections {
    NSMutableArray *filteredConnections = [NSMutableArray arrayWithCapacity:[connections count]];
    
    for (NSDictionary *connectionData in connections) {
        if ( ! [@"private" isEqual:[connectionData objectForKey:@"id"]]) {
            [filteredConnections addObject:connectionData];
        }
    }
    
    return filteredConnections;
}

@end
