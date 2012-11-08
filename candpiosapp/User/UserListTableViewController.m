//
//  UserListTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserTableViewCell.h"
#import "GTMNSString+HTML.h"
#import "UIViewController+CPUserActionCellAdditions.h"
#import "NSDictionary+JsonParserWorkaround.h"
#import "CPMarkerManager.h"
#import "SVPullToRefresh.h"

@interface UserListTableViewController()

@property (nonatomic) BOOL userIsPerformingQuickAction;
@property (nonatomic) BOOL reloadPrevented;

@end

@implementation UserListTableViewController

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    __weak UserListTableViewController *weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshData];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SVProgressHUD showWithStatus:@"Loading..."];
    [self refreshData];
}

#pragma mark - private Methods/Data

- (void)refreshData
{
    [CPapi getNearestCheckedInWithCompletion:^(NSDictionary *json, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [self.checkedInUsers removeAllObjects];
            if (![[json objectForKey:@"error"] boolValue]) {

                CLLocation *userLocation = [CPAppDelegate currentOrDefaultLocation];
                NSArray *people = [[json objectForKey:@"payload"] valueForKey:@"people"];
                for (NSDictionary *personJSON in people) {
                    CPUser *user = [[CPUser alloc] initFromDictionary:personJSON];

                    CLLocation *location = [[CLLocation alloc] initWithLatitude:user.location.latitude longitude:user.location.longitude];
                    user.distance = [location distanceFromLocation:userLocation];
                   
                    NSNumber *venueID = [personJSON numberForKey:@"venue_id" orDefault:@0];
                    CPVenue *userVenue;
                    
                    if (!(userVenue = [[CPMarkerManager sharedManager] markerVenueWithID:venueID])) {
                        userVenue = [[CPVenue alloc] init];
                        userVenue.venueID = venueID;
                        userVenue.name = [personJSON objectForKey:@"name" orDefault:@""];
                        user.placeCheckedIn = userVenue;
                    }
                    
                    user.placeCheckedIn = userVenue;
                    [self.checkedInUsers addObject:user];
                }
                
                if (!self.userIsPerformingQuickAction) {
                    NSUInteger preReloadVisibleCellsCount = [self.tableView.visibleCells count];

                    [self.tableView reloadData];

                    if (!preReloadVisibleCellsCount) {
                        [self animateSlideWaveWithCPUserActionCells:self.tableView.visibleCells];
                    }
                } else {
                    self.reloadPrevented = YES;
                }
            } else {
                [SVProgressHUD showErrorWithStatus:[json objectForKey:@"message"]
                                          duration:kDefaultDismissDelay];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]
                                      duration:kDefaultDismissDelay];
        }
        [self.tableView.pullToRefreshView stopAnimating];
    }];
}

- (NSMutableArray *)checkedInUsers
{
    if (!_checkedInUsers) {
        _checkedInUsers = [NSMutableArray array];
    }
    return _checkedInUsers;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.checkedInUsers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 130;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"UserListCustomCell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // be the delegate of the cell for swipe actions
    cell.delegate = self;
    
    // Configure the cell...
    CPUser *user = [self.checkedInUsers objectAtIndex:(NSUInteger) indexPath.row];
    cell.user = user;
    
    // reset the nickname label since this is a reusable cell
    CGRect nicknameFrameChanger = cell.nicknameLabel.frame;
    nicknameFrameChanger.origin.y = 15;
    // show the user's major job category (unless it's other)
    if (![user.majorJobCategory isEqualToString:@"other"]) {
        cell.categoryLabel.text = [user.majorJobCategory capitalizedString];
        
    } else {
        cell.categoryLabel.text = @"";
        nicknameFrameChanger.origin.y += 16;        
    }
    
    cell.nicknameLabel.frame = nicknameFrameChanger;
    
    cell.statusLabel.text = @"";
    if (user.status.length > 0 && user.checkedIn) {
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"",[user.status gtm_stringByUnescapingFromHTML]];
    }
    
    cell.checkInLabel.text = [NSString stringWithFormat:@"@%@", user.placeCheckedIn.name];

    [CPUIHelper profileImageView:cell.profilePictureImageView
             withProfileImageUrl:user.photoURL];
    cell.nicknameLabel.text = [CPUIHelper profileNickname:user.nickname];
    
    if ([cell.user.isContact boolValue]) {
        cell.rightStyle = CPUserActionCellSwipeStyleReducedAction;
    } else{
        cell.rightStyle = CPUserActionCellSwipeStyleQuickAction;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

@end
