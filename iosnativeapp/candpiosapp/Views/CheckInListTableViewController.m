#import "CheckInListTableViewController.h"
#import "AppDelegate.h"
#import "CheckInDetailsViewController.h"
#import "CPPlace.h"
#import "SVProgressHUD.h"
#import "SignupController.h"

@implementation CheckInListTableViewController

@synthesize places;

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

    self.title = @"Places";
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(closeWindow:)];

    self.navigationItem.leftBarButtonItem = closeButton;
}

- (void)closeWindow:(id)sender {
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
    [self refreshLocations];
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
    return YES;
}

- (void)refreshLocations {
	[SVProgressHUD showWithStatus:@"Loading nearby places..."];

    // Reset the Places array
    
    places = [[NSMutableArray alloc] init];

    // Format: https://api.foursquare.com/v2/venues/search?ll=44.3,37.2&limit=20&oauth_token=BCG410DXRKXSBRWUNM1PPQFSLEFQ5ND4HOUTTTWYUB1PXYC4

    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
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

    CPPlace *place = [[CPPlace alloc] init];
    place.name = @"<Location Not Listed>";
    place.foursquareID = @"0";
    
    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
    place.lat = location.coordinate.latitude;
    place.lng = location.coordinate.longitude;
    
    [places addObject:place];
    
    NSArray *itemsArray = [[[[json valueForKey:@"response"] valueForKey:@"groups"] valueForKey:@"items"] objectAtIndex:0];

    for (NSMutableDictionary *item in itemsArray) {
        NSLog(@"ITEM FULL: %@", item);

        CPPlace *place = [[CPPlace alloc] init];
        place.name = [item valueForKey:@"name"];
        place.foursquareID = [item valueForKey:@"id"];
        place.address = [[item valueForKey:@"location"] valueForKey:@"address"];
        place.city = [[item valueForKey:@"location"] valueForKey:@"city"];
        place.state = [[item valueForKey:@"location"] valueForKey:@"state"];
        place.zip = [[item valueForKey:@"location"] valueForKey:@"postalCode"];
        
        place.lat = [[[item valueForKey:@"location"] valueForKey:@"lat"] floatValue];
        place.lng = [[[item valueForKey:@"location"] valueForKey:@"lng"] floatValue];
        [places addObject:place];
    }

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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    cell.textLabel.text = [[places objectAtIndex:indexPath.row] name];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([AppDelegate instance].settings.candpUserId) {
        CheckInDetailsViewController *detailViewController = [[CheckInDetailsViewController alloc] init];
        detailViewController.title = [[places objectAtIndex:indexPath.row] name];
        detailViewController.place = [places objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:detailViewController animated:YES];        
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must be logged in to C&P in order to check in." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alertView show];
        
        SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
