//
//  CheckInListViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.

#import "CheckInListViewController.h"
#import "CheckInDetailsViewController.h"
#import "CheckInListCell.h"
#import "FoursquareAPIClient.h"
#import "CPUserSessionHandler.h"
#import "SVPullToRefresh.h"

@interface CheckInListViewController() <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableArray *closeVenues;
@property (strong, nonatomic) CPVenue *neighborhoodVenue;
@property (strong, nonatomic) CPVenue *defaultVenue;
@property (strong, nonatomic) CLLocation *searchLocation;
@property (strong, nonatomic) CLLocationManager *checkinLocationManager;

- (IBAction)closeWindow:(id)sender;
- (void)refreshLocations;

@end

@implementation CheckInListViewController

// TODO: Add a search box at the box of the table view so the user can quickly search for the venue

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // move the mapView to the user's current location
    // and start location updates so the mapView moves if the user does
    [self zoomMapViewToLocation:self.checkinLocationManager.location];
    [self.checkinLocationManager startUpdatingLocation];
    
    // don't set the seperator here, add it manually in storyboard
    // allows us to show a line on the top cell when you are at the top of the table view
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // add a line to the top of the table
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(68.0/255.0) green:(68.0/255.0) blue:(68.0/255.0) alpha:1.0];
    [self.tableView addSubview:topLine];
    
    // add pull to refresh to UITableView using SVPullToRefresh
    [self.tableView addPullToRefreshWithActionHandler:^{
        [self refreshLocations];
    }];
    
    // trigger a refresh of the tableView
    [self.tableView.pullToRefreshView triggerRefresh];
}

#pragma mark - Overriden getters

- (CLLocationManager *)checkinLocationManager
{
    if (!_checkinLocationManager) {
        _checkinLocationManager = [[CLLocationManager alloc] init];
        _checkinLocationManager.delegate = self;
    }
    
    return _checkinLocationManager;
}

#pragma mark - IBActions 

- (IBAction)closeWindow:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Helpers

- (void)refreshLocations {    
    // take the user's location at the beginning of the search and use that for both requests and the venue sorting
    self.searchLocation = [self.checkinLocationManager.location copy];
    
    // reset the neighborhood venue
    self.neighborhoodVenue = nil;
    // reset the closeVenues array
    self.closeVenues = [NSMutableArray array];
    
    [self.tableView reloadData];
    
    // grab the closest neighborhood from foursquare
    [FoursquareAPIClient getClosestNeighborhoodToLocation:self.searchLocation completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            // insert the returned neighborhood into the first slot in our neighborhoods array
            self.neighborhoodVenue = [[self arrayOfVenuesFromFoursquareResponse:json] objectAtIndex:0];
            
            // tell the tableView to reload venues, after filtering for duplicates
            [self filterDuplicatesAndReloadTableVenues];
        }
    }];
    
    // if we're reloading and we already have a default venue we don't need to grab it again
    if (!self.defaultVenue) {
        // grab this user's recent check in from C&P api
        [CPapi getDefaultCheckInVenueWithCompletion:^(NSDictionary *json, NSError *errorVenue) {
            BOOL respError = [[json objectForKey:@"error"] boolValue];
            
            if (!errorVenue && !respError) {
                // set our default venue to the default venue instantiated using initFromDictionary
                self.defaultVenue = [[CPVenue alloc] initFromDictionary:[json objectForKey:@"payload"]];
                
                // tell the tableView to reload venues, after filtering for duplicates
                [self filterDuplicatesAndReloadTableVenues];
            }
        }];
    }
    
    // grab the 20 closest venues to user location
    [FoursquareAPIClient getVenuesCloseToLocation:self.searchLocation completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            // add the close venues that foursquare returned to our array of venues
            [self.closeVenues addObjectsFromArray:[self arrayOfVenuesFromFoursquareResponse:json]];
            
            // tell the tableView to reload venues, after filtering for duplicates
            [self filterDuplicatesAndReloadTableVenues];
        } else {
            // if this request fails we'll show an error because it represents the majority of the data
            UIAlertView *bulkLoadFail = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                   message:@"There was a problem getting data from foursquare."
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"Refresh", nil];
            
            [bulkLoadFail show];
        }
    }];
}

- (void)filterDuplicatesAndReloadTableVenues
{
    if (self.closeVenues.count) {
        if (self.neighborhoodVenue || self.defaultVenue) {
            NSMutableSet *existingIDs = [NSMutableSet set];
            
            if (self.neighborhoodVenue) {
                // add the neighborhood venue's foursquare ID to the set of existing IDs
                [existingIDs addObject:self.neighborhoodVenue.foursquareID];
            }
            
            if (self.defaultVenue) {
                // add the default venue foursquare ID to the set of existing IDs
                [existingIDs addObject:self.defaultVenue.foursquareID];
            }
            
            // remove any venues from self.closeVenues with a foursquareID in the existingIDs set
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (foursquareID in %@)", existingIDs];
            [self.closeVenues filterUsingPredicate:filterPredicate];
        }
    }
    
    // stop the pull to refresh view
    [self.tableView.pullToRefreshView stopAnimating];
    
    // tell the tableView to reload its data
    [self.tableView reloadData];
}

