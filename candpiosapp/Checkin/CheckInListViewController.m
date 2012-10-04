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

@interface CheckInListViewController() <UIAlertViewDelegate, UITableViewDataSource,
                                        UITableViewDelegate, CLLocationManagerDelegate,
                                        UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *closeVenues;
@property (strong, nonatomic) CPVenue *neighborhoodVenue;
@property (strong, nonatomic) CPVenue *defaultVenue;
@property (strong, nonatomic) NSMutableArray *searchCloseVenues;
@property (strong, nonatomic) CPVenue *searchNeighborhoodVenue;
@property (strong, nonatomic) CPVenue *searchDefaultVenue;
@property (strong, nonatomic) CLLocation *searchLocation;
@property (strong, nonatomic) CLLocationManager *checkinLocationManager;
@property (strong, nonatomic) AFHTTPRequestOperation *currentSearchOperation;
@property (nonatomic) BOOL isUserSearching;

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
    
    // make the UISearchBar use UIKeyboardAppearanceAlert
    for(UIView *subView in self.searchBar.subviews) {
        if([subView isKindOfClass: [UITextField class]]) {
            [(UITextField *)subView setKeyboardAppearance: UIKeyboardAppearanceAlert];
        }
    }
    
    // add pull to refresh to UITableView using SVPullToRefresh
    [self.tableView addPullToRefreshWithActionHandler:^{
        [self refreshLocations];
    }];
    
    // trigger a refresh of the tableView
    [self.tableView.pullToRefreshView triggerRefresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // listen to keyboard show/hide notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // we're going offscreen, stop listening to see if the keyboard comes up or goes away
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.currentSearchOperation = [FoursquareAPIClient getVenuesCloseToLocation:self.searchLocation
                                        searchText:nil
                                       completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            // add the close venues that foursquare returned to our array of search results
            [self.closeVenues addObjectsFromArray:[self arrayOfVenuesFromFoursquareResponse:json]];
            
            // sort array of venues, prioritizing wether it's a neighboord and the distance from user
            [self.closeVenues sortUsingSelector:@selector(sortByNeighborhoodAndDistanceToUser:)];
            
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
            NSMutableSet *existingIDs = [self setOfNeighborhoodAndDefaultIDsForPredicate];
            
            // remove any venues from self.closeVenues with a foursquareID in the existingIDs set
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (foursquareID in %@)", existingIDs];
            [self.closeVenues filterUsingPredicate:filterPredicate];
        }
    }
    
    // stop the pull to refresh view if it exists in the tableView
    [self.tableView.pullToRefreshView stopAnimating];

    // tell the tableView to reload its data
    [self.tableView reloadData];
}

- (NSMutableSet *)setOfNeighborhoodAndDefaultIDsForPredicate
{
    NSMutableSet *existingIDs = [NSMutableSet set];
    
    CPVenue *stateNeighborhoodVenue = !self.isUserSearching ? self.neighborhoodVenue : self.searchNeighborhoodVenue;
    CPVenue *stateDefaultVenue = !self.isUserSearching ? self.defaultVenue : self.searchDefaultVenue;
    
    if (stateNeighborhoodVenue) {
        [existingIDs addObject:stateNeighborhoodVenue.foursquareID];
    }
    
    if (stateDefaultVenue) {
        [existingIDs addObject:stateDefaultVenue.foursquareID];
    }
    
    return existingIDs;
}

- (NSMutableArray *)arrayOfVenuesFromFoursquareResponse:(NSDictionary *)json
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

