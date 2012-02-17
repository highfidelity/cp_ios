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
#import "WebViewController.h"
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "UserTableViewCell.h"
#import "UserProfileCheckedInViewController.h"

@implementation UserListTableViewController

@synthesize missions, orderedMissions;

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

    self.title = @"List";
    
    // Iterate through the passed missions and only show the ones that were within the map bounds, ordered by distance

    CLLocation *currentLocation = [AppDelegate instance].settings.lastKnownLocation;

    // Build a list of annotations that should be removed from the list view so that duplicate individuals aren't shown (if they check in several times)
    NSMutableArray *badAnnotations = [[NSMutableArray alloc] init];
    NSMutableSet *goodUserIds = [[NSMutableSet alloc] init];
    NSMutableSet *badUserIds = [[NSMutableSet alloc] init];
    
    for (UserAnnotation *annotation in missions) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:annotation.lat longitude:annotation.lon];
        
        annotation.distance = [location distanceFromLocation:currentLocation];

        annotation.distanceTo = [LocalizedDistanceCalculator localizedDistanceBetweenLocationA: currentLocation andLocationB:location];
        
        // Check if this person already has a checkin, and if so, mark the user as needing to clean up old checkins
        NSNumber *userId = [NSNumber numberWithInteger:annotation.userId];
        
        if ([goodUserIds containsObject:userId]) {
            [badUserIds addObject:userId];
        }
        else {
            [goodUserIds addObject:userId];
        }        
    }
    
    // Clean up old checkins
    for (NSNumber *userId in badUserIds) {
        NSArray *duplicates = [missions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userId == %d", [userId integerValue]]];
        
        for (NSInteger i = 0; i < (duplicates.count - 1); i++) {
            [badAnnotations addObject:[duplicates objectAtIndex:i]];
        }        
    }
    
    [missions removeObjectsInArray:badAnnotations];
    
    // Could sort by checkinId in reverse order to get most recent checkins
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];

    [missions sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Count: %d", [missions count]);
    return [missions count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return a slightly taller final cell if more than 5 rows, and on the last row, to compensate for the Check In button cutting into the view

    if ([missions count] > 5 && indexPath.row < ([missions count] - 1)) {
        return 60;
    }
    else {
        return 70;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    // Configure the cell...
    
    UserAnnotation *annotation = [missions objectAtIndex:indexPath.row];

    // Add FaceToFace information
    NSString* haveMet = @"";
    if (annotation.haveMet) {
        haveMet = @" (F2F)";
    }
    
    cell.nicknameLabel.text = [annotation.nickname stringByAppendingString:haveMet];
    cell.statusLabel.text = annotation.status;
    cell.distanceLabel.text = annotation.distanceTo;
    
    //if (annotation.skills != [NSNull null]) {
    //    cell.skillsLabel.text = annotation.skills;
    //}
        
    if (annotation.imageUrl) {
        UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
		
		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
        
        [leftCallout setImageWithURL:[NSURL URLWithString:annotation.imageUrl]
                    placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
        
        cell.imageView.image = leftCallout.image;
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"63-runner.png"];			
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"ShowUserProfileCheckedInFromList" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowUserProfileCheckedInFromList"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        UserAnnotation *annotation = [missions objectAtIndex:path.row];
        
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
    }
}

@end
