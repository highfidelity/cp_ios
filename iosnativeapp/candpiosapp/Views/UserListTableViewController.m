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
#import "CPapi.h"
#import "SVProgressHUD.h"
#import "CheckInDetailsViewController.h"
#import "CPAnnotation.h"
#import "OCAnnotation.h"
#import "VenueInfoViewController.h"

@interface UserListTableViewController()
@property BOOL venueList;
@property id delegate;
@end

@implementation UserListTableViewController

@synthesize delegate, missions, checkedInMissions, titleForList, listType, currentVenue;
@synthesize mapBounds = _mapBounds;
@synthesize venues = _venues;
@synthesize venueList = _venueList;


- (void)setVenues:(NSMutableArray *)venues
{
    _venues = venues;
}

- (NSMutableArray *)venues
{
    if (_venues == nil) {
        _venues = [[NSMutableArray alloc] init];
    }
    return _venues;
}
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
    
    // Add a notification catcher for refreshViewOnCheckin to refresh the view
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshViewOnCheckin:) 
                                                 name:@"refreshViewOnCheckin" 
                                               object:nil];    
    
    self.title = self.titleForList;
    self.venueList = NO;
    
    MKMapPoint neMapPoint = MKMapPointMake(self.mapBounds.origin.x + self.mapBounds.size.width, self.mapBounds.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(self.mapBounds.origin.x, self.mapBounds.origin.y + self.mapBounds.size.height);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    
    [SVProgressHUD showWithStatus:@"Loading..."];

    [CPapi getVenuesInSWCoords:swCoord
                   andNECoords:neCoord
                  userLocation:[AppDelegate instance].settings.lastKnownLocation
                withCompletion:^(NSDictionary *json, NSError *error) {
                    
                    BOOL respError = [[json objectForKey:@"error"] boolValue];
                    if (!error && !respError) {
                        
                        NSArray *itemsArray = [json objectForKey:@"payload"];
                        
                        if ([itemsArray class] != [NSNull class]) {
                            for (NSMutableDictionary *item in itemsArray) {
                                CPPlace *place = [[CPPlace alloc] init];
                                
                                place.name = [item valueForKey:@"name"];
                                place.foursquareID = [item valueForKey:@"foursquare"];
                                place.address = [item valueForKey:@"address"];
                                place.city = [item valueForKey:@"city"];
                                place.state = [item valueForKey:@"state"];
                                place.photoURL = [item valueForKey:@"photo_url"];
                                place.phone = [item valueForKey:@"phone"];
                                place.formattedPhone = [item valueForKey:@"formatted_phone"];
                                place.checkinCount = [[item valueForKey:@"checkins"] integerValue];
                                place.distanceFromUser = [[item valueForKey:@"distance"] doubleValue];
                                place.lat = [[item valueForKey:@"lat"] doubleValue];
                                place.lng = [[item valueForKey:@"lng"] doubleValue];
                                
                                [[self venues] addObject:place];
                            }   
                        }
                    }

                    [SVProgressHUD dismiss];
        
    }];
    
    [self filterData];
    
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
    [[AppDelegate instance] showCheckInButton];
    [super viewDidAppear:animated];
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
    
    for (CPAnnotation *annotation in missions) {
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
    [missions sortUsingDescriptors:[NSArray arrayWithObjects:d,nil]];

    // Clean up old checkins
    for (NSNumber *userId in badUserIds) {
        NSArray *duplicates = [missions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userId == %d", [userId integerValue]]];
        
        for (NSInteger i = 0; i < (duplicates.count - 1); i++) {
            [badAnnotations addObject:[duplicates objectAtIndex:i]];
        }        
    }
    [missions removeObjectsInArray:badAnnotations];
    
    NSMutableArray *excludedAnnotations = [[NSMutableArray alloc] init];
    
    checkedInMissions = [[NSMutableArray alloc] init];
    for (CPAnnotation *mission in missions) {
        if (mission.checkedIn) {
//            NSLog(@"currentVenue: %@", currentVenue);
//            NSLog(@"Mission's venue: %@", mission.groupTag);
//            if ((currentVenue && [mission.groupTag isEqualToString:currentVenue]) || !currentVenue) {
                [checkedInMissions addObject:mission];
//            }
//            else {
//                [excludedAnnotations addObject:mission];
//            }
        }
    }
    
    if (excludedAnnotations.count > 0) {
        [missions removeObjectsInArray:excludedAnnotations];
    }
    
    [missions removeObjectsInArray:checkedInMissions];

    NSSortDescriptor *descriptor;
    
    if (listType == 0) {
        // Could sort by checkinId in reverse order to get most recent checkins
        descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
    }
    else {
         descriptor = [[NSSortDescriptor alloc] initWithKey:@"checkinCount" ascending:NO];
    }

    [missions sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    [checkedInMissions sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
        
}

- (void)refreshViewOnCheckin:(NSNotification *)notification {
    // get data based on the venue list we are viewing
    if (self.currentVenue) {
        missions = [self.delegate getCheckinsByGroupTag:self.currentVenue];
    } else {
        missions = [self.delegate getCheckins];
    }
    
    // filter that data
    [self filterData];
    // and reload the table
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.venueList) {
        return 2;
    }
    
    if (checkedInMissions.count > 0 && missions.count > 0) {
        return 3;
    }
    else if (checkedInMissions.count > 0 || missions.count > 0) {
        return 2;
    }
    else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *checkedInNow;
    NSString *lastCheckins = @"Last 7 Days";

    if (self.venueList) {
        return @"";
    }
    
    if (listType == 0) {
        checkedInNow = @"Checked In Now";
    }
    else {
        checkedInNow = @"Here Now";
    }

    if (section == 1 && checkedInMissions.count > 0) {
        return checkedInNow;
    }
    else if (section == 1 && missions.count > 0) {
        return lastCheckins;
    }
    else if (section == 2) {
        return lastCheckins;
    }
    else {
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    if (section == 1 && self.venueList) {
        return [[self venues] count];
    }

    if (section == 1 && checkedInMissions.count > 0) {
        return checkedInMissions.count;
    }
    else if (section == 1 && missions.count > 0) {
        return missions.count;
    }
    else if (section == 2) {
        return missions.count;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 36;
    }
    return 130;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [tableView dequeueReusableCellWithIdentifier:@"UserListMenuCell"];
    }

    if (indexPath.section == 1 && self.venueList) {
        
        static NSString *venueCellIdentifier = @"VenueListCustomCell";
        
        VenueCell *vcell = [tableView dequeueReusableCellWithIdentifier:venueCellIdentifier];
        
        if (vcell == nil) {
            vcell = [[VenueCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:venueCellIdentifier];
        }
        
        CPPlace *venue = [[self venues] objectAtIndex:indexPath.row];
        
        vcell.venueName.text = venue.name;
        vcell.venueAddress.text = venue.address;

        vcell.venueDistance.text = [NSString stringWithFormat:@"%@ %@", [CPUtils localizedDistanceStringFromMiles:venue.distanceFromUser], @"away"];
        
        vcell.venueCheckins.text = @"";
        if (venue.checkinCount  > 0) {
            if (venue.checkinCount == 1) {
                vcell.venueCheckins.text = @"1 person here now";
            } else {
                vcell.venueCheckins.text = [NSString stringWithFormat:@"%d people here now", venue.checkinCount];
            }
        } else {
            vcell.venueCheckins.text = @"";
        }

        if (![venue.photoURL isKindOfClass:[NSNull class]]) {
            [vcell.venuePicture setImageWithURL:[NSURL URLWithString:venue.photoURL]
                               placeholderImage:[UIImage imageNamed:@"picture-coming-soon.jpg"]];
        } else {
            vcell.venuePicture.image = [UIImage imageNamed:@"picture-coming-soon.jpg"];
        }
        
        return vcell;
    }
    
    if (indexPath.section > 1 && self.venueList) {
        return nil;
    }

    static NSString *CellIdentifier = @"UserListCustomCell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // Configure the cell...
    CPAnnotation *annotation;

    if (indexPath.section == 1 && checkedInMissions.count > 0) {
        annotation = [checkedInMissions objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1 && missions.count > 0) {
        annotation = [missions objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 2) {
        annotation = [missions objectAtIndex:indexPath.row];
    }

    // Add FaceToFace information
    NSString* haveMet = @"";
    if (annotation.haveMet) {
        haveMet = @" (F2F)";
    }
    
    cell.nicknameLabel.text = [annotation.nickname stringByAppendingString:haveMet];

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
    if (section == 0 || self.venueList) {
        return 0;
    }
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if ([[segue identifier] isEqualToString:@"ShowUserProfileCheckedInFromList"]) {
        
        CPAnnotation *annotation;

        if (indexPath.section == 1 && checkedInMissions.count > 0) {
            annotation = [checkedInMissions objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == 1 && missions.count > 0) {
            annotation = [missions objectAtIndex:indexPath.row];
        }
        else if (indexPath.section == 2) {
            annotation = [missions objectAtIndex:indexPath.row];
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
        // set the user object on the UserProfileCheckedInVC to the user we just created
        [[segue destinationViewController] setUser:selectedUser];
    } else if ([[segue identifier] isEqualToString:@"ProfileToFace2FaceInvite"]) {
        // We're going to make a F2F invite!
        
    } else if ([[segue identifier] isEqualToString:@"ShowVenueInfoViewFromVenueList"]) {
        // give place info to the CheckInDetailsViewController
        CPPlace *place = [[self venues] objectAtIndex:indexPath.row];
        [[segue destinationViewController] setVenue:place];
    }
}

- (IBAction)peopleButtonClick:(UIButton *)sender 
{
    self.venueList = NO;
    [[self navigationItem] setTitle:@"People"];
    [[self.view viewWithTag:4] setAlpha:0.4];
    [[self.view viewWithTag:3] setAlpha:1];
    [[self.view viewWithTag:41] setHidden:YES];
    [[self.view viewWithTag:31] setHidden:NO];
    
    [((UITableView *)[self view]) reloadData];
}

- (IBAction)placesButtonClick:(UIButton *)sender 
{
    self.venueList = YES;
    [[self navigationItem] setTitle:@"Place"];
    [[self.view viewWithTag:4] setAlpha:1];
    [[self.view viewWithTag:3] setAlpha:0.4];
    [[self.view viewWithTag:41] setHidden:NO];
    [[self.view viewWithTag:31] setHidden:YES];
    
    [((UITableView *)[self view]) reloadData];
}
@end