- (CPVenue *)venueForTableViewIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isUserSearching) {
        // grab the cellVenue depending on which row this is
        // the first row is the neighborhood venue and the second is the recent venue
        switch (indexPath.row) {
            case 0:
                return self.neighborhoodVenue;
                break;
            case 1:
                return self.defaultVenue;
                break;
            default:
                return self.closeVenues.count ? [self.closeVenues objectAtIndex:(indexPath.row - 2)] : nil;
                break;
        }
    } else {
        int topResults = (int)!!self.searchNeighborhoodVenue + (int)!!self.searchDefaultVenue;
        
        if (topResults) {
            // we have at least one result stuck to the top
            if (indexPath.row == 0) {
                return self.searchNeighborhoodVenue ? self.searchNeighborhoodVenue : self.searchDefaultVenue;
            } else if (topResults > 1 && indexPath.row == 1) {
                return self.searchDefaultVenue;
            } else {
                return [self.searchCloseVenues objectAtIndex:(indexPath.row - topResults)];
            }
        } else {
            // no top results
            // just return the venue for that row
            return [self.searchCloseVenues objectAtIndex:indexPath.row];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isUserSearching) {
        // 1 for neighborhood, 1 for default, number of close venues
        return 2 + self.closeVenues.count;
    } else {
        // one row for each venue in search result array
        return !!self.searchNeighborhoodVenue + !!self.searchDefaultVenue + self.searchCloseVenues.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CheckInListCell *cell;
    CPVenue *cellVenue = [self venueForTableViewIndexPath:indexPath];
    
    // default for main label is venue name
    NSString *nameLabelText = cellVenue.name;
    
    if ((!self.isUserSearching && indexPath.row == 0) || cellVenue.isNeighborhood) {
        if (cellVenue) {
            // this cell is for a neighborhood so grab the right cell
            cell = [tableView dequeueReusableCellWithIdentifier:@"WFHCheckInListTableCell"];
            
            // WFH venues have a custom name label, 'in' before the venue name
            // unless this is the WFH placeholder
            nameLabelText = [NSString stringWithFormat:@"in %@", cellVenue.name];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"PlaceholderWFHCheckInListTableCell"];
        }           
    } else {
        // grab the standard cell from the table view
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
        
        if (cellVenue == self.defaultVenue) {
            // this is the user's recent venue
            cell.distanceString.text = @"Recent";
        } else {
            // get the localized distance string based on the distance of this venue from the user
            // which we set when we sort the places
            cell.distanceString.text = [CPUtils localizedDistanceStringForDistance:[cellVenue distanceFromUser]];
        }
        
        if (!(cell.venueAddress.text = cellVenue.address)) {
            // if we don't have an address then center the venue name
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 0, cell.venueName.frame.size.width, cell.frame.size.height);
        } else {
            // otherwise put it back since we re-use the cells
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 3, cell.venueName.frame.size.width, 21);
        }
    }
    
    // if we don't have a cellVenue then don't show the disclosureImageView
    // and don't allow selection of the cell
    cell.disclosureImageView.hidden = !cellVenue;
    cell.selectionStyle = cellVenue ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
    
    // give venueName UILabel the value of nameLabelText
    cell.venueName.text = nameLabelText;
    
    return cell;
}

#pragma mark - Table view delegate

