//
//  MapTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "MapDataSet.h"
#import "MKAnnotationView+WebCache.h"
#import "VenueInfoViewController.h"

#define qHideTopNavigationBarOnMapView			0
#define kCheckinThresholdForSmallPin            2

@interface MapTabController() 
-(void)zoomTo:(CLLocationCoordinate2D)loc;

@property (nonatomic, strong) NSTimer *reloadTimer;
@property (nonatomic, strong) NSTimer *locationAllowTimer;
@property (nonatomic, strong) NSTimer *arrowSpinTimer;
@property (nonatomic, assign) BOOL locationStatusKnown;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

-(void)refreshLocationsIfNeeded;
-(void)startRefreshArrowAnimation;
-(void)stopRefreshArrowAnimation;
-(void)checkIfUserHasDismissedLocationAlert;
@end

@implementation MapTabController
@synthesize mapView;
@synthesize dataset;
@synthesize reloadTimer;
@synthesize arrowSpinTimer;
@synthesize mapHasLoaded;
@synthesize mapAndButtonsView;
@synthesize locationAllowTimer;
@synthesize locationStatusKnown;
@synthesize refreshButton;

BOOL clearLocations = NO;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // Reload all pins when the app comes back into the foreground
    [self refreshButtonClicked:nil];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.tag = mapTag;
    [AppDelegate instance].settingsMenuController.mapTabController = self;

    // Register to receive userCheckedIn notification to intitiate map refresh immediately after user checks in
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshButtonClicked:) 
                                                 name:@"userCheckedIn" 
                                               object:nil];

    // Add a notification catcher for applicationDidBecomeActive to refresh map pins
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(applicationDidBecomeActive:) 
                                                 name:@"applicationDidBecomeActive" 
                                               object:nil];
    
    // Title view styling
    self.navigationItem.title = @"C&P"; // TODO: Remove once back button with mug logo is added to pushed views
    
    self.mapHasLoaded = NO;
    
    self.navigationController.delegate = self;
	hasUpdatedUserLocation = false;
    
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
	if([AppDelegate instance].settings.hasLocation)
	{
		//[mapView setCenterCoordinate:[AppDelegate instance].settings.lastKnownLocation.coordinate];
		NSLog(@"MapTab: viewDidLoad zoomto (lat %f, lon %f)", [AppDelegate instance].settings.lastKnownLocation.coordinate.latitude, [AppDelegate instance].settings.lastKnownLocation.coordinate.longitude);
		[self zoomTo: [AppDelegate instance].settings.lastKnownLocation.coordinate];
	}

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
	[self setMapView:nil];
    [self setMapAndButtonsView:nil];
    [self setRefreshButton:nil];
    [super viewDidUnload];
	[reloadTimer invalidate];
	reloadTimer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userCheckedIn" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationDidBecomeActive" object:nil];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
    
    // Refresh all locations when view will re-appear after being in another area of the app; don't do it on the first launch though
    
    if (hasShownLoadingScreen) {
        [self refreshLocationsAfterDelay];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.mapHasLoaded = YES;

    // Update for login name in header field
    [[AppDelegate instance].settingsMenuController.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)refreshButtonClicked:(id)sender
{
    clearLocations = NO;
    [self refreshLocations];
}

- (void)refreshLocationsAfterDelay
{
    [self refreshButtonClicked:nil];
}

-(void)refreshLocationsIfNeeded
{
    
    if (locationStatusKnown) {
        
        MKMapRect mapRect = mapView.visibleMapRect;
        
        // prevent the refresh of locations when we have a valid dataset or the map is not yet loaded
        if(self.mapHasLoaded && (!dataset || ![dataset isValidFor:mapRect]))
        {
            [self refreshLocations];
        }
    }
}

-(void)refreshLocations
{
    [self startRefreshArrowAnimation];
    MKMapRect mapRect = mapView.visibleMapRect;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"mapIsLoadingNewData" object:nil];
    [MapDataSet beginLoadingNewDataset:mapRect
                            completion:^(MapDataSet *newDataset, NSError *error) {

                                if (clearLocations) {
                                    
                                    // clear other than current user location
                                    for (id annotation in mapView.annotations) {
                                        if ([annotation isKindOfClass:[CPPlace class]]) {
                                            [self.mapView removeAnnotation:annotation];
                                        }
                                    }                             
                                }

                                NSMutableArray *annotationsToAdd = [[NSMutableArray alloc] initWithArray:newDataset.annotations];
                                
                                if(newDataset)
                                {
                                    dataset = newDataset;
                                    
                                    NSSet *visiblePins = [mapView annotationsInMapRect: mapView.visibleMapRect];
                                    BOOL foundIt = NO;

                                    for (CPPlace *ann in visiblePins) {
                                        foundIt = NO;                                            
                                        for (CPPlace *newAnn in newDataset.annotations) {
                                            if ([ann.foursquareID isEqualToString:newAnn.foursquareID]) {
                                                foundIt = YES;
                                                if (ann.checkinCount != newAnn.checkinCount || ann.weeklyCheckinCount != newAnn.weeklyCheckinCount) {
                                                    // the annotation will be added again
                                                    [mapView removeAnnotation:ann];
                                                } else {
                                                    // no update to the annotation is required
                                                    [annotationsToAdd removeObject:newAnn];
                                                }
                                                break;
                                            }
                                        }
                                        
                                        if (! foundIt) {
                                            // this is causing problems, commenting out for now
                                            // [mapView removeAnnotation:ann];
                                        }
                                        
                                    }
                                }
                                
                                // add modified dataset to map - new/updated annotations
                                [mapView addAnnotations:annotationsToAdd];                                
                            
                                // stop spinning the refresh icon and dismiss the HUD
                                [self stopRefreshArrowAnimation];
                                
                                // only try to dismiss the SVProgressHUD if this view is on screen
                                // so that the places and venue tabs can dismiss their own ProgressHUDs
                                
                                if (self.isViewLoaded && self.view.window) {
                                   [SVProgressHUD dismiss];
                                }
                                
                                // post two notifications for places and people reload
                                // both send non-mutable copies of the data
                                // it's up to that view controller to make a mutable copy that it can modify so that it doesn't directly touch the dataset
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshUsersFromNewMapData" object:dataset.activeUsers];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVenuesFromNewMapData" object:[NSArray arrayWithArray:dataset.annotations]];
                            }]; 
}

