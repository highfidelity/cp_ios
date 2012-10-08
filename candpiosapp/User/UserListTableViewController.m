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

@interface UserListTableViewController()

@property (nonatomic) BOOL userIsPerformingQuickAction;
@property (nonatomic) BOOL reloadPrevented;

@end

@implementation UserListTableViewController

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [SVProgressHUD showWithStatus:@"Loading..."];
    [CPapi getNearestCheckedInWithCompletion:^(NSDictionary *json, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [self.checkedInUsers removeAllObjects];
            if (![[json objectForKey:@"error"] boolValue]) {

                CLLocation *userLocation = [CPAppDelegate currentOrDefaultLocation];
                NSArray *people = [[json objectForKey:@"payload"] valueForKey:@"people"];
                for (NSDictionary *personJSON in people) {
                    User *user = [[User alloc] initFromDictionary:personJSON];

                    CLLocation *location = [[CLLocation alloc] initWithLatitude:user.location.latitude longitude:user.location.longitude];
                    user.distance = [location distanceFromLocation:userLocation];
                    CPVenue *venue = [[CPVenue alloc] init];
                    venue.name = [personJSON objectForKey:@"venue_name" orDefault:@""];
                    venue.venueID = [[personJSON objectForKey:@"venue_id" orDefault:[NSNumber numberWithInt:0]] intValue];
                    user.placeCheckedIn = venue;
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
    User *user = [self.checkedInUsers objectAtIndex:(NSUInteger) indexPath.row];
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
    cell.distanceLabel.text = [CPUtils localizedDistanceStringForDistance:user.distance];
    
    cell.checkInLabel.text = user.placeCheckedIn.name;

    [CPUIHelper profileImageView:cell.profilePictureImageView
             withProfileImageUrl:user.photoURL];
    cell.nicknameLabel.text = [CPUIHelper profileNickname:user.nickname];
    
    //If user is virtually checkedIn then add virtual badge to their profile image
    [CPUIHelper manageVirtualBadgeForProfileImageView:cell.profilePictureImageView
                                     checkInIsVirtual:user.checkInIsVirtual];
    if (cell.user.isContact) {
        cell.rightStyle = CPUserActionCellSwipeStyleReducedAction;
    } else{
        cell.rightStyle = CPUserActionCellSwipeStyleQuickAction;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

@end
