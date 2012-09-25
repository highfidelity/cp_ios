//
//  InviteLinkedInConnectionsTableViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "InviteLinkedInConnectionsTableViewController.h"
#import "OAuthConsumer.h"
#import "CPLinkedInAPI.h"
#import "LinkedInConnectionCell.h"
#import "EditLinkedInInvitationMessageViewController.h"

@interface InviteLinkedInConnectionsTableViewController ()

@property (strong, nonatomic) NSArray *connections;
@property (strong, nonatomic) NSMutableDictionary *selectedConnections;

- (void)loadLinkedInConnections;
- (NSMutableArray *)filterOutInvalidConnections:(NSArray *)connections;
- (NSDictionary *)connectionForIndexPath:(NSIndexPath *)indexPath;
- (void)setConnection:(NSDictionary *)connection isSelected:(BOOL)selected;
- (BOOL)isConnectionSelected:(NSDictionary *)connection;
- (NSArray *)arrayOfSlectedConnectionIDs;

@end

@implementation InviteLinkedInConnectionsTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectedConnections = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadLinkedInConnections];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditLinkedInInvitationMessageViewControllerSegue"]) {
        EditLinkedInInvitationMessageViewController *editInvitationViewController = (EditLinkedInInvitationMessageViewController *)segue.destinationViewController;
        
        editInvitationViewController.nickname = [CPUserDefaultsHandler currentUser].nickname;
        editInvitationViewController.connectionIDs = [self arrayOfSlectedConnectionIDs];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self resetNextButtonEnabledState];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.connections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *connectionData = [self connectionForIndexPath:indexPath];
    
    static NSString *CellIdentifier = @"LinkedInConnectionCell";
    LinkedInConnectionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.linkedInName.text = [connectionData objectForKey:@"formattedName"];
    
    UIImageView *imageView = cell.linkedInProfileImage;
    if ([connectionData objectForKey:@"pictureUrl"] != [NSNull null]) {
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [imageView setImageWithURL:[NSURL URLWithString:[connectionData objectForKey:@"pictureUrl"]]
                  placeholderImage:[CPUIHelper defaultProfileImage]];
    } else {
        imageView.image = [CPUIHelper defaultProfileImage];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([self isConnectionSelected:connectionData]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BOOL selected = NO;
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        selected = YES;
    }
    
    [self setConnection:[self connectionForIndexPath:indexPath]
             isSelected:selected];
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self resetNextButtonEnabledState];
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
                         afterDelay:kDefaultDismissDelay];
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

- (NSDictionary *)connectionForIndexPath:(NSIndexPath *)indexPath {
    return [self.connections objectAtIndex:indexPath.row];
}

- (void)setConnection:(NSDictionary *)connection isSelected:(BOOL)selected {
    NSString *connectionID = [connection objectForKey:@"id"];
    
    if (selected) {
        [self.selectedConnections setObject:connection forKey:connectionID];
    } else {
        [self.selectedConnections removeObjectForKey:connectionID];
    }
}

- (BOOL)isConnectionSelected:(NSDictionary *)connection {
    NSString *connectionID = [connection objectForKey:@"id"];
    
    if ([self.selectedConnections objectForKey:connectionID]) {
        return YES;
    }
    return NO;
}

- (NSArray *)arrayOfSlectedConnectionIDs {
    return [[self.selectedConnections keyEnumerator] allObjects];
}

- (void)resetNextButtonEnabledState {
    BOOL enabled = [self.selectedConnections count] > 0;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