- (IBAction)locateMe:(id)sender
{
    if (![CLLocationManager locationServicesEnabled] || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        
        NSString *message = @"We're unable to get your location and the application relies on it.\n\nPlease go to your settings and enable location for the C&P app.";
        
        // show an alert to the user if location services are disabled
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Can't find you!" 
                                                            message:message
                                                           delegate:self 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        // we have a location ... zoom to it
        [self zoomTo: [[mapView userLocation] coordinate]];
    }    
}

- (MKUserLocation *)currentUserLocationInMapView
{
    return mapView.userLocation;
}

// called just before a controller pops us
- (void)navigationController:(UINavigationController *)navigationControllerArg willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
#if qHideTopNavigationBarOnMapView
	if(viewController == self)
	{
		// we're about to be revealed
		// (happens after a pop back, but also on initial appearance)
		navigationControllerArg.navigationBarHidden = YES;
	}
	else
	{
		navigationControllerArg.navigationBarHidden = NO;
	}
#endif
	
}

-(void)loginButtonTapped
{
	[CPAppDelegate showSignupModalFromViewController:self animated:YES];
}

-(void)logoutButtonTapped
{
	// logout of *all* accounts
	[[AppDelegate instance] logoutEverything];
	
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
        
        if ([view.annotation isKindOfClass:[CPPlace class]]) {
            // Bring any checked in pins to the front of all subviews
            CPPlace *place = (CPPlace *)view.annotation;
            
            if (place.checkinCount > 0) {
                [[view superview] bringSubviewToFront:view];
            }
            else {
                [[view superview] sendSubviewToBack:view];                
            }
        } else {
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
    BOOL smallPin = NO;
    
    if ([annotation isKindOfClass:[CPPlace class]]) {
        CPPlace *placeAnn = (CPPlace *)annotation;
        
        // Need to set a unique identifier to prevent any weird formatting issues -- use a combination of annotationsInCluster.count + hasCheckedInUsers value + smallPin value
        // @TODO: comment above is now invalid, identifier below is not going to be unique. why not use the foursquare id, or venue id? -- lithium
        NSString *reuseId = [NSString stringWithFormat:@"place-%d-%d", (placeAnn.checkinCount > 0) ? placeAnn.checkinCount : placeAnn.weeklyCheckinCount, (placeAnn.checkinCount > 0)];
        
        MKAnnotationView *pin = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
        
        if (pin == nil)
        {
            pin = [[MKAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
        }
        else
        {
            pin.annotation = annotation;
        }
        
        if (!placeAnn.checkinCount > 0) {
            if (placeAnn.weeklyCheckinCount < kCheckinThresholdForSmallPin) {
                smallPin = YES;
                [pin setPin:placeAnn.weeklyCheckinCount hasCheckins:NO smallPin:smallPin withLabel:NO];
            }
            else {
                smallPin = NO;
                [pin setPin:placeAnn.weeklyCheckinCount hasCheckins:NO smallPin:smallPin withLabel:NO];
                pin.centerOffset = CGPointMake(0, -18);
            }            
        } 
        else {
            [pin setPin:placeAnn.checkinCount hasCheckins:YES smallPin:smallPin withLabel:YES];
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {

    if ([view.annotation isKindOfClass:[CPPlace class]]) {
        CPPlace *tappedPlace = (CPPlace *)view.annotation;
        
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

////// map delegate

- (void)mapView:(MKMapView *)thisMapView regionDidChangeAnimated:(BOOL)animated
{   
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
//	NSLog(@"MapTab: didUpdateUserLocation (lat %f, lon %f)",
//          userLocation.location.coordinate.latitude,
//          userLocation.location.coordinate.longitude);
	
	if(userLocation.location.coordinate.latitude != 0 &&
       userLocation.location.coordinate.longitude != 0)
	{
		// save the location for the next time
		[AppDelegate instance].settings.hasLocation = true;
		[AppDelegate instance].settings.lastKnownLocation = userLocation.location;
		[[AppDelegate instance] saveSettings];
		
        if (!hasUpdatedUserLocation) {
            NSLog(@"MapTab: didUpdateUserLocation a zoomto (lat %f, lon %f)",
                  userLocation.location.coordinate.latitude,
                  userLocation.location.coordinate.longitude);
            [self zoomTo:userLocation.location.coordinate];   
            hasUpdatedUserLocation = true;
        }

	}
}
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
	[SVProgressHUD dismiss];
}

// zoom to the location; on initial load & after updaing their pos
-(void)zoomTo:(CLLocationCoordinate2D)loc
{
    // zoom to a region 2km across
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000);
    [mapView setRegion:viewRegion animated:TRUE];    
}

// check if the user has either explicitly allowed or denied the use of their location
- (void)checkIfUserHasDismissedLocationAlert
{
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) {
        
#if DEBUG
        NSLog(@"We have a location authorization status. We will now refresh data.");
#endif
        
        // we know we either will or won't be getting user location so load the datapoints
        
        // show the loading screen but only the first time
        if(!hasShownLoadingScreen)
        {
            [SVProgressHUD showWithStatus:@"Loading..."];
            hasShownLoadingScreen = YES;
        }
        
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
