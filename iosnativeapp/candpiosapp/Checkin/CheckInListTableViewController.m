//
//  CheckInListTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.

#import "CheckInListTableViewController.h"
#import "CPVenue.h"
#import "CheckInDetailsViewController.h"
#import "SignupController.h"
#import "CheckInListCell.h"
#import "FoursquareAPIRequest.h"
#import "LogViewController.h"

@implementation CheckInListTableViewController {
    UIAlertView *addPlaceAlertView;
}

@synthesize delegate = _delegate;
@synthesize places = _places;

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

// TODO: Add a search box at the box of the table view so the user can quickly search for the venue

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // add the separator line above each cell
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(68.0/255.0) green:(68.0/255.0) blue:(68.0/255.0) alpha:1.0];
    [self.view addSubview:topLine];
    
    __block CheckInListTableViewController *checkinTVC = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [checkinTVC refreshLocations]; 
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    } else {
        return NO;
    }
}

- (void)refreshLocations {

    // Reset the Places array
    
    self.places = [[NSMutableArray alloc] init];

    CLLocation *userLocation = [CPAppDelegate locationManager].location;
    [FoursquareAPIRequest getVenuesCloseToLocation:userLocation :^(NSDictionary *json, NSError *error){
        // Do error checking here, in case Foursquare is down
        if (!error || [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            
            // get the array of places that foursquare returned
            NSArray *itemsArray = [[json valueForKey:@"response"] valueForKey:@"venues"];
            
            // iterate through the results and add them to the places array
            for (NSMutableDictionary *item in itemsArray) {
                CPVenue *place = [[CPVenue alloc] init];
                place.name = [item valueForKey:@"name"];
                place.foursquareID = [item valueForKey:@"id"];
                place.address = [[item valueForKey:@"location"] valueForKey:@"address"];
                place.city = [[item valueForKey:@"location"] valueForKey:@"city"];
                place.state = [[item valueForKey:@"location"] valueForKey:@"state"];
                place.zip = [[item valueForKey:@"location"] valueForKey:@"postalCode"];
                place.coordinate = CLLocationCoordinate2DMake([[item valueForKeyPath:@"location.lat"] doubleValue], [[item valueForKeyPath:@"location.lng"] doubleValue]);
                place.phone = [[item valueForKey:@"contact"] valueForKey:@"phone"];
                place.formattedPhone = [item valueForKeyPath:@"contact.formattedPhone"];
                                
                if ([item valueForKey:@"categories"] && [[item valueForKey:@"categories"] count] > 0) {
                    place.icon = [[[item valueForKey:@"categories"] objectAtIndex:0] valueForKey:@"icon"];
                }
                else {
                    place.icon = @"";
                }
                
                CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];                
                
                
                place.distanceFromUser = [placeLocation distanceFromLocation:userLocation];
                [self.places addObject:place];
            }
            
            // sort the places array by distance from user
            [self.places sortUsingSelector:@selector(sortByDistanceToUser:)];
            [self.tableView reloadData];            
            
            [self.tableView.pullToRefreshView stopAnimating];
        }
    }];
}

#pragma mark - Table view data source

- (void)reloadData
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.places count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // note that this code will cause the app to crash if these identifiers don't match what is in the storyboard
    // we'd catch that before going to the store, but be careful
    CheckInListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
    
    // get the localized distance string based on the distance of this venue from the user
    // which we set when we sort the places
    cell.distanceString.text = [CPUtils localizedDistanceStringForDistance:[[self.places objectAtIndex:indexPath.row] distanceFromUser]];
    
    cell.venueAddress.text = [[[self.places objectAtIndex:indexPath.row] address] description];
    if (!cell.venueAddress.text) {
        // if we don't have an address then move the venuename down
        cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 19, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
    } else {
        // otherwise put it back since we re-use the cells
        cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 11, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
    }
    
    cell.venueName.text = [[self.places objectAtIndex:indexPath.row] name];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // give this venue to the delegate as the selected venue
    [self.delegate setSelectedVenue:[self.places objectAtIndex:indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is the last row it's the 'place not listed' row so make it smaller
    return 60;    
}

# pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *name = [alertView textFieldAtIndex:0].text;
    
    // Check for a valid name, otherwise cancel the Add Place request
    if (buttonIndex == 1) {
        [self addNewPlace:name];
    }
    else {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [addPlaceAlertView dismissWithClickedButtonIndex:1 animated:YES];
    [self addNewPlace:textField.text];
    return YES;
}

- (void)addNewPlace:(NSString *)name {
	[SVProgressHUD showWithStatus:@"Saving new place..."];

    CPVenue *place = [self.places objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    place.name = name;
    
    // Send Add request to Foursquare and use the new Venue ID here
    
    CLLocation *location = [CPAppDelegate locationManager].location;
    [FoursquareAPIRequest addNewPlace:name atLocation:location :^(NSDictionary *json, NSError *error){
        // Do error checking here, in case Foursquare is down
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
#if DEBUG
            NSLog(@"JSON returned: %@", [json description]);
#endif
            
            NSString *venueID = [json valueForKeyPath:@"response.venue.id"];
            
            place.foursquareID = venueID;
        }
        else if ([[json valueForKeyPath:@"meta.code"] intValue] == 409) {
            // 409 means a duplicate was found, use the id from the duplicate; if you really want to get fancy, show a list of all possible dupes but that's overkill for now

            NSArray *venues = [json valueForKeyPath:@"response.candidateDuplicateVenues"];
            
            NSString *venueID = [[venues objectAtIndex:0] objectForKey:@"id"];

            place.foursquareID = venueID;
        }
        else {
            // Error encountered, but let the user check in anyhow and use a randomly generated ID so that it will still be tracked internally
            place.foursquareID = [NSString stringWithFormat:@"CandP%@", [[NSProcessInfo processInfo] globallyUniqueString]];

            NSLog(@"Error encountered while adding venue to Foursquare");
        }
        
        [SVProgressHUD dismiss];
        
        [self performSegueWithIdentifier:@"ShowCheckInDetailsView" sender:self];
    }];    
}

@end
