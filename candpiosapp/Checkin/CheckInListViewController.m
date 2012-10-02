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

@interface CheckInListViewController()

@property (strong, nonatomic) UIAlertView *addPlaceAlertView;
@property (strong, nonatomic) CLLocation *searchLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation CheckInListViewController

// TODO: Add a search box at the box of the table view so the user can quickly search for the venue

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // center the map on the user's current location
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance([CPAppDelegate locationManager].location.coordinate, 200, 200)
                   animated:YES];
    
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

#pragma mark - IBActions 

- (IBAction)closeWindow:(id)sender {
    [SVProgressHUD dismiss];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Helpers

- (void)refreshLocations {
    
    // Reset the array of venues
    self.venues = [[NSMutableArray alloc] init];
    
    // take the user's location at the beginning of the search and use that for both requests and the venue sorting
    self.searchLocation = [[CPAppDelegate locationManager].location copy];
    
    [FoursquareAPIClient getClosestNeighborhoodToLocation:self.searchLocation completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
        if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
            // add the returned neighborhood to the array of venues
            [self.venues addObjectsFromArray:[self arrayOfVenuesFromFoursquareResponse:json]];
        }
        
        [FoursquareAPIClient getVenuesCloseToLocation:self.searchLocation completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {            
            if (!error && [[json valueForKeyPath:@"meta.code"] intValue] == 200) {
                
                // add the close venues that foursquare returned to our array of venues
                [self.venues addObjectsFromArray:[self arrayOfVenuesFromFoursquareResponse:json]];
            
                
                // add a custom place so people can check in if foursquare doesn't have the venue
                CPVenue *place = [[CPVenue alloc] init];
                place.name = @"Add Place...";
                place.foursquareID = @"0";
                
                place.coordinate = [CPAppDelegate locationManager].location.coordinate;
                [self.venues insertObject:place atIndex:[self.venues count]];
                
                [CPapi getDefaultCheckInVenueWithCompletion:^(NSDictionary *jsonVenue, NSError *errorVenue) {
                    BOOL respError = [[jsonVenue objectForKey:@"error"] boolValue];
                    
                    if (!errorVenue && !respError) {
                        NSDictionary *jsonDict = [jsonVenue objectForKey:@"payload"];
                        CPVenue *defaultVenue = [[CPVenue alloc] initFromDictionary:jsonDict];
                        NSPredicate *defaultVenuePredicate = [NSPredicate predicateWithFormat:@"foursquareID != %@", defaultVenue.foursquareID];
                        [self.venues filterUsingPredicate:defaultVenuePredicate];
                        
                        //add default venue
                        [self.venues insertObject:defaultVenue atIndex:1];
                        
                        // reload the tableView now that we have new data
                        [self.tableView reloadData];
                    }
                    
                 [self.tableView.pullToRefreshView stopAnimating];
                }];
            } else {
                UIAlertView *bulkLoadFail = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                       message:@"There was a problem getting data from foursquare."
                                                                      delegate:self
                                                             cancelButtonTitle:@"Cancel"
                                                             otherButtonTitles:@"Refresh", nil];
                
                [self.tableView.pullToRefreshView stopAnimating];
                [bulkLoadFail show];
            }
        }];
    }];   
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

- (void)addNewPlace:(NSString *)name {
	[SVProgressHUD showWithStatus:@"Saving new place..."];
    
    CPVenue *place = [self.venues objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    place.name = name;
    
    // Send Add request to Foursquare and use the new Venue ID here
    
    CLLocation *location = [CPAppDelegate locationManager].location;
    [FoursquareAPIClient addNewPlace:name
                            location:location
                          completion:^(AFHTTPRequestOperation *operation, id json, NSError *error) {
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
    return [self.venues count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // note that this code will cause the app to crash if these identifiers don't match what is in the storyboard
    // we'd catch that before going to the store, but be careful
    CheckInListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
    
    // if this is the "place not listed" cell then we have a different identifier
    if (indexPath.row == [self.venues count] - 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCellNotListed"];
    } else {
        // get the localized distance string based on the distance of this venue from the user
        // which we set when we sort the places
        if (indexPath.row == 0) {
            cell.distanceString.text = @"WFH";
        } else if (indexPath.row == 1) {
            cell.distanceString.text = @"Recent";
        } else {
            cell.distanceString.text = [CPUtils localizedDistanceStringForDistance:[[self.venues objectAtIndex:indexPath.row] distanceFromUser]];
        }
        
        cell.venueAddress.text = [[[self.venues objectAtIndex:indexPath.row] address] description];
        if (!cell.venueAddress.text || [cell.venueAddress.text length] == 0) {
            // if we don't have an address then move the venuename down
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 19, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
        } else {
            // otherwise put it back since we re-use the cells
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 11, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
        }
    }
    
    cell.venueName.text = [[self.venues objectAtIndex:indexPath.row] name];
    
    return cell;
}

#pragma mark - Table view delegate

#define SWITCH_VENUE_ALERT_TAG 1230

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([CPUserDefaultsHandler currentUser].userID) {
        // If the item selected is the last in the list, prompt user to add a new venue
        if (indexPath.row == self.venues.count - 1) {
            self.addPlaceAlertView = [[UIAlertView alloc] initWithTitle:@"Name of New Place" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            self.addPlaceAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[self.addPlaceAlertView textFieldAtIndex:0] setDelegate:self];
            [self.addPlaceAlertView show];
            return;
        }
        else if ([CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {
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
    if (indexPath.row == [self.venues count] - 1) {
        return 40;
    } else {
        return 60;
    }    
}

# pragma mark - Segue Methods

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowCheckInDetailsView"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        CPVenue *place = [self.venues objectAtIndex:path.row];
        
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
    } else if (alertView == self.addPlaceAlertView) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        // Check for a valid name, otherwise cancel the Add Place request
        if (buttonIndex == 1) {
            [self addNewPlace:name];
        }
        else {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
    } else {
        // this was the foursquare error alert view
        if (buttonIndex != alertView.cancelButtonIndex) {
            // trigger a refresh of the table view if the user asked for one
            [self.tableView.pullToRefreshView triggerRefresh];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    NSLog(@"text: %@", textField.text);
    [self.addPlaceAlertView dismissWithClickedButtonIndex:1 animated:YES];
    [self addNewPlace:textField.text];
    return YES;
}

@end
