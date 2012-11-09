//
//  MapTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "MKAnnotationView+SpecialPin.h"
#import "VenueInfoViewController.h"
#import "CPUser.h"
#import "CPObjectManager.h"
#import "CPMarkerManager.h"

@interface MapTabController()
-(void)zoomTo:(CLLocationCoordinate2D)loc;

@property (strong, nonatomic) NSTimer *reloadTimer;
@property (strong, nonatomic) NSTimer *locationAllowTimer;
@property (strong, nonatomic) NSTimer *arrowSpinTimer;
@property (strong, nonatomic) NSDate *dataLoadDate;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (nonatomic) BOOL locationStatusKnown;
@property (nonatomic) MKMapRect dataCoveredMapRect;

-(void)refreshLocationsIfNeeded;
-(void)startRefreshArrowAnimation;
-(void)stopRefreshArrowAnimation;
-(void)checkIfUserHasDismissedLocationAlert;
@end

@implementation MapTabController

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // Reload all pins when the app comes back into the foreground
    [self refreshButtonClicked:nil];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.tag = mapTag;
    
    // Register to receive userCheckedIn notification to intitiate map refresh immediately after user checks in
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userCheckedIn:)
                                                 name:@"userCheckInStateChange"
                                               object:nil];
    
    // Add a notification catcher for applicationDidBecomeActive to refresh map pins
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:@"applicationDidBecomeActive"
                                               object:nil];
    
    self.mapHasLoaded = NO;
    
	self.hasUpdatedUserLocation = false;
    
	// let's assume when this view loads we don't know the location status
    // this is switched in checkIfUserHasDismissedLocationAlert
    self.locationStatusKnown = NO;
    
    // fire a timer every two seconds to make sure the user has explicity denied or allowed location
    // this allows us to not start loading the data until the user has dismiss the alert the OS puts up
    
    self.locationAllowTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                               target:self
                                                             selector:@selector(checkIfUserHasDismissedLocationAlert)
                                                             userInfo:nil
                                                              repeats:YES];
    // check this already since we don't want a lag time if this step has already been completed
    [self checkIfUserHasDismissedLocationAlert];
    
    // center on the last known user location
	[self zoomTo:[CPAppDelegate locationManager].location.coordinate];
    
	NSOperationQueue *queue = [NSOperationQueue mainQueue];
	//NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	//BOOL wasSuspended = queue.isSuspended;
	[queue setSuspended: NO];
    
    // Drop shadow under navigation bar
    UIImageView *shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-shadow.png"]];
    shadowView.frame = CGRectMake(0,
                                  0,
                                  self.view.frame.size.width,
                                  shadowView.frame.size.height);
    [self.view addSubview:shadowView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self.reloadTimer invalidate];
	self.reloadTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userCheckInStateChange" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationDidBecomeActive" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.mapHasLoaded = YES;
    
    // Update for login name in header field
    [[CPAppDelegate settingsMenuController].tableView reloadData];
    
    // Refresh all locations when view will re-appear after being in another area of the app; don't do it on the first launch though
    if (self.locationStatusKnown) {
        [self refreshButtonClicked:nil];
    }
}

- (void)userCheckedIn:(NSNotification *)notification
{
    [self refreshButtonClicked:notification];
}

- (IBAction)refreshButtonClicked:(id)sender
{
    [self refreshLocations:nil];
}

- (CLLocationCoordinate2D)northeastCoordinateForMapView
{
    return [self.mapView convertPoint:CGPointMake(self.mapView.bounds.origin.x + self.mapView.bounds.size.width,
                                                  self.mapView.bounds.origin.y) toCoordinateFromView:self.mapView];
}

- (CLLocationCoordinate2D)southwestCoordinateForMapView
{
    return [self.mapView convertPoint:CGPointMake(self.mapView.bounds.origin.x,
                                                  self.mapView.bounds.origin.y + self.mapView.bounds.size.height) toCoordinateFromView:self.mapView];
}

