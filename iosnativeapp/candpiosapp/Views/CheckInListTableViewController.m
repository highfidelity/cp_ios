#import "CheckInListTableViewController.h"
#import "AppDelegate.h"
#import "CPPlace.h"
#import "CheckInDetailsViewController.h"
#import "CPUIHelper.h"
#import "SVProgressHUD.h"
#import "SignupController.h"
#import "CheckInListCell.h"
#import "LocalizedDistanceCalculator.h"

@implementation CheckInListTableViewController

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Title view styling
    [CPUIHelper addDarkNavigationBarStyleToViewController:self];
    self.title = @"Places";
    refreshLocationsNow = YES;
    
    // change the separator color on the table view (since we have a different background)
    self.tableView.separatorColor = [UIColor colorWithRed:(68.0/255.0) green:(68.0/255.0) blue:(68.0/255.0) alpha:1.0];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
	[SVProgressHUD showWithStatus:@"Loading nearby places..."];

    // Reset the Places array
    
    places = [[NSMutableArray alloc] init];

    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    // TODO: Add this to the FoursquareAPIRequest Code
    NSString *locationString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&limit=20&oauth_token=BCG410DXRKXSBRWUNM1PPQFSLEFQ5ND4HOUTTTWYUB1PXYC4", location.coordinate.latitude, location.coordinate.longitude];
    
    NSURL *locationURL = [NSURL URLWithString:locationString];
    
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: 
                        locationURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) 
                               withObject:data waitUntilDone:YES];
    });
}

- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData:responseData //1
                          
                          options:kNilOptions 
                          error:&error];

    // Do error checking here, in case Foursquare is down

    // get the array of places that foursquare returned
    NSArray *itemsArray = [[[[json valueForKey:@"response"] valueForKey:@"groups"] valueForKey:@"items"] objectAtIndex:0];

    // iterate through the results and add them to the places array
    for (NSMutableDictionary *item in itemsArray) {
        CPPlace *place = [[CPPlace alloc] init];
        place.name = [item valueForKey:@"name"];
        place.foursquareID = [item valueForKey:@"id"];
        place.address = [[item valueForKey:@"location"] valueForKey:@"address"];
        place.city = [[item valueForKey:@"location"] valueForKey:@"city"];
        place.state = [[item valueForKey:@"location"] valueForKey:@"state"];
        place.zip = [[item valueForKey:@"location"] valueForKey:@"postalCode"];
        
        
        place.lat = [[item valueForKeyPath:@"location.lat"] doubleValue];
        place.lng = [[item valueForKeyPath:@"location.lng"] doubleValue];
        [places addObject:place];
    }
    
    // sort the places array by distance from user
    [places sortUsingSelector:@selector(sortByDistanceToUser:)];
    
    // add a custom place so people can checkin if foursquare doesn't have the venue
    CPPlace *place = [[CPPlace alloc] init];
    place.name = @"Place not listed...";
    place.foursquareID = @"0";
    
    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
    place.lat = location.coordinate.latitude;
    place.lng = location.coordinate.longitude;
    
    [places insertObject:place atIndex:0];

    [SVProgressHUD dismiss];
    
    [self.tableView reloadData];    
}

#pragma mark - Table view data source

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // note that this code will cause the app to crash if these identifiers don't match what is in the storyboard
    // we'd catch that before going to the store, but be careful
    CheckInListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCell"];
    
    // if this is the "place not listed" cell then we have a different identifier
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInListTableCellNotListed"];
    } else {
        // get a CLLocation for the user and the place so we can get a localized distance between them
        CLLocation *userLocation = [[AppDelegate instance].settings lastKnownLocation];
        CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:[[places objectAtIndex:indexPath.row] lat] longitude:[[places objectAtIndex:indexPath.row] lng]];
        cell.distanceString.text = [LocalizedDistanceCalculator localizedDistanceBetweenLocationA:userLocation andLocationB:placeLocation];
        
        cell.venueAddress.text = [[[places objectAtIndex:indexPath.row] address] description];
        if (!cell.venueAddress.text) {
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

    if ([AppDelegate instance].settings.candpUserId) {
        // segue to CheckInDetailsViewController
        [self performSegueWithIdentifier:@"ShowCheckInDetailsView" sender:self];
    }
    else {
        // Tell the user they aren't logged in and show them the Signup Page
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must be logged in to C&P in order to check in." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alertView show];
        
        SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if this is the first row it's the 'place not listed' row so make it smaller
    if (indexPath.row == 0) {
        return 40;
    } else {
        return 60;
    }    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowCheckInDetailsView"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        CPPlace *place = [places objectAtIndex:path.row];
        
        // give place info to the CheckInDetailsViewController
        [[segue destinationViewController] setPlace:place];
        
    }
}
@end
