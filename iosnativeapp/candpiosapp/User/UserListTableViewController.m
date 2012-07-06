//
//  UserListTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserLoveViewController.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"
#import "NSString+HTML.h"
#import "VenueCell.h"
#import "CheckInDetailsViewController.h"
#import "CPVenue.h"
#import "CPSwipeableQuickActionSwitch.h"
#import "CPSoundEffectsManager.h"
#import "OneOnOneChatViewController.h"

@interface UserListTableViewController()

@property (nonatomic, assign) BOOL userIsPerformingQuickAction;
@property (nonatomic, assign) BOOL reloadPrevented;

@end

@implementation UserListTableViewController

@synthesize userIsPerformingQuickAction = _userIsPerformingQuickAction;
@synthesize reloadPrevented = _reloadPrevented;
@synthesize weeklyUsers = _weeklyUsers;
@synthesize checkedInUsers = _checkedInUsers;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // we are using swipe cells.. which will need to handle the selection themselves
    self.tableView.allowsSelection = NO;

    // the map is our delegate
    self.delegate = [[CPAppDelegate settingsMenuController] mapTabController];
    
    // Add a notification catcher for refreshTableViewWithNewMapData to refresh the view
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(newDataBeingLoaded:) 
                                                 name:@"mapIsLoadingNewData" 
                                               object:nil]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshFromNewMapData:) 
                                                 name:@"refreshUsersFromNewMapData" 
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"mapIsLoadingNewData" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshUsersFromNewMapData" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    // setup the tableView with whatever we already have
    [self filterData];
    
    // tell the map to reload data
    // we'll get a notification when that's done to reload ours
    [self.delegate refreshButtonClicked:nil];
    [self showCorrectLoadingSpinnerForCount:self.weeklyUsers.count + self.checkedInUsers.count];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSMutableArray *)weeklyUsers
{
    if (!_weeklyUsers) {
        _weeklyUsers = [NSMutableArray array];
    }
    return _weeklyUsers;
}

- (NSMutableArray *)checkedInUsers
{
    if (!_checkedInUsers) {
        _checkedInUsers = [NSMutableArray array];
    }
    return _checkedInUsers;
}

- (void)filterData {
    
    // Iterate through the passed missions and only show the ones that were within the map bounds, ordered by distance

    CLLocation *currentLocation = [CPAppDelegate locationManager].location;
    
    for (User *user in [self.weeklyUsers copy]) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:user.location.latitude longitude:user.location.longitude];
        user.distance = [location distanceFromLocation:currentLocation];
        if (user.checkedIn) {
            [self.checkedInUsers addObject:user];
            [self.weeklyUsers removeObject:user];
        }
    }  
    
    // sort the two arrays by the distance to each user
    self.checkedInUsers = [[self.checkedInUsers sortedArrayUsingSelector:@selector(compareDistanceToUser:)] mutableCopy];
    self.weeklyUsers = [[self.weeklyUsers sortedArrayUsingSelector:@selector(compareDistanceToUser:)] mutableCopy];    
    
    // we only want to reload the table view here if the user isn't in the process of performing a quick action
    if (!self.userIsPerformingQuickAction) {
        [self.tableView reloadData];
    } else {
        self.reloadPrevented = YES;
    }
}

-(void)newDataBeingLoaded:(NSNotification *)notification
{
    // check if we're visible
    if ([[[self tabBarController] selectedViewController] isEqual:self]) {
        [self showCorrectLoadingSpinnerForCount:self.weeklyUsers.count + self.checkedInUsers.count];
    }    
}