-(BOOL)isCurrentMarkerDataStillValid
{
	const double kTwoMinutesAgo = -2 * 60;
	
	// if the data is old, we need to reload anyway
	double age = [self.dataLoadDate timeIntervalSinceNow];
	
    if(self.dataLoadDate && age < kTwoMinutesAgo) {
		NSLog(@"Forcing refresh of map data ... it's too old (%.2f seconds old)", age);
		return false;
	}
    
	// if the new map region is contained within the region defined by the venues that are the furthest away
    // then we don't need to reload
	if(MKMapRectContainsRect(self.dataCoveredMapRect, self.mapView.visibleMapRect)) {
		return true;
    } else {
		return false;
	}
}

-(void)refreshLocationsIfNeeded
{
    // prevent the refresh of locations when we have a valid dataset or the map is not yet loaded
    if(self.locationStatusKnown && self.mapHasLoaded && (![CPMarkerManager sharedManager].venues || ![self isCurrentMarkerDataStillValid])) {
        [self refreshLocations:nil];
    }
}

-(void)refreshLocations:(void (^)(void))completion
{
    // cancel any current requests for new map data or active users for venues
    RKRoute *markerRoute = [[CPObjectManager sharedManager].router.routeSet routeForName:kRouteMarkers];
    RKRoute *venueCheckedInRoute = [[CPObjectManager sharedManager].router.routeSet routeForName:kRouteVenueCheckedInUsers];
    [[CPObjectManager sharedManager] cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:markerRoute.pathPattern];
    [[CPObjectManager sharedManager] cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:venueCheckedInRoute.pathPattern];
    
    [self startRefreshArrowAnimation];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"mapIsLoadingNewData" object:nil];
    
    MKMapRect mapRectForRequest = self.mapView.visibleMapRect;
        
    [[CPMarkerManager sharedManager] getMarkersWithinRegionDefinedByNortheastCoordinate:[self northeastCoordinateForMapView]
                                                                    southwestCoordinate:[self southwestCoordinateForMapView]
                                                                             completion:^(NSError *error)
     {
         self.dataLoadDate = [NSDate date];
         self.dataCoveredMapRect = mapRectForRequest;
         
         if (completion) {
             completion();
         }
         
         NSMutableArray *filteredVenues = [[[CPMarkerManager sharedManager].venues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isNeighborhood == NO"]] mutableCopy];
         
         for (CPVenue *newVenue in [filteredVenues mutableCopy]) {
             if ([self.mapView.annotations containsObject:newVenue]) {
                 
                 CPVenue *mapVenue = [self.mapView.annotations objectAtIndex:[self.mapView.annotations indexOfObject:newVenue]];
                 
                 if (![newVenue.checkedInNow isEqualToNumber:mapVenue.checkedInNow] || ![newVenue.weeklyCheckinCount isEqualToNumber:mapVenue.weeklyCheckinCount]) {
                     // the annotation will be added again
                     [self.mapView removeAnnotation:mapVenue];
                 } else {
                     // no update to the annotation is required
                     [filteredVenues removeObject:newVenue];
                 }
             }
         }
         
         // add modified dataset to map - new/updated annotations
         [self.mapView addAnnotations:filteredVenues];
         
         // stop spinning the refresh icon and dismiss the HUD
         [self stopRefreshArrowAnimation];
         
         // only try to dismiss the SVProgressHUD if this view is on screen
         // so that the places and venue tabs can dismiss their own ProgressHUDs
         
         if (self.isViewLoaded && self.view.window) {
             [SVProgressHUD dismiss];
         }
     }];
}

- (IBAction)locateMe:(id)sender
{
    if (![CLLocationManager locationServicesEnabled] ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        
        NSString *message = @"We're unable to get your location and the application relies on it.\n\nPlease go to your settings and enable location for the Workclub app.";
        [SVProgressHUD showErrorWithStatus:message
                                  duration:kDefaultDismissDelay];
    } else {
        // we have a location ... zoom to it
        [self zoomTo: [[self.mapView userLocation] coordinate]];
    }
}

- (MKUserLocation *)currentUserLocationInMapView
{
    return self.mapView.userLocation;
}

- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        CGFloat startingAlpha = view.alpha;
        
        // Fade in any new annotations
        view.alpha = 0;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        view.alpha = startingAlpha;
        [UIView commitAnimations];
        
        if (![view.annotation isKindOfClass:[CPVenue class]]) {
            [[view superview] sendSubviewToBack:view];
        }
    }
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *pinToReturn = nil;
    
    if ([annotation isKindOfClass:[CPVenue class]]) {
        CPVenue *placeAnn = (CPVenue *)annotation;
        
        // Need to set a unique identifier to prevent any weird formatting issues -- use a combination of annotationsInCluster.count + hasCheckedInUsers value + smallPin value
        // @TODO: comment above is now invalid, identifier below is not going to be unique. why not use the foursquare id, or venue id? -- lithium
        NSString *reuseId = [NSString stringWithFormat:@"place-%@-%d", ([placeAnn.checkedInNow intValue] > 0) ? placeAnn.checkedInNow : placeAnn.weeklyCheckinCount,
                             ([placeAnn.checkedInNow intValue] > 0)];
        
        MKAnnotationView *pin = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
        
        if (!pin)
        {
            pin = [[MKAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
        }
        else
        {
            pin.annotation = annotation;
        }
        
        BOOL solar = [placeAnn.specialVenueType isEqual:@"solar"];
        
        if ([placeAnn.checkedInNow intValue] == 0) {
            [pin setPin:placeAnn.weeklyCheckinCount hasCheckins:NO hasContacts:NO isSolar:solar withLabel:NO];
            [self adjustScaleForPin:pin forNumberOfPeople:placeAnn.weeklyCheckinCount];
        }
        else {
            [pin setPin:placeAnn.checkedInNow hasCheckins:YES hasContacts:[placeAnn.hasCheckedInContacts boolValue] isSolar:solar withLabel:YES];
            pin.centerOffset = CGPointMake(0, -31);
        }
        
        pin.enabled = YES;
        pin.canShowCallout = YES;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        button.frame = CGRectMake(0, 0, 32, 32);
        //      button.tag = [dataset.annotations indexOfObject:candpanno];
        pin.rightCalloutAccessoryView = button;
        pinToReturn = pin;
        
        // Set up correct callout offset for custom pin images
        pinToReturn.calloutOffset = CGPointMake(0,0);
        
    }
    return pinToReturn;
}

- (float)getPinScaleForNumberOfPeople:(NSInteger)number {
    if (!self.pinScales) {
        self.pinScales = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.31f],   // for 1 person
                          [NSNumber numberWithFloat:0.57f],
                          [NSNumber numberWithFloat:0.74f],
                          [NSNumber numberWithFloat:0.855f],
                          [NSNumber numberWithFloat:0.932f],
                          [NSNumber numberWithFloat:0.976f],
                          [NSNumber numberWithFloat:1.0f],   // for 7 or more people
                          nil];
    }
    
    if (number <= 0) {
        return [[self.pinScales objectAtIndex:0] floatValue];
    } else if (number >= [self.pinScales count]) {
        return [[self.pinScales objectAtIndex:[self.pinScales count] - 1] floatValue];
    } else {
        return [[self.pinScales objectAtIndex:number - 1] floatValue];
    }
    
}

