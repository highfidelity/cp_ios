//
//  AutoCheckinTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AutoCheckinTableViewController.h"
#import "CPVenue.h"
#import "AutoCheckinCell.h"

@interface AutoCheckinTableViewController ()
@property (strong, nonatomic) NSMutableArray *placesArray;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AutoCheckinTableViewController

@synthesize globalCheckinSwitch = _globalCheckinSwitch;
@synthesize placesArray;
@synthesize locationManager = _locationManager;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupPlacesArray];
}

- (void)viewDidUnload
{
    [self setGlobalCheckinSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)setupPlacesArray {
    if (!placesArray) {
        placesArray = [[NSMutableArray alloc] init];
    }
    
    NSArray *pastVenues = DEFAULTS(object, kUDPastVenues);
    
    for (NSData *encodedObject in pastVenues) {
        CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        if (venue && venue.name) {
            NSLog(@"venue found: %@", venue.name);
            [placesArray addObject:venue];
        }
    }
   
    NSArray *sortedArray;
    
    sortedArray = [placesArray sortedArrayUsingComparator:^(id a, id b) {
        NSString *first = [(CPVenue *)a name];
        NSString *second = [(CPVenue *)b name];
        return [first compare:second];
    }];
    
    placesArray = [sortedArray mutableCopy];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
//{
//    // create the parent view that will hold header Label
//	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0)];
//	
//	// create the button object
//	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//	headerLabel.backgroundColor = tableView.backgroundColor;
//	headerLabel.opaque = YES;
//	headerLabel.textColor = [UIColor whiteColor];
//	headerLabel.font = [UIFont boldSystemFontOfSize:14];
//	headerLabel.frame = CGRectMake(20.0, 0.0, self.view.bounds.size.width - 40, 44.0);
//    
//	headerLabel.text = @"Choose the venues:";
//	[customView addSubview:headerLabel];
//    
//	return customView;
//}
//
//- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//	return 44.0;
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (placesArray.count > 0) {
        return 1;
    }
    else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (placesArray.count > 0) {
        return placesArray.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AutoCheckinCell";
    AutoCheckinCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    CPVenue *venue = [placesArray objectAtIndex:indexPath.row];
    
    if (venue) {
        cell.venueName.text = venue.name;
        cell.venueAddress.text = venue.address;
    }

    
    // Configure the cell...
    
    return cell;
}

- (IBAction)globalCheckinChanged:(UISwitch *)sender {
    NSLog(@"new value: %i", sender.on);

    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];

    if (!sender.on) {
        [placesArray removeAllObjects];
        [[CPAppDelegate locationManager] stopMonitoringSignificantLocationChanges];
//        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
    else {
        [self setupPlacesArray];
        [[CPAppDelegate locationManager] startMonitoringSignificantLocationChanges];
//        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    
    [self.tableView reloadData];
}

@end
