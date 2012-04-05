//
//  UserListTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "MissionAnnotation.h"
#import "UIImageView+WebCache.h"
#import "UserTableViewCell.h"
#import "UserProfileCheckedInViewController.h"
#import "NSString+HTML.h"
#import "VenueCell.h"
#import "CheckInDetailsViewController.h"
#import "CPAnnotation.h"
#import "OCAnnotation.h"
#import "VenueInfoViewController.h"

@interface UserListTableViewController()
@end

@implementation UserListTableViewController

@synthesize delegate, users, checkedInUsers, listType, currentVenue;
@synthesize mapBounds = _mapBounds;


// TODO: These are users, not missions so change the property name accordingly

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // listType of 1 is used from within an annotation's callouts, otherwise set to 0, default for global list
    if (!listType) {
        listType = 0;
    }
    
    // the map is our delegate
    self.delegate = [[CPAppDelegate settingsMenuController] mapTabController];
    
    // Add a notification catcher for refreshViewOnCheckin to refresh the view
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshViewOnCheckin:) 
                                                 name:@"refreshViewOnCheckin" 
                                               object:nil];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshViewOnCheckin" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // call refreshViewOnCheckin now to grab data from the map
    [self refreshViewOnCheckin:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)filterData {
    
    // Iterate through the passed missions and only show the ones that were within the map bounds, ordered by distance

    CLLocation *currentLocation = [AppDelegate instance].settings.lastKnownLocation;

    // Build a list of annotations that should be removed from the list view so that duplicate individuals aren't shown (if they check in several times)
    NSMutableArray *badAnnotations = [[NSMutableArray alloc] init];
    NSMutableSet *goodUserIds = [[NSMutableSet alloc] init];
    NSMutableSet *badUserIds = [[NSMutableSet alloc] init];
    
    for (CPAnnotation *annotation in users) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.lat longitude:annotation.lon];
        
        annotation.distance = [location distanceFromLocation:currentLocation];

        annotation.distanceTo = [CPUtils localizedDistanceofLocationA:currentLocation awayFromLocationB:location];
        
        // Check if this person already has a checkin, and if so, mark the user as needing to clean up old checkins
        NSNumber *userId = [NSNumber numberWithInteger:annotation.userId];
        
        if ([goodUserIds containsObject:userId]) {
            [badUserIds addObject:userId];
        }
        else {
            [goodUserIds addObject:userId];
        }        
    }
    

    // first sort using checkinId so that we dont remove the most resent checkin by the user
    NSSortDescriptor *d = [[NSSortDescriptor alloc] initWithKey:@"checkinId" ascending:YES];
    [users sortUsingDescriptors:[NSArray arrayWithObjects:d,nil]];

    // Clean up old checkins
    for (NSNumber *userId in badUserIds) {
        NSArray *duplicates = [users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userId == %d", [userId integerValue]]];
        
        for (NSInteger i = 0; i < (duplicates.count - 1); i++) {
            [badAnnotations addObject:[duplicates objectAtIndex:i]];
        }        
    }
    [users removeObjectsInArray:badAnnotations];
    
    NSMutableArray *excludedAnnotations = [[NSMutableArray alloc] init];
    
    checkedInUsers = [[NSMutableArray alloc] init];
    for (CPAnnotation *mission in users) {
        if (mission.checkedIn) {
//            NSLog(@"currentVenue: %@", currentVenue);
//            NSLog(@"Mission's venue: %@", mission.groupTag);
//            if ((currentVenue && [mission.groupTag isEqualToString:currentVenue]) || !currentVenue) {
                [checkedInUsers addObject:mission];
//            }
//            else {
//                [excludedAnnotations addObject:mission];
//            }
        }
    }
    
    if (excludedAnnotations.count > 0) {
        [users removeObjectsInArray:excludedAnnotations];
    }
    
    [users removeObjectsInArray:checkedInUsers];

    NSSortDescriptor *descriptor;
    
    if (listType == 0) {
        // Could sort by checkinId in reverse order to get most recent checkins
        descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
    }
    else {
         descriptor = [[NSSortDescriptor alloc] initWithKey:@"checkinCount" ascending:NO];
    }

    [users sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    [checkedInUsers sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
        
}

- (void)refreshViewOnCheckin:(NSNotification *)notification {
    // get data based on the venue list we are viewing
    if (self.currentVenue) {
        users = [self.delegate getCheckinsByGroupTag:self.currentVenue];
    } else {
        users = [self.delegate getCheckins];
    }
    
    // filter that data
    [self filterData];
    // and reload the table
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (checkedInUsers.count > 0 && users.count > 0) {
        return 2;
    }
    else if (checkedInUsers.count > 0 || users.count > 0) {
        return 1;
    }
    else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *checkedInNow;
    NSString *lastCheckins = @"Last 7 Days";

    if (listType == 0) {
        checkedInNow = @"Checked In Now";
    }
    else {
        checkedInNow = @"Here Now";
    }

    if (section == 0 && checkedInUsers.count > 0) {
        return checkedInNow;
    }
    else if (section == 0 && users.count > 0) {
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
    if (section == 0 && checkedInUsers.count > 0) {
        return checkedInUsers.count;
    }
    else if (section == 0 && users.count > 0) {
        return users.count;
    }
    else if (section == 1) {
        return users.count;
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

    // Configure the cell...
    CPAnnotation *annotation;

    if (indexPath.section == 0 && checkedInUsers.count > 0) {
        annotation = [checkedInUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 0 && users.count > 0) {
        annotation = [users objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1) {
        annotation = [users objectAtIndex:indexPath.row];
    }
   
    cell.nicknameLabel.text = annotation.nickname;

    // reset the nickname label since this is a reusable cell
    CGRect nicknameFrameChanger = cell.nicknameLabel.frame;
    nicknameFrameChanger.origin.y = 15;
    // show the user's major job category (unless it's other)
    if (![annotation.majorJobCategory isEqualToString:@"other"]) {
        cell.categoryLabel.text = [annotation.majorJobCategory capitalizedString];
        
    } else {
        cell.categoryLabel.text = @"";
        nicknameFrameChanger.origin.y += 16;        
    }
    
    cell.nicknameLabel.frame = nicknameFrameChanger;
    
    cell.statusLabel.text = @"";
    if (![annotation.status isEqualToString:@""]) {
        cell.statusLabel.text = [NSString stringWithFormat:@"\"%@\"",[annotation.status stringByDecodingHTMLEntities]];
    }
    cell.distanceLabel.text = annotation.distanceTo;

    cell.checkInLabel.text = annotation.venueName;
    
    if (annotation.checkinCount == 1) {
        cell.checkInCountLabel.text = [NSString stringWithFormat:@"%d Checkin",annotation.checkinCount];
    }
    else {
        cell.checkInCountLabel.text = [NSString stringWithFormat:@"%d Checkins",annotation.checkinCount];
    }

    UIImageView *imageView = cell.profilePictureImageView;
    if (annotation.imageUrl) {

        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [imageView setImageWithURL:[NSURL URLWithString:annotation.imageUrl]
                       placeholderImage:[CPUIHelper defaultProfileImage]];
    }
    else
    {
        imageView.image = [CPUIHelper defaultProfileImage];
    }
    
    
    
    
    return cell;
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section 
{
    return 22;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    NSString *title = [self tableView:tableView titleForHeaderInSection:section];

    UIView *theView = [[UIView alloc] init];
    theView.backgroundColor = RGBA(66, 66, 66, 1);

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    [label sizeToFit];

    label.frame = CGRectMake(label.frame.origin.x+10, label.frame.origin.y+1, label.frame.size.width, label.frame.size.height);

    [theView addSubview:label];
    
    return theView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CPAnnotation *annotation;
    
    if (indexPath.section == 0 && checkedInUsers.count > 0) {
        annotation = [checkedInUsers objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 0 && users.count > 0) {
        annotation = [users objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1) {
        annotation = [users objectAtIndex:indexPath.row];
    }
    
    // setup a user object with the info we have from the pin and callout
    // so that this information can already be in the resume without having to load it
    User *selectedUser = [[User alloc] init];
    selectedUser.nickname = annotation.nickname;
    selectedUser.status = annotation.status;
    selectedUser.skills = annotation.skills;   
    selectedUser.userID = [annotation.objectId intValue];
    selectedUser.location = CLLocationCoordinate2DMake(annotation.lat, annotation.lon);
    selectedUser.checkedIn = annotation.checkedIn;
    
    UserProfileCheckedInViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    // set the user object on the UserProfileCheckedInVC to the user we just created
    userVC.user = selectedUser;
    
    // push the UserProfileCheckedInViewController onto the navigation controller stack
    [self.navigationController pushViewController:userVC animated:YES];
}
@end