- (void)adjustScaleForPin:(MKAnnotationView *)pin forNumberOfPeople:(NSNumber *)number {
    if (pin.image) {
        float scale = [self getPinScaleForNumberOfPeople:[number intValue]];
        
        // can't simply adjust the pin's transform since that will also scale the callout bubble
        // TODO: if we want to keep the pin touch area the same, we should only scale the image instead
        CGRect newFrame = CGRectMake(0, 0, roundf(pin.image.size.width * scale), roundf(pin.image.size.height * scale));
        [pin setFrame:newFrame];
        [pin setCenterOffset: CGPointMake(0, - roundf(newFrame.size.height / 2.4f))];
    }
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    if ([view.annotation isKindOfClass:[CPVenue class]]) {
        CPVenue *tappedPlace = (CPVenue *)view.annotation;
        
        VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        venueVC.venue = tappedPlace;
        
        // back button should say map and not C&P for this transition
        UIBarButtonItem *backButton = [[ UIBarButtonItem alloc] init];
        backButton.title = @"Map";
        self.navigationItem.backBarButtonItem = backButton;
        
        // push the VenueInfoViewController onto the screen
        [self.navigationController pushViewController:venueVC animated:YES];
    }
}

- (void)mapView:(MKMapView *)thisMapView regionDidChangeAnimated:(BOOL)animated
{
    // bring any checked-in venues to the front of all subviews.
    for (CPVenue *ann in [self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self isKindOfClass: %@)", [CPVenue class]]]) {
        MKAnnotationView *annView = [thisMapView viewForAnnotation:ann];
        if (annView) {
            if ([ann.checkedInNow intValue]> 0) {
                [[annView superview] bringSubviewToFront:annView];
            }
            else {
                [[annView superview] sendSubviewToBack:annView];
            }
        }
    }
    
    [self refreshLocationsIfNeeded];
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
	NSLog(@"mapViewWillStartLocatingUser");
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
	NSLog(@"mapViewDidStopLocatingUser");
	
}
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	
	if(userLocation.location.coordinate.latitude != 0 &&
       userLocation.location.coordinate.longitude != 0)
	{
        if (!self.hasUpdatedUserLocation) {
            NSLog(@"MapTab: didUpdateUserLocation a zoomto (lat %f, lon %f)",
                  userLocation.location.coordinate.latitude,
                  userLocation.location.coordinate.longitude);
            [self zoomTo:userLocation.location.coordinate];
            self.hasUpdatedUserLocation = true;
        }
        
	}
}

