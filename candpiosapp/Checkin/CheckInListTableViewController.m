//
//  CheckInListTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.

#import "CheckInListTableViewController.h"
#import "CPVenue.h"
#import "CheckInDetailsViewController.h"
#import "CheckInListCell.h"
#import "FoursquareAPIRequest.h"

@implementation CheckInListTableViewController {
    UIAlertView *addPlaceAlertView;
}

@synthesize places, refreshLocationsNow;

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
    refreshLocationsNow = YES;
    
    self.title = @"Check In";
    
    // don't set the seperator here, add it manually in storyboard
    // allows us to show a line on the top cell when you are at the top of the table view
    // self.tableView.separatorColor = [UIColor colorWithRed:(68.0/255.0) green:(68.0/255.0) blue:(68.0/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // add a line to the top of the table
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(68.0/255.0) green:(68.0/255.0) blue:(68.0/255.0) alpha:1.0];
    [self.view addSubview:topLine];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:@"LoginStateChanged"
                                               object:nil];
}

- (IBAction)closeWindow:(id)sender {
    [SVProgressHUD dismiss];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Load the list of nearby venues
    if (refreshLocationsNow) {
        [self refreshLocations];
        refreshLocationsNow = NO;
    }
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
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    } else {
        return NO;
    }
}

- (void)refreshLocations {
	[SVProgressHUD showWithStatus:@"Loading nearby venues..."];

    // Reset the Places array
    
    places = [[NSMutableArray alloc] init];

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
                [places addObject:place];
            }
            
            // sort the places array by distance from user
            [places sortUsingSelector:@selector(sortByDistanceToUser:)];
            
            // add a custom place so people can checkin if foursquare doesn't have the venue
            CPVenue *place = [[CPVenue alloc] init];
            place.name = @"Add Place...";
            place.foursquareID = @"0";
            
            place.coordinate = userLocation.coordinate;
            
            [places insertObject:place atIndex:[places count]];
            
            [CPapi getDefaultCheckInVenueWithCompletion:^(NSDictionary *jsonVenue, NSError *errorVenue) {
                BOOL respError = [[jsonVenue objectForKey:@"error"] boolValue];
                
                if (!errorVenue && !respError) {
                    NSDictionary *jsonDict = [jsonVenue objectForKey:@"payload"];
                    CPVenue *defaultVenue = [[CPVenue alloc] initFromDictionary:jsonDict];
                    NSPredicate *defaultVenuePredicate = [NSPredicate predicateWithFormat:@"foursquareID != %@", defaultVenue.foursquareID];
                    [places filterUsingPredicate:defaultVenuePredicate];
                    
                    //add default venue
                    [places insertObject:defaultVenue atIndex:0];

                    // reload the tableView now that we have new data
                    [self.tableView reloadData];
                }
                
                // dismiss the loading HUD
                [SVProgressHUD dismiss];
            }];
        } else {
            // dismiss the progress HUD with an error
            [SVProgressHUD dismissWithError:@"Oops!\nCouldn't get the data." afterDelay:3];
            
            UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLocations)];
            self.navigationItem.rightBarButtonItem = refresh;
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
    return [places count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // note that this code will cause the app to crash if these identifiers don't match what is in the storyboard
    // we'd catch that before going to the store, but be careful
    CheckInListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
    
    // if this is the "place not listed" cell then we have a different identifier
    if (indexPath.row == [places count] - 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCellNotListed"];
    } else {
        // get the localized distance string based on the distance of this venue from the user
        // which we set when we sort the places
        if (indexPath.row == 0) {
            cell.distanceString.text = @"Recent";
        } else {
            cell.distanceString.text = [CPUtils localizedDistanceStringForDistance:[[places objectAtIndex:indexPath.row] distanceFromUser]];
        }
        
        cell.venueAddress.text = [[[places objectAtIndex:indexPath.row] address] description];
        if (!cell.venueAddress.text || [cell.venueAddress.text length] == 0) {
            // if we don't have an address then move the venuename down
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 19, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
        } else {
            // otherwise put it back since we re-use the cells
            cell.venueName.frame = CGRectMake(cell.venueName.frame.origin.x, 11, cell.venueName.frame.size.width, cell.venueName.frame.size.height);
        }
    }
    
    cell.venueName.text = [[places objectAtIndex:indexPath.row] name];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([CPUserDefaultsHandler currentUser].userID) {
        // If the item selected is the last in the list, prompt user to add a new venue
        if (indexPath.row == places.count - 1) {
            addPlaceAlertView = [[UIAlertView alloc] initWithTitle:@"Name of New Place" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            addPlaceAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[addPlaceAlertView textFieldAtIndex:0] setDelegate:self];
            [addPlaceAlertView show];
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
            
#define SWITCH_VENUE_ALERT_TAG 1230
            
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
        [CPAppDelegate performSelector:@selector(showSignupModalFromViewController:animated:) withObject:self afterDelay:kDefaultDismissDelay];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is the last row it's the 'place not listed' row so make it smaller
    if (indexPath.row == [places count] - 1) {
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
        CPVenue *place = [places objectAtIndex:path.row];
        
        // give place info to the CheckInDetailsViewController
        [[segue destinationViewController] setVenue:place];
        
    }
}

# pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SWITCH_VENUE_ALERT_TAG) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self performSegueWithIdentifier:@"ShowCheckInDetailsView" sender:self];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
    } else {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        // Check for a valid name, otherwise cancel the Add Place request
        if (buttonIndex == 1) {
            [self addNewPlace:name];
        }
        else {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
    }    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    NSLog(@"text: %@", textField.text);
    [addPlaceAlertView dismissWithClickedButtonIndex:1 animated:YES];
    [self addNewPlace:textField.text];
    return YES;
}

- (void)addNewPlace:(NSString *)name {
	[SVProgressHUD showWithStatus:@"Saving new place..."];

    CPVenue *place = [places objectAtIndex:[self.tableView indexPathForSelectedRow].row];
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
