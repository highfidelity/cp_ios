//
//  AutoCheckinTableViewController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AutoCheckinTableViewController.h"
#import "AutoCheckinCell.h"
#import "CPGeofenceHandler.h"

@interface AutoCheckinTableViewController ()
@property (strong, nonatomic) NSMutableArray *placesArray;
@end

@implementation AutoCheckinTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // If automaticCheckins is disabled, hide the table view unless changed
    BOOL automaticCheckins = [CPUserDefaultsHandler automaticCheckins];
        
    self.globalCheckinSwitch.on = automaticCheckins;

    if (automaticCheckins) {    
        [self setupPlacesArray];
    }
}

- (void)setupPlacesArray {
    if (!self.placesArray) {
        self.placesArray = [[NSMutableArray alloc] init];
    }
    
    NSArray *pastVenues = [CPUserDefaultsHandler pastVenues];
    
    for (NSData *encodedObject in pastVenues) {
        CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        if (venue && venue.name) {
            [self.placesArray addObject:venue];
        }
    }
   
    NSArray *sortedArray;
    
    sortedArray = [self.placesArray sortedArrayUsingComparator:^(id a, id b) {
        NSString *first = [(CPVenue *)a name];
        NSString *second = [(CPVenue *)b name];
        return [first compare:second];
    }];
    
    self.placesArray = [sortedArray mutableCopy];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return 48;
        case 1:
            return 60;
        default:
            return 69;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.placesArray.count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.row < 2) {
        NSString *topCellIdentifier = indexPath.row == 0 ? @"GeofenceLogButtonCell" : @"AutoCheckInToggleCell";
        cell = [tableView dequeueReusableCellWithIdentifier:topCellIdentifier];
        cell.contentView.backgroundColor = [UIColor colorWithR:40 G:40 B:40 A:1];
    } else {
        static NSString *VenueCellIdentifier = @"AutoCheckinCell";
        AutoCheckinCell *autoCell = [tableView dequeueReusableCellWithIdentifier:VenueCellIdentifier];
        
        CPVenue *venue = [self.placesArray objectAtIndex:(indexPath.row - 2)];
        
        if (venue) {
            autoCell.venueName.text = venue.name;
            autoCell.venueAddress.text = venue.address;
            autoCell.venue = venue;
            
            autoCell.venueSwitch.on = venue.autoCheckin;
        }
        
        cell = autoCell;
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // we're heading to the geofence log
    // The original text on the back button is too long, just make it "Back"
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
}

- (IBAction)globalCheckinChanged:(UISwitch *)sender {
    // Store the choice in NSUserDefaults
    [CPUserDefaultsHandler setAutomaticCheckins:sender.on];
    
    if (!sender.on) {
        // Disable auto checkins
        
        for (CPVenue *venue in self.placesArray) {
            [[CPGeofenceHandler sharedHandler] stopMonitoringVenue:venue];
        }
        
        [self.placesArray removeAllObjects];

        // Clear out all currently monitored regions in order to stop using geofencing altogether
        for (CLRegion *reg in [[CPAppDelegate locationManager] monitoredRegions]) {
            [[CPAppDelegate locationManager] stopMonitoringForRegion:reg];
        }
        
        [Flurry logEvent:@"automaticCheckinsDisabled"];
    }
    else {
        [self setupPlacesArray];
        
        // Iterate over all past venues to start monitoring those with autoCheckin enabled        
        for (CPVenue *venue in self.placesArray) {
            NSLog(@"auto: %i, venue: %@", venue.autoCheckin, venue.name);
            if (venue.autoCheckin) {
                [[CPGeofenceHandler sharedHandler] startMonitoringVenue:venue];
            }
        }

        [Flurry logEvent:@"automaticCheckinsEnabled"];
    }
    
    [self.tableView reloadData];
}

- (IBAction)gearPressed:(UIButton *)sender
{
    [[CPAppDelegate settingsMenuViewController] slideAwayChildViewController];
}
@end