#define SWITCH_VENUE_ALERT_TAG 1230

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([CPUserDefaultsHandler currentUser].userID) {
        
        // make sure that we actually have a venue for this row
        // which either means we're searching or it's not a placeholder cell
        if (self.isUserSearching || [self venueForTableViewIndexPath:indexPath]) {
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
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else {
        // deselect the row
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // Tell the user they aren't logged in and show them the Signup Page
        [SVProgressHUD showErrorWithStatus:@"You must be logged in to C&P in order to check in."
                                  duration:kDefaultDismissDelay];
        [CPUserSessionHandler performSelector:@selector(showSignupModalFromViewController:animated:) withObject:self afterDelay:kDefaultDismissDelay];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is a WFH cell make it a little taller
    // otherwise it's the standard 45
    if ((!self.isUserSearching && indexPath.row == 0) || [self venueForTableViewIndexPath:indexPath].isNeighborhood) {
        return 60;
    } else {
        return 45;
    }
}

# pragma mark - Segue Methods

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowCheckInDetailsView"]) {
        NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
        CPVenue *venue = [self venueForTableViewIndexPath:selectedPath];
        
        // deselect the row
        [self.tableView deselectRowAtIndexPath:selectedPath animated:YES];
        
        // give place info to the CheckInDetailsViewController
        [[segue destinationViewController] setVenue:venue];
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

#pragma mark - Search

- (void)keyboardWillShow:(NSNotification *)notification
{
    // use keyboardWillMove helper to resize and move views
    [self keyboardWillMove:notification beingShown:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // use keyboardWillMove helper to resize and move views
    [self keyboardWillMove:notification beingShown:NO];
}

- (void)keyboardWillMove:(NSNotification *)notification beingShown:(BOOL)beingShown
{
    // grab the CGRect for the keyboard end frame
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // grab CGRects for the mapView and tableView so we can alter their frames
    CGRect mapShift = self.mapView.frame;
    CGRect tableShift = self.tableView.frame;
    
    if (beingShown) {
        // keyboard is being shown
        
        // hide the mapView by sliding it up
        mapShift.origin.y -= mapShift.size.height;
        
        // slide up the tableView and allow it to take the extra space
        tableShift.origin.y = self.searchBar.frame.size.height;
        tableShift.size.height = self.view.frame.size.height - self.searchBar.frame.size.height - keyboardRect.size.height;
    } else {
        // keyboard is hiding
        
        // bring the mapView back down
        mapShift.origin.y = self.searchBar.frame.size.height;
        
        // slide the tableView back down and shrink it back to previous size
        tableShift.size.height = self.view.frame.size.height - mapShift.size.height - self.searchBar.frame.size.height;
        tableShift.origin.y = mapShift.origin.y + mapShift.size.height;
    }
    
    // grab the animationDuration and curve from the keyboard animation
    CGFloat animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions keyboardCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // animate the mapView and tableView frame changes using that duration and curve
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:keyboardCurve
                     animations:^{
                         self.mapView.frame = mapShift;
                         self.tableView.frame = tableShift;                         
                     } completion:nil];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // add the cancel button
    searchBar.showsCancelButton = YES;
    
    // prevent pull to refresh in the search view
    self.tableView.showsPullToRefresh = NO;
    
    // toggle the navigation bar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!searchText.length) {
        // the user is no longer searching, switch back to other state
        self.isUserSearching = NO;
    } else {
        // the user is now searching
        self.isUserSearching = YES;
        
        // alloc-init a search results array
        self.searchCloseVenues = [NSMutableArray array];
        
        // search whatever we have locally first
        
        // check if we have a match in the neighborhood venue
        // if so then set our searchNeighborhoodVenue to that venue, otherwise nil it out
        NSRange neighborhoodRange = [self.neighborhoodVenue.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
        self.searchNeighborhoodVenue = neighborhoodRange.location != NSNotFound ? self.neighborhoodVenue : nil;
        
        // check if we have a match in the default venue
        // if so then set our defaultVenue to that venue, otherwise nil it out
        NSRange defaultRange = [self.defaultVenue.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
        self.searchDefaultVenue = defaultRange.location != NSNotFound ? self.defaultVenue : nil;
        
        // filter the searchCloseVenues array using NSPredicate
        self.searchCloseVenues = [[self.closeVenues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText]] mutableCopy];
        
        // search foursquare for more venues which match the search text
        // first cancel the existing search operation if it's still going
        [self.currentSearchOperation cancel];
    
        // ask Foursquare API for 20 venues close to location that have venue names matching the passed searchText
        self.currentSearchOperation = [FoursquareAPIClient getVenuesCloseToLocation:self.checkinLocationManager.location
                                            searchText:searchText
                                            completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
                                                // check if we get an error from foursquare or during JSON parse
                                                // if so just ignore it and don't show the results
                                                if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
                                                    // use parseFoursquareVenueResponse:destinationArray helper to
                                                    // add the venues to self.searchCloseVenues, sort and filter them and then ask the tableView to reload
                                                    NSMutableArray *foursquareResultArray = [self arrayOfVenuesFromFoursquareResponse:json];
                                                    
                                                    // make sure we have no duplicate venues in the foursquare result array
                                                    
                                                    // use the helper method to create an NSMutableSet containing the neighborhood and default venue foursquare ID
                                                    NSMutableSet *existingIDs = [self setOfNeighborhoodAndDefaultIDsForPredicate];
                                                    
                                                    // add the foursquare IDs for venues that we had locally
                                                    for (CPVenue *resultVenue in self.searchCloseVenues) {
                                                        [existingIDs addObject:resultVenue.foursquareID];
                                                    }                                                    
                                                    
                                                    // remove any venues from self.closeVenues with a foursquareID in the existingIDs set
                                                    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (foursquareID in %@)", existingIDs];
                                                    [foursquareResultArray filterUsingPredicate:filterPredicate];
                                                    
                                                    // add the new venues to self.searchCloseVenues
                                                    [self.searchCloseVenues addObjectsFromArray:foursquareResultArray];
                                                    
                                                    // sort the result set by distance, prioritize neighborhoods
                                                    [self.searchCloseVenues sortUsingSelector:@selector(sortByNeighborhoodAndDistanceToUser:)];
                                                    
                                                    // reload the tableView
                                                    [self.tableView reloadData];
                                                }
                                            }];
        
        
    }
    
    // call reloadData to put old un-searched data back OR local results in the tableView
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // toggle the navigation bar
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    // stop the search
    [searchBar resignFirstResponder];
    
    // re-enable pull to refresh in tableView
    self.tableView.showsPullToRefresh = YES;
    
    // clear out the search string
    self.searchBar.text = nil;
    [self searchBar:self.searchBar textDidChange:nil];
    
    // remove the cancel button
    searchBar.showsCancelButton = NO;
}

@end