- (void)refreshFromNewMapData:(NSNotification *)notification {
        
    // clear the user arrays
    [self.weeklyUsers removeAllObjects];
    [self.checkedInUsers removeAllObjects];
    
    self.weeklyUsers = [[(NSDictionary *)notification.object allValues] mutableCopy];    
    
    if (self.isViewLoaded && self.view.window) {
        // we're visible
        [self stopAppropriateLoadingSpinner];
        
        // filter that data
        [self filterData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.checkedInUsers.count > 0 && self.weeklyUsers.count > 0) {
        return 2;
    }
    else if (self.checkedInUsers.count > 0 || self.weeklyUsers.count > 0) {
        return 1;
    }
    else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *checkedInNow;
    NSString *lastCheckins = @"Last 7 Days";
    
    checkedInNow = @"Checked In Now";
    

    if (section == 0 && self.checkedInUsers.count > 0) {
        return checkedInNow;
    }
    else if (section == 0 && self.weeklyUsers.count > 0) {
        return lastCheckins;
    }
    else if (section == 1) {
        return lastCheckins;
    }
    else {
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 && self.checkedInUsers.count > 0) {
        return self.checkedInUsers.count;
    }
    else if (section == 0 && self.weeklyUsers.count > 0) {
        return self.weeklyUsers.count;
    }
    else if (section == 1) {
        return self.weeklyUsers.count;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 130;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"UserListCustomCell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // be the delegate of the cell for swipe actions
    cell.delegate = self;
    
    // Configure the cell...
    User *user;

    if (indexPath.section == 0 && self.checkedInUsers.count > 0) {
        user = [self.checkedInUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 0 && self.weeklyUsers.count > 0) {
        user = [self.weeklyUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1) {
        user = [self.weeklyUsers objectAtIndex:indexPath.row];
    }
   

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
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"",[user.status stringByDecodingHTMLEntities]];
    }
    cell.distanceLabel.text = [CPUtils localizedDistanceStringForDistance:user.distance];
    
    cell.checkInLabel.text = user.placeCheckedIn.name;

    [CPUIHelper profileImageView:cell.profilePictureImageView
             withProfileImageUrl:user.photoURL];
    cell.nicknameLabel.text = [CPUIHelper profileNickname:user.nickname];
    
    //If user is virtually checkedIn then add virtual badge to their profile image
    if(user.checkedIn)
    {
        [CPUIHelper manageVirtualBadgeForProfileImageView:cell.profilePictureImageView
                                         checkInIsVirtual:user.checkInIsVirtual];
    }
    else {
        [CPUIHelper manageVirtualBadgeForProfileImageView:cell.profilePictureImageView
                                         checkInIsVirtual:NO];
    }
    // Additional buttons for contact exchange and chat
    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * buttonImage = [UIImage imageNamed:@"go-menu-button-2.png"];
    [chatButton setImage:buttonImage 
                forState:UIControlStateNormal];
    [chatButton addTarget:self 
                   action:@selector(chatRequest:) 
         forControlEvents:UIControlEventTouchUpInside];
    [chatButton addTarget:self 
                   action:@selector(switchSound:) 
         forControlEvents:UIControlEventTouchDown | UIControlEventTouchUpInside | UIControlEventTouchCancel];
    
    chatButton.frame = CGRectMake(cell.contentView.frame.size.width * 0.45, 
                                  (cell.contentView.frame.size.height / 2) - (buttonImage.size.height / 2), 
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
    [cell.hiddenView addSubview:chatButton];
        
    UIButton *exchangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonImage = [UIImage imageNamed:@"exchange-cards.png"];
    [exchangeButton setImage:buttonImage 
                    forState:UIControlStateNormal];
    [exchangeButton addTarget:self 
                       action:@selector(exchangeContactInfoRequest:) 
             forControlEvents:UIControlEventTouchUpInside];
    [exchangeButton addTarget:self 
                   action:@selector(switchSound:) 
         forControlEvents:UIControlEventTouchDown | UIControlEventTouchUpInside | UIControlEventTouchCancel];
    exchangeButton.frame = CGRectMake(cell.contentView.frame.size.width * 0.7, 
                                  (cell.contentView.frame.size.height / 2) - (buttonImage.size.height / 2), 
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
    [cell.hiddenView addSubview:exchangeButton];
    
    return cell;
}

- (User*) closeTrayAndReturnUser:(id)sender {
    // close the open slide tray
    [self closeOpenCellsExceptForIndexPath:nil];
    
    // return the selected user
    UITableViewCell *cell = (UITableViewCell*)[[sender superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    return [self selectedUserForIndexPath:indexPath];
}

- (void) chatRequest:(id)sender {
    // handle chat request to the selected user
    User *user = [self closeTrayAndReturnUser:sender];
    
    // get a user object with resume data.. which includes its contact settings
    [user loadUserResumeData:^(NSError *error) {
        if (!error) {
            if (user.contactsOnlyChat && !user.isContact) {
                NSString *errorMessage = [NSString stringWithFormat:@"You can not chat with %@ until the two of you have exchanged contact information", user.nickname];
                [SVProgressHUD showErrorWithStatus:errorMessage
                                          duration:kDefaultDimissDelay];
            } else {
                // push the UserProfileViewController onto the navigation controller stack
                OneOnOneChatViewController *chatViewController = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"OneOnOneChatView"];
                chatViewController.user = user; 
                [self.navigationController pushViewController:chatViewController animated:YES];
            }
        } else {
            // error checking for load of user
            NSLog(@"Error in user load during chat request.");
        }
    }];
   
    
    
}

- (void) exchangeContactInfoRequest:(id)sender { 
    // handle chat request to the selected user
    User *user = [self closeTrayAndReturnUser:sender];

    // Offer to exchange contacts
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:kRequestToAddToMyContactsActionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Send"
                                  otherButtonTitles: nil
                                  ];
    actionSheet.tag = user.userID;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Exchange contacts if accepted
    if ([actionSheet title] == kRequestToAddToMyContactsActionSheetTitle) {
        if (buttonIndex != [actionSheet cancelButtonIndex]) {
            [CPapi sendContactRequestToUserId:actionSheet.tag];
        }
    }
}


- (void) switchSound:(id)sender {    
    UIButton *button = (UIButton*)sender;
    NSString *prefix = quickActionPrefix;
    if (button.isHighlighted) { 
        [CPSoundEffectsManager playSoundWithSystemSoundID:
         [CPSoundEffectsManager systemSoundIDForSoundWithName:[prefix stringByAppendingString:@"-sound-on"] type:@"wav"]];
    } else { 
        [CPSoundEffectsManager playSoundWithSystemSoundID:
         [CPSoundEffectsManager systemSoundIDForSoundWithName:[prefix stringByAppendingString:@"-sound-off"] type:@"wav"]];
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    // alloc-init a header UIView and give it the right background color
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
    headerView.backgroundColor = [UIColor colorWithR:68 G:68 B:68 A:1];
    
    // alloc-init a UILabel to place in the header view
    CGFloat labelLeft = 15;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelLeft, 0, headerView.frame.size.width - labelLeft, headerView.frame.size.height)];
    
    // change the font to league gothic
    [CPUIHelper changeFontForLabel:headerLabel toLeagueGothicOfSize:18];
    
    // change the text color and shadow for the label
    headerLabel.textColor = [UIColor colorWithR:193 G:193 B:193 A:1];
    headerLabel.shadowColor = [UIColor colorWithR:0 G:0 B:0 A:0.5];
    headerLabel.shadowOffset = CGSizeMake(0, -1);
    
    // clear the background color on the label
    headerLabel.backgroundColor = [UIColor clearColor];
    
    // give the headerLabel the right text
    headerLabel.text = [self tableView:tableView titleForHeaderInSection:section];

    // add the label to the header
    [headerView addSubview:headerLabel];
    
    // return the headerView
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![CPUserDefaultsHandler currentUser]) {
        [CPAppDelegate showLoginBanner];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    [self closeOpenCellsExceptForIndexPath:indexPath];
    [self showUserProfileForUser:[self selectedUserForIndexPath:indexPath]];
}


- (User *)selectedUserForIndexPath:(NSIndexPath *)indexPath
{
    User *selectedUser;
    
    if (indexPath.section == 0 && self.checkedInUsers.count > 0) {
        selectedUser = [self.checkedInUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 0 && self.weeklyUsers.count > 0) {
        selectedUser = [self.weeklyUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1) {
        selectedUser = [self.weeklyUsers objectAtIndex:indexPath.row];
    }
    
    return selectedUser;
}

- (void)showUserProfileForUser:(User *)selectedUser
{
    UserProfileViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    // set the user object on the UserProfileVC to the user we just created
    userVC.user = selectedUser;
    
    // push the UserProfileViewController onto the navigation controller stack
    [self.navigationController pushViewController:userVC animated:YES];
}

# pragma mark - CPSwipeableTableViewCellDelegate

static NSString *quickActionPrefix = @"send-love-switch";
static CPSwipeableQuickActionSwitch *quickSwitch = nil;

- (CPSwipeableQuickActionSwitch *)quickActionSwitchForDirection:(CPSwipeableTableViewCellDirection)direction
{
    if (!quickSwitch) {
        quickSwitch = [[CPSwipeableQuickActionSwitch alloc] initWithAssetPrefix:quickActionPrefix];
    }
    return quickSwitch;
}

-(void)performQuickActionForDirection:(CPSwipeableTableViewCellDirection)direction cell:(CPSwipeableTableViewCell *)sender
{
    // only show the love modal if this user is logged in
    if ([CPUserDefaultsHandler currentUser]) {
        User *selectedUser = [self selectedUserForIndexPath:[self.tableView indexPathForCell:sender]];
        
        // only show the love modal if this isn't the user themselves
        if (selectedUser.userID != [CPUserDefaultsHandler currentUser].userID) {
            UserLoveViewController *loveModal = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"SendLoveModal"];
            loveModal.user = selectedUser;
            
            [self presentModalViewController:loveModal animated:YES];
        }
    }
}

-(void)cellDidBeginPan:(CPSwipeableTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self closeOpenCellsExceptForIndexPath:indexPath];
    self.userIsPerformingQuickAction = YES;
}

-(void)cellDidFinishPan:(CPSwipeableTableViewCell *)cell
{
    self.userIsPerformingQuickAction = NO;
    
    if (self.reloadPrevented) {
        // we prevented our UITableView from reloading before so fire it now
        [self.tableView reloadData];
        
        // reset the boolean
        self.reloadPrevented = NO;
    }
}

- (void)closeOpenCellsExceptForIndexPath:(NSIndexPath*)openIndexPath {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (!openIndexPath ||
            (openIndexPath.section != indexPath.section || 
             openIndexPath.row != indexPath.row)) {
            UserTableViewCell *cell = (UserTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell close];
        }
    }
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self closeOpenCellsExceptForIndexPath:nil];    
}

@end
