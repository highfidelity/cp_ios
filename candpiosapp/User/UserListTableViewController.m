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
#import "CPObjectManager.h"

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
    
    self.tableView.tableFooterView = [self tabBarButtonAvoidingFooterView];
    
    [self.tableView.pullToRefreshView triggerRefresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshData];
}

#pragma mark - private Methods/Data

- (void)refreshData
{
    CLLocationCoordinate2D currentCoord = [CPAppDelegate currentOrDefaultLocation].coordinate;
    NSDictionary *latLngDict = @{@"lat" : @(currentCoord.latitude), @"lng" : @(currentCoord.longitude)};
    [[CPObjectManager sharedManager] getObjectsAtPathForRouteNamed:kRouteNearestCheckedIn
                                                            object:latLngDict
                                                        parameters:@{@"v" : @"20121128"}
                                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        self.checkedInUsers = [result.array mutableCopy];
        
        if (!self.userIsPerformingQuickAction) {
            NSUInteger preReloadVisibleCellsCount = [self.tableView.visibleCells count];
            
            [self.tableView reloadData];
            
            if (!preReloadVisibleCellsCount) {
                [self animateSlideWaveWithCPUserActionCells:self.tableView.visibleCells];
            }
        } else {
            self.reloadPrevented = YES;
        }
        
        [self.tableView.pullToRefreshView stopAnimating];

    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:[error localizedDescription]
                                  duration:kDefaultDismissDelay];
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
    if (user.lastCheckIn.statusText.length > 0 && user.lastCheckIn.isCurrentlyCheckedIn) {
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", user.lastCheckIn.statusText];
    }
    
    cell.checkInLabel.text = [NSString stringWithFormat:@"@%@", user.lastCheckIn.venue.name];

    [CPUIHelper profileImageView:cell.profilePictureImageView
             withProfileImageUrl:user.photoURL];
    cell.nicknameLabel.text = [CPUIHelper profileNickname:user.nickname];
    
    if ([cell.user.isContact boolValue]) {
        cell.rightStyle = CPUserActionCellSwipeStyleReducedAction;
    } else{
        cell.rightStyle = CPUserActionCellSwipeStyleQuickAction;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    cell.hoursWorkedLabel.text = [NSString stringWithFormat:@"%d", [user.totalHoursCheckedIn intValue]];
    cell.endorseCountLabel.text = [NSString stringWithFormat:@"%d", [user.totalEndorsementCount intValue]];

    return cell;
}

@end
