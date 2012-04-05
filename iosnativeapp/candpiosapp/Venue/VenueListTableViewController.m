//
//  VenuesTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueListTableViewController.h"
#import "CPapi.h"
#import "CPUtils.h"
#import "SVProgressHUD.h"
#import "VenueCell.h"
#import "VenueInfoViewController.h"
#import "MapTabController.h"

@interface VenueListTableViewController ()

@end

@implementation VenueListTableViewController

@synthesize venues = _venues;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableArray *)venues
{
    // lazily instantiate the array of venues
    if (!_venues) {
        _venues = [NSMutableArray array];
    }
    return _venues;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // our delegate is the map tab controller
    self.delegate = [[CPAppDelegate settingsMenuController] mapTabController];
    
    MKMapRect mapBounds = [[self.delegate  mapView] visibleMapRect];
    
    MKMapPoint neMapPoint = MKMapPointMake(mapBounds.origin.x + mapBounds.size.width, mapBounds.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mapBounds.origin.x, mapBounds.origin.y + mapBounds.size.height);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    
    [SVProgressHUD showWithStatus:@"Loading ..."];
    
    [CPapi getVenuesInSWCoords:swCoord
                   andNECoords:neCoord
                  userLocation:[AppDelegate instance].settings.lastKnownLocation
                withCompletion:^(NSDictionary *json, NSError *error) {
                    
                    BOOL respError = [[json objectForKey:@"error"] boolValue];
                    if (!error && !respError) {
                        
                        NSArray *itemsArray = [json objectForKey:@"payload"];
                        
                        if ([itemsArray class] != [NSNull class]) {
                            for (NSMutableDictionary *item in itemsArray) {
                                CPPlace *place = [[CPPlace alloc] init];
                                
                                place.name = [item valueForKey:@"name"];
                                place.foursquareID = [item valueForKey:@"foursquare"];
                                place.address = [item valueForKey:@"address"];
                                place.city = [item valueForKey:@"city"];
                                place.state = [item valueForKey:@"state"];
                                place.photoURL = [item valueForKey:@"photo_url"];
                                place.phone = [item valueForKey:@"phone"];
                                place.formattedPhone = [item valueForKey:@"formatted_phone"];
                                place.checkinCount = [[item valueForKey:@"checkins"] integerValue];
                                place.weeklyCheckinCount = [[item valueForKey:@"checkins_for_week"] integerValue];
                                place.monthlyCheckinCount = [[item valueForKey:@"checkins_for_month"]
                                                             integerValue];
                                place.distanceFromUser = [[item valueForKey:@"distance"] doubleValue];
                                place.lat = [[item valueForKey:@"lat"] doubleValue];
                                place.lng = [[item valueForKey:@"lng"] doubleValue];
                                
                                [[self venues] addObject:place];
                            }   
                        }
                    }
                    
                    [SVProgressHUD dismiss];                    
                    [self.tableView reloadData];
                    
                }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *venueCellIdentifier = @"VenueListCustomCell";
    
    VenueCell *vcell = [tableView dequeueReusableCellWithIdentifier:venueCellIdentifier];
    
    if (vcell == nil) {
        vcell = [[VenueCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:venueCellIdentifier];
    }
    
    CPPlace *venue = [[self venues] objectAtIndex:indexPath.row];
    
    vcell.venueName.text = venue.name;
    vcell.venueAddress.text = venue.address;
    
    vcell.venueDistance.text = [NSString stringWithFormat:@"%@ %@", [CPUtils localizedDistanceStringFromMiles:venue.distanceFromUser], @"away"];
    
    vcell.venueCheckins.text = @"";
    if (venue.checkinCount  > 0) {
        if (venue.checkinCount == 1) {
            vcell.venueCheckins.text = @"1 person here now";
        } else {
            vcell.venueCheckins.text = [NSString stringWithFormat:@"%d people here now", venue.checkinCount];
        }
    } else {
        if (venue.weeklyCheckinCount > 0) {
            
            vcell.venueCheckins.text = [NSString stringWithFormat:venue.weeklyCheckinCount == 1 ? @"%d person this week" : @"%d people this week", venue.weeklyCheckinCount];
        } else {
            if (venue.monthlyCheckinCount > 0) {
                vcell.venueCheckins.text = [NSString stringWithFormat:venue.monthlyCheckinCount == 1 ? @"%d person this month" : @"%d people this week", venue.monthlyCheckinCount];
            } else {
                vcell.venueCheckins.text = @"";
            }                
        }
        
    }
    
    if (![venue.photoURL isKindOfClass:[NSNull class]]) {
        [vcell.venuePicture setImageWithURL:[NSURL URLWithString:venue.photoURL]
                           placeholderImage:[UIImage imageNamed:@"picture-coming-soon.jpg"]];
    } else {
        vcell.venuePicture.image = [UIImage imageNamed:@"picture-coming-soon.jpg"];
    }
    
    return vcell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 130;
}

# pragma mark - Table View Delegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // give place info to the CheckInDetailsViewController
    CPPlace *place = [[self venues] objectAtIndex:indexPath.row];
    
    VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    venueVC.venue = place;
    
    // push the VenueInfoViewController onto the screen
    [self.navigationController pushViewController:venueVC animated:YES];
}

@end