- (NSArray *)arrayOfVenuesFromFoursquareResponse:(NSDictionary *)json
{
    // setup venueArray to pass back in return
    NSMutableArray *venueArray =  [NSMutableArray array];

    // grab the foursquare venue array from the json response
    NSArray *foursquareVenueArray = [[json valueForKey:@"response"] valueForKey:@"venues"];
    
    // iterate through the results and add them to the places array
    for (NSMutableDictionary *foursquareVenueDict in foursquareVenueArray) {
        CPVenue *venue = [[CPVenue alloc] initFromFoursquareDictionary:foursquareVenueDict userLocation:self.searchLocation];
        [venueArray addObject:venue];
    }
    
    return venueArray;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // 1 for neighborhood, 1 for default, number of close venues and 1 for add place
    return !!self.neighborhoodVenue + !!self.defaultVenue + self.closeVenues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CheckInListCell *cell;
    CPVenue *cellVenue;
    
    // grab the cellVenue depending on which row this is
    // the first row is the neighborhood venue and the second is the recent venue
    switch (indexPath.row) {
        case 0:
            cellVenue = self.neighborhoodVenue;
            break;
        case 1:
            cellVenue = self.defaultVenue;
            break;
        default:
            cellVenue = self.closeVenues.count ? [self.closeVenues objectAtIndex:(indexPath.row - 2)] : nil;
            break;
    }
    
    // default for main label is venue name
    NSString *nameLabelText = cellVenue.name;
    
    if (cellVenue.isNeighborhood) {
        // this cell is for a neighborhood so grab the right cell
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCellWFH"];
        
        // WFH venues have a custom name label, not just the venue name
        nameLabelText = [NSString stringWithFormat:@"in %@", cellVenue.name];
    } else {
        // grab the standard cell from the table view
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
        
        if (self.defaultVenue == cellVenue) {
            // this is the user's recent venue
            cell.distanceString.text = @"Recent";
        } else {
            // get the localized distance string based on the distance of this venue from the user
            // which we set when we sort the places
            cell.distanceString.text = [CPUtils localizedDistanceStringForDistance:[cellVenue distanceFromUser]];
        }
        
        cell.venueAddress.text = cellVenue.address;
        
        if (!cellVenue.address) {
            // if we don't have an address then center the venue name
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 0, cell.venueName.frame.size.width, 45);
        } else {
            // otherwise put it back since we re-use the cells
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 3, cell.venueName.frame.size.width, 21);
        }
    }
    
    cell.venueName.text = nameLabelText;
    
    return cell;
}

#pragma mark - Table view delegate

#define SWITCH_VENUE_ALERT_TAG 1230

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([CPUserDefaultsHandler currentUser].userID) {
        if ([CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {
            // this user is currently checked in
            // we need to present them with an alertView to confirm that they do in fact want to checkout of the previous venue
            // and checkin here now
            NSString *switchVenueMessage = [NSString stringWithFormat:@"Do you want to leave %@?\nYou can always go back later!", 
                                            [CPUserDefaultsHandler currentVenue].name];
            
            UIAlertView *switchVenueConfirm = [[UIAlertView alloc] 
                                               initWithTitle:@"Are you sure?" 
                                               message:switchVenueMessage
                                               delegate:self 
                                               cancelButtonTitle:@"Cancel" 
                                               otherButtonTitles:@"Yes", nil];
            
            switchVenueConfirm.tag = SWITCH_VENUE_ALERT_TAG;
            [switchVenueConfirm show];
            
        } else {
            [self performSegueWithIdentifier:@"ShowCheckInDetailsView" sender:self]; 
        }
    }
    else {
        // Tell the user they aren't logged in and show them the Signup Page
        [SVProgressHUD showErrorWithStatus:@"You must be logged in to C&P in order to check in."
                                  duration:kDefaultDismissDelay];
        [CPUserSessionHandler performSelector:@selector(showSignupModalFromViewController:animated:) withObject:self afterDelay:kDefaultDismissDelay];
    }
    
    // deselect the row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is the last row it's the 'place not listed' row so make it smaller
    if (indexPath.row == 0) {
        return 60;
    } else {
        return 45;
    }
}

# pragma mark - Segue Methods

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowCheckInDetailsView"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        CPVenue *place = [self.closeVenues objectAtIndex:path.row];
        
        // give place info to the CheckInDetailsViewController
        [[segue destinationViewController] setVenue:place];
        
    }
}

# pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SWITCH_VENUE_ALERT_TAG) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self performSegueWithIdentifier:@"ShowCheckInDetailsView" sender:self];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
    } else {
        // this was the foursquare error alert view
        if (buttonIndex != alertView.cancelButtonIndex) {
            // trigger a refresh of the table view if the user asked for one
            [self.tableView.pullToRefreshView triggerRefresh];
        }
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self zoomMapViewToLocation:newLocation];
}

- (void)zoomMapViewToLocation:(CLLocation *)newLocation
{
    // center the map on the user's current location
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 200, 200) animated:YES];
}

@end
