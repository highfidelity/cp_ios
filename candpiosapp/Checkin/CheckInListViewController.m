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

typedef enum {
    CPCheckInListSearchStateComplete,
    CPCheckInListSearchStateInProgress,
    CPCheckInListSearchStateError
} CPCheckInListSearchState;

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
@property (nonatomic) CPCheckInListSearchState currentSearchState;

- (IBAction)closeWindow:(id)sender;
- (void)refreshVenues;

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
        [self refreshVenues];
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

- (IBAction)closeWindow:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Helpers

- (void)refreshVenues
{
    // take the user's location at the beginning of the search and use that for both requests and the venue sorting
    self.searchLocation = [self.checkinLocationManager.location copy];
    
    // reset the neighborhood venue
    self.neighborhoodVenue = nil;
    // reset the closeVenues array
    self.closeVenues = [NSMutableArray array];
    
    // reload the table view to show searching state
    // only if user isn't in the middle of a query
    if (!self.isUserSearching) {
        [self.tableView reloadData];
    }
    
    // grab the closest neighborhood from foursquare
    [FoursquareAPIClient getClosestNeighborhoodToLocation:self.searchLocation completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            // insert the returned neighborhood into the first slot in our neighborhoods array
            NSArray *neighborhoodArray = [self arrayOfVenuesFromFoursquareResponse:json];
            self.neighborhoodVenue = neighborhoodArray.count ? [neighborhoodArray objectAtIndex:0] : nil;
            
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
    
    // use loadTwentyClosestVenues to populate the rest of the tableView
    [self loadTwentyClosestVenues:nil];
}

- (void)loadTwentyClosestVenues:(NSString *)searchText
{
    // search foursquare for more venues which match the search text
    // first cancel the existing search operation if it's still going
    [self.currentSearchOperation cancel];
    
    // while we're waiting to hear back from foursquare isWaitingForSearchResults should be YES
    self.currentSearchState = CPCheckInListSearchStateInProgress;

    
    // grab the 20 closest venues to user location, use searchText if passed
    self.currentSearchOperation = [FoursquareAPIClient getVenuesCloseToLocation:self.searchLocation
                                                                     searchText:searchText
                                                                     completion:^(AFHTTPRequestOperation *operation, id json, NSError *error)
    {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            
            // pull the resultArray using arrayOfVenuesFromFoursquareResponse
            NSMutableArray *resultArray = [self arrayOfVenuesFromFoursquareResponse:json];
            
            // different handling if this was from a search query
            if (!searchText) {
                // just assign the result array to our close venues
                self.closeVenues = resultArray;
                
                // sort the result set by distance, prioritize neighborhoods
                [self.closeVenues sortUsingSelector:@selector(sortByNeighborhoodAndDistanceToUser:)];
            } else {
                // use parseFoursquareVenueResponse:destinationArray helper to
                // add the venues to self.searchCloseVenues, sort and filter them and then ask the tableView to reload
                NSMutableArray *foursquareResultArray = [self arrayOfVenuesFromFoursquareResponse:json];
                
                // make sure we have no duplicate venues in the foursquare result array
                foursquareResultArray = [self filterVenueDuplicatesFromArray:foursquareResultArray
                                                                againstArray:self.searchCloseVenues
                                               includeNeighborhoodAndDefault:YES
                                                           isForSearchResult:YES];
                
                // add the new venues to self.searchCloseVenues
                [self.searchCloseVenues addObjectsFromArray:foursquareResultArray];
                
                // sort the result set by distance, prioritizing neighborhoods
                [self.searchCloseVenues sortUsingSelector:@selector(sortByNeighborhoodAndDistanceToUser:)];
            }            
           
            // we've got our result for this search, fix the boolean
            self.currentSearchState = CPCheckInListSearchStateComplete;
           
            if (!searchText) {
                // tell the tableView to reload venues, after filtering for duplicates
                [self filterDuplicatesAndReloadTableVenues];
            } else {
                [self.tableView reloadData];
            }
        } else {
           
            // we want to show an error cell
            self.currentSearchState = CPCheckInListSearchStateError;
           
            // tell the tableView to reload to show the error cell
            [self.tableView reloadData];
        }
    }];    
}

- (void)filterDuplicatesAndReloadTableVenues
{   
    if (self.closeVenues.count) {
        if (self.neighborhoodVenue || self.defaultVenue) {
            self.closeVenues = [self filterVenueDuplicatesFromArray:self.closeVenues
                                                       againstArray:nil
                                      includeNeighborhoodAndDefault:YES
                                                  isForSearchResult:NO];
        }
    }
    
    // if the user isn't searching then reload the table view
    if (!self.isUserSearching) {
        // stop the pull to refresh view if it exists in the tableView
        [self.tableView.pullToRefreshView stopAnimating];
        
        // tell the tableView to reload its data
        [self.tableView reloadData];
    }
}