// zoom to the location; on initial load & after updaing their pos
-(void)zoomTo:(CLLocationCoordinate2D)loc
{
    
    if(CLLocationCoordinate2DIsValid(loc))
    {
        // zoom to a region 2km across
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000);
        [self.mapView setRegion:viewRegion animated:TRUE];
    }
    else {
#if DEBUG
        NSLog(@"Received Invalid Coordinate, not zooming");
#endif
    }
}

// check if the user has either explicitly allowed or denied the use of their location
- (void)checkIfUserHasDismissedLocationAlert
{
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) {
        
#if DEBUG
        NSLog(@"We have a location authorization status. We will now refresh data.");
#endif
        
        // we know we either will or won't be getting user location so load the datapoints
        // set the locationStatusKnown boolean to yes so we know we can reload data
        self.locationStatusKnown = YES;
        
        // refresh the locations now
        [self refreshLocationsIfNeeded];
        
        // every 10 seconds, see if it's time to refresh the data
        // (the data invalidates every 2 minutes, but we check more often)
        
        self.reloadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                            target:self
                                                          selector:@selector(refreshLocationsIfNeeded)
                                                          userInfo:nil
                                                           repeats:YES];
        
        
        // invalidate this timer so its done
        [self.locationAllowTimer invalidate];
        self.locationAllowTimer = nil;
    }
}

- (void)spinRefreshArrow
{
    [CPUIHelper spinView:self.refreshButton.imageView
                duration:1.0f
             repeatCount:0
               clockwise:NO
          timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
}

- (void)startRefreshArrowAnimation
{
    // invalidate the old timer if it exists
    [self.arrowSpinTimer invalidate];
    
    // spin the arrow
    [self spinRefreshArrow];
    // start a timer to keep spinning it
    self.arrowSpinTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(spinRefreshArrow) userInfo:nil repeats:YES];
}

- (void)stopRefreshArrowAnimation
{
    // stop the timer so the arrow stops spinning after the rotation completes
    [self.arrowSpinTimer invalidate];
    self.arrowSpinTimer = nil;
}

@end