- (NSMutableArray *)filterVenueDuplicatesFromArray:(NSMutableArray *)filterArray
                                      againstArray:(NSArray *)againstArray
                    includeNeighborhoodAndDefault:(BOOL)includeND
                                 isForSearchResult:(BOOL)isForSearchResult
{
    NSMutableSet *existingIDs = [NSMutableSet set];
    
    // if includeND is yes then we also need to filter out the neighborhood and default venue
    if (includeND) {
        CPVenue *stateNeighborhoodVenue = !isForSearchResult ? self.neighborhoodVenue : self.searchNeighborhoodVenue;
        CPVenue *stateDefaultVenue = !isForSearchResult ? self.defaultVenue : self.searchDefaultVenue;
        
        if (stateNeighborhoodVenue) {
            [existingIDs addObject:stateNeighborhoodVenue.foursquareID];
        }
        
        if (stateDefaultVenue) {
            [existingIDs addObject:stateDefaultVenue.foursquareID];
        }
    }
    
    // if we have an againstArray then we need to also filter out foursquare IDs in that array
    if (againstArray) {
        for (CPVenue *venue in againstArray) {
            [existingIDs addObject:venue.foursquareID];
        }
    }
    
    // remove any venues from self.closeVenues with a foursquareID in the existingIDs set
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (foursquareID in %@)", existingIDs];
    return [[filterArray filteredArrayUsingPredicate:filterPredicate] mutableCopy];
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
    // have a variable that will count the number of results stuck to top
    int topResults;
    
    if (!self.isUserSearching) {
        // not searching so we have a WFH placeholder or venue and possibly a default venue
        topResults = 1 + !!self.defaultVenue;
    } else {
        // searching so we may have either a WFH or default venue but niether is required
        topResults = !!self.searchNeighborhoodVenue + !!self.searchDefaultVenue;
    }
    
    // grab the cellVenue depending on which row this is
    // the first row is the neighborhood venue and the second is the recent venue
    NSArray *stateCloseVenues = !self.isUserSearching ? self.closeVenues : self.searchCloseVenues;
    
    if (topResults) {
        // we have at least one result stuck to the top
        if (indexPath.row == 0) {
            if (!self.isUserSearching) {
                return self.neighborhoodVenue;
            } else {
                return self.searchNeighborhoodVenue ? self.searchNeighborhoodVenue : self.searchDefaultVenue;
            }
        } else if (topResults > 1 && indexPath.row == 1) {
            return !self.isUserSearching ? self.defaultVenue : self.searchDefaultVenue;
        } else {
            return [stateCloseVenues objectAtIndex:(indexPath.row - topResults)];
        }
    } else {
        // searching with no top results
        // just return the venue for that row
        return [self.searchCloseVenues objectAtIndex:indexPath.row];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfRowsForTableView
{
    if (!self.isUserSearching) {
        // 1 for neighborhood, 1 for default if it exists, number of close venues
        return 1 + !!self.defaultVenue + self.closeVenues.count + (self.currentSearchState != CPCheckInListSearchStateComplete);
    } else {
        // one row for each venue in search result array
        return !!self.searchNeighborhoodVenue + !!self.searchDefaultVenue + self.searchCloseVenues.count + (self.currentSearchState != CPCheckInListSearchStateComplete);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfRowsForTableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CheckInListCell *cell;
    
    if ((self.currentSearchState != CPCheckInListSearchStateComplete) && indexPath.row == [self numberOfRowsForTableView] - 1) {
        if (self.currentSearchState == CPCheckInListSearchStateInProgress) {
            // this is the acitivity spinner cell that shows up when the user is searching
            cell = [tableView dequeueReusableCellWithIdentifier:@"SearchingCheckInListTableCell"];
            
            if (!cell.searchingSpinner.isAnimating) {
                [cell.searchingSpinner startAnimating];
            }
        } else {
            // this is the acitivity spinner cell that shows up when the user is searching
            cell = [tableView dequeueReusableCellWithIdentifier:@"SearchErrorCheckInListTableCell"];
        }
    } else {
        CPVenue *cellVenue = [self venueForTableViewIndexPath:indexPath];
        
        // default for main label is venue name
        NSString *nameLabelText = cellVenue.name;
        
        if ((!self.isUserSearching && indexPath.row == 0) || [cellVenue.isNeighborhood boolValue]) {
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
        
        // give venueName UILabel the value of nameLabelText
        cell.venueName.text = nameLabelText;
    }
    
    return cell;
}

#pragma mark - Table view delegate

#define SWITCH_VENUE_ALERT_TAG 1230

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([CPUserDefaultsHandler currentUser]) {
        
        if ((self.currentSearchState != CPCheckInListSearchStateComplete) && indexPath.row == [self numberOfRowsForTableView] - 1) {
            if (self.currentSearchState == CPCheckInListSearchStateError) {
                // this is the error cell and the user has tapped to reload
                
                // refire the request for the twenty closest matching venues
                [self loadTwentyClosestVenues:(self.isUserSearching ? self.searchBar.text : nil)];
                
                // reload the tableView data so it shows the searching cell again
                [self.tableView reloadData];
            }
        } else {
            // make sure that we actually have a venue for this row
            // which either means we're searching or it's not a placeholder cell
            if ([self venueForTableViewIndexPath:indexPath]) {
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
        }
    } else {
        // deselect the row
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // Tell the user they aren't logged in and show them the Signup Page
        [SVProgressHUD showErrorWithStatus:@"You must be logged in to Workclub in order to check in."
                                  duration:kDefaultDismissDelay];
        [CPUserSessionHandler performSelector:@selector(showSignupModalFromViewController:animated:) withObject:self afterDelay:kDefaultDismissDelay];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is a WFH cell make it a little taller
    // otherwise it's the standard 45
    if ((self.currentSearchState != CPCheckInListSearchStateComplete) && indexPath.row == [self numberOfRowsForTableView] - 1) {
        return 45;
    } else if ((!self.isUserSearching && indexPath.row == 0) || [[self venueForTableViewIndexPath:indexPath].isNeighborhood boolValue]) {
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
    
    // if we've moved more than our maximum stray distance then let's reload
    int maximumStrayDistance = 200;
    
    if ([newLocation distanceFromLocation:self.searchLocation] > maximumStrayDistance) {
        [self refreshVenues];
    }
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
    [self.tableView.pullToRefreshView stopAnimating];
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
        
        // search whatever we have locally first
        
        // check if we have a match in the neighborhood venue
        // if so then set our searchNeighborhoodVenue to that venue, otherwise nil it out
        NSRange neighborhoodRange = [self.neighborhoodVenue.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
        self.searchNeighborhoodVenue = neighborhoodRange.location != NSNotFound ? self.neighborhoodVenue : nil;
        
        // check if we have a match in the default venue
        // if so then set our defaultVenue to that venue, otherwise nil it out
        NSRange defaultRange = [self.defaultVenue.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
        self.searchDefaultVenue = defaultRange.location != NSNotFound ? self.defaultVenue : nil;
        
        NSPredicate *venueNamePredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        
        if (!self.searchCloseVenues) {
            // alloc-init a search results array if we don't already have one
            self.searchCloseVenues = [NSMutableArray array];
        } else {
            // filter the results we already have with the new venue name predicate
            [self.searchCloseVenues filterUsingPredicate:venueNamePredicate];
        }
        
        // add any matching results from our local list of close venues
        NSMutableArray *localResultArray = [[self.closeVenues filteredArrayUsingPredicate:venueNamePredicate] mutableCopy];
        
        // if there's anything in searchCloseVenues we need to make sure we aren't introducing any duplicates
        if (self.searchCloseVenues.count && localResultArray.count) {
            localResultArray = [self filterVenueDuplicatesFromArray:localResultArray
                                                       againstArray:self.searchCloseVenues
                                      includeNeighborhoodAndDefault:NO
                                                  isForSearchResult:YES];
            
            // add everything from localResultArray to searchCloseVenues
            [self.searchCloseVenues addObjectsFromArray:localResultArray];
            
            // sort the resulting array by distance and WFH
            [self.searchCloseVenues sortUsingSelector:@selector(sortByNeighborhoodAndDistanceToUser:)];
        } else {
            // just add everything from localResultArray, it's already sorted from closeVenues
            [self.searchCloseVenues addObjectsFromArray:localResultArray];
        }

        // pull an up-to-date location for the user before searching for closest venues
        self.searchLocation = [self.checkinLocationManager.location copy];
        
        [self loadTwentyClosestVenues:searchText];
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
    
    // we're not waiting on any search results anymore
    self.currentSearchState = CPCheckInListSearchStateComplete;
    
    // reload foursquare close venues if we don't have any
    if (!self.closeVenues.count) {
        [self refreshVenues];
    }
    
    // re-enable pull to refresh in tableView
    self.tableView.showsPullToRefresh = YES;
    
    // clear out the search string
    self.searchBar.text = nil;
    [self searchBar:self.searchBar textDidChange:nil];
    
    // remove the cancel button
    searchBar.showsCancelButton = NO;
}

@end
