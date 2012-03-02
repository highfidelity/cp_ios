//
//  MapTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "MapTabController.h"
#import "UIImageView+WebCache.h"
#import "MissionAnnotation.h"
#import "CPAnnotation.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "UserListTableViewController.h"
#import "SignupController.h"
#import "MapDataSet.h"
#import "CPUIHelper.h"
#import "UserProfileCheckedInViewController.h"
#import "OCAnnotation.h"
#import "UIImage+Resize.h"
#import "MKAnnotationView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

#define qHideTopNavigationBarOnMapView			0
#define kMinimumDeltaForSmallPins               0.15

@interface MapTabController() 
-(void)zoomTo:(CLLocationCoordinate2D)loc;

@property (nonatomic, strong) NSTimer *reloadTimer;

-(void)refreshLocationsIfNeeded;

@end

@implementation MapTabController 
@synthesize mapView;
@synthesize dataset;
@synthesize fullDataset;
@synthesize annotationsToRedisplay;
@synthesize reloadTimer;
@synthesize mapHasLoaded;
@synthesize mapAndButtonsView;

BOOL clusterNow = YES;
BOOL bigZoomLevelChange = NO;
BOOL zoomedIn = NO;
BOOL zoomedOut = NO;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.tag = mapTag;
    [AppDelegate instance].settingsMenuController.mapTabController = self;

    // Register to receive userCheckedIn notification to intitiate map refresh immediately after user checks in
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshLocationsAfterDelay) 
                                                 name:@"userCheckedIn" 
                                               object:nil];
    
    // Title view styling
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    self.navigationItem.title = @"C&P"; // TODO: Remove once back button with mug logo is added to pushed views
    
    
    self.mapHasLoaded = NO;

    // Initialize the fullDataset array to keep track of all checked in users, even outside of current map bounds
    fullDataset = [[MapDataSet alloc] init];
    annotationsToRedisplay = [[NSMutableSet alloc] init];
    
    self.navigationController.delegate = self;
	hasUpdatedUserLocation = false;
	
	// every 10 seconds, see if it's time to refresh the data
	// (the data invalidates every 2 minutes, but we check more often)

	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
												   target:self
												 selector:@selector(refreshLocationsIfNeeded)
												 userInfo:nil
												  repeats:YES];
    
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
    [super viewDidUnload];
	[reloadTimer invalidate];
	reloadTimer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userCheckedIn" object:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.mapHasLoaded = YES;
	// show the loading screen but only the first time
	if(!hasShownLoadingScreen)
	{
		[SVProgressHUD showWithStatus:@"Loading..."];
		hasShownLoadingScreen = true;
	}
    
    [[AppDelegate instance] showCheckInButton];

    [self refreshLocationsIfNeeded];
    
    // Update for login name in header field
    [[AppDelegate instance].settingsMenuController.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)refreshButtonClicked:(id)sender
{
    fullDataset = nil;    
    fullDataset = [[MapDataSet alloc] init];
    [self.mapView removeAllAnnotations];
    [self refreshLocations];
}

- (void)refreshLocationsAfterDelay
{
    [self refreshButtonClicked:nil];
}

-(void)refreshLocationsIfNeeded
{
    clusterNow = YES;
    
	MKMapRect mapRect = mapView.visibleMapRect;

    // If zoom level changed drastically, remove the previously clustered checkedOut pins
    if (bigZoomLevelChange) {
        for (id <MKAnnotation> annotation in mapView.annotations) {
            if ([annotation isKindOfClass:[OCAnnotation class]]) {
                OCAnnotation *thisAnnotation = (OCAnnotation *)annotation;
                
                if (!thisAnnotation.hasCheckins) {
                    [self.mapView removeAnnotation:annotation];
                }
            }
            
            if ([annotation isKindOfClass:[CPAnnotation class]]) {
                CPAnnotation *thisAnnotation = (CPAnnotation *)annotation;
                
                if (!thisAnnotation.checkedIn) {
//                    [fullDataset.annotations removeObject:annotation];
                    [self.mapView removeAnnotation:annotation];
                    [annotationsToRedisplay addObject:annotation];
                }
            }
        }
        
        bigZoomLevelChange = NO;
        [self.mapView doClustering];
    }
    
    // prevent the refresh of locations when we have a valid dataset or the map is not yet loaded
	if(self.mapHasLoaded && (!dataset || ![dataset isValidFor:mapRect]))
	{
		[self refreshLocations];
	}

    // Re-add any annotations in annotationsToRedisplay to get the correct pins after big zoom changes
    if (annotationsToRedisplay.count > 0) {
        for (CPAnnotation *ann in annotationsToRedisplay) {
            [mapView addAnnotation:ann];
        }
    
        [self.mapView doClustering];
        clusterNow = NO;
        [annotationsToRedisplay removeAllObjects];
    }

    if (clusterNow) {
        [self.mapView doClustering];
        clusterNow = NO;
    }
}

-(void)refreshLocations
{
    MKMapRect mapRect = mapView.visibleMapRect;
    [MapDataSet beginLoadingNewDataset:mapRect
                            completion:^(MapDataSet *newDataset, NSError *error) {
                                if(newDataset)
                                {
                                    NSSet *visiblePins = [mapView annotationsInMapRect: mapView.visibleMapRect];
                                    
                                    for (CPAnnotation *ann in visiblePins) {
                                        if ([[newDataset annotations] containsObject: ann]) {
                                            [[newDataset annotations] removeObject: ann];
                                        } else {
//                                            [mapView removeAnnotation:ann];
                                        }
                                    }
                                    
                                    dataset = newDataset;

                                    // Load all users (even outside of map bounds) into fullDataset for List view
                                    for (CPAnnotation *ann2 in newDataset.annotations) {
                                        if (![fullDataset.annotations containsObject: ann2]) {
                                            [fullDataset.annotations addObject: ann2];
                                            [mapView addAnnotation:ann2];
                                        }
                                    }
                                }
                                
                                [self.mapView doClustering];
                                clusterNow = NO;
                                
                                [SVProgressHUD dismiss];
                            }];    
}

- (IBAction)locateMe:(id)sender
{
    [self zoomTo: [[mapView userLocation] coordinate]];
}



- (IBAction)revealButtonPressed:(id)sender {
    SettingsMenuController *settingsMenuController = [AppDelegate instance].settingsMenuController;
    [settingsMenuController showMenu: !settingsMenuController.isMenuShowing];
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
	SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
}

-(void)logoutButtonTapped
{
	// logout of *all* accounts
	[[AppDelegate instance] logoutEverything];
	
}

- (void) mapView:(CPMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        CGFloat startingAlpha = view.alpha;

        // Fade in any new annotations
        view.alpha = 0;        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        view.alpha = startingAlpha;
        [UIView commitAnimations];
        
        // Bring any checked in pins to the front of all subviews
        if ([view.annotation isKindOfClass:[OCAnnotation class]]) {
            OCAnnotation *thisAnnotation = (OCAnnotation *)view.annotation;
            
            if (thisAnnotation.hasCheckins) {
                [[view superview] bringSubviewToFront:view];
            }
            else {
                [[view superview] sendSubviewToBack:view];                
            }
        }
        else {
            [[view superview] sendSubviewToBack:view];
        }
    }    
}

- (UIImage *)imageWithBorderFromImage:(UIImage*)source {
    CGSize size = [source size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0);
    CGContextStrokeRect(context, rect);
    UIImage *finalImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

- (UIImage *)pinImage:(NSMutableArray *)imageSources {
    // Re-order imageSources to first show non-empty images

    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCompare:)];
    imageSources = [[imageSources sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] copy];
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    CGFloat faceSize = 25;
    CGFloat rows;
    CGFloat columns;

    if (imageSources.count == 1) {
        rows = columns = 1;
    }
    else if (imageSources.count == 2) {
        columns = 2;
        rows = 1;
    }
    else {
//        columns = floor(imageSources.count / 2) + 1;
        columns = 2;
        rows = 2;
    }
    
    CGSize size = CGSizeMake(columns * faceSize, rows * faceSize);
    UIGraphicsBeginImageContext(size);

    for (NSInteger i = 0; i < imageSources.count; i++) {
        NSString *imageSource = [imageSources objectAtIndex:i];
        
        UIImage *image = nil;
        
        // Only show the first 3 faces and a + if more
        if (i == 3 && imageSources.count > 3) {
            image = [UIImage imageNamed:@"plusSign"];
        }
        else if (i < 3) {
            // If the passed imageSource is empty don't try to fetch it from the imageCache
            if (![imageSource isEqualToString:@"empty"]) {
                image = [manager imageWithURL:[NSURL URLWithString:imageSource]];                
            }
                        
            if (!image) {
                image = [UIImage imageNamed:@"defaultAvatar25"];
            }
        }
        else {
            break;
        }

        CGFloat x;
        CGFloat y;

        switch (i) {
            case 0:
                x = 0;
                y = 0;
                break;

            case 1:
                x = faceSize;
                y = 0;
                break;

            case 2:
                x = 0;
                y = faceSize;
                break;

            case 3:
                x = faceSize;
                y = faceSize;
                break;

            case 4:
                x = faceSize*2;
                y = 0;
                break;

            case 5:
                x = faceSize*2;
                y = faceSize;
                break;
                
            default:
                break;
        }

        // Resize any images that are larger than minSize
        if (image.size.width > faceSize || image.size.height > faceSize) {
            image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(faceSize, faceSize) interpolationQuality:kCGInterpolationLow];
        }

        image = [self imageWithBorderFromImage:image];
        
        CGPoint imagePoint = CGPointMake(x, y);
        [image drawAtPoint:imagePoint];
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(CPMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{   
	MKAnnotationView *pinToReturn = nil;
    BOOL hasCheckedInUsers = NO;
    BOOL smallPin = NO;
        
    if ([annotation isKindOfClass:[OCAnnotation class]]) {
        NSArray *annotationsInCluster = [(OCAnnotation *)annotation annotationsInCluster];
        NSMutableArray *imageSources = [[NSMutableArray alloc] initWithCapacity:annotationsInCluster.count];

        NSInteger checkedInUsers = 0;
        
        for (id <MKAnnotation> ann in annotationsInCluster) {
            if ([ann isKindOfClass:[CPAnnotation class]]) {
                CPAnnotation *thisAnn = (CPAnnotation *)ann;
                
                if (thisAnn.imageUrl) {
                    [imageSources addObject:thisAnn.imageUrl];
                }
                else {
                    [imageSources addObject:@"empty"];
                }
                
                if (thisAnn.checkedIn) {
                    checkedInUsers++;
                    hasCheckedInUsers = YES;
                }
            }
        }

        if (!hasCheckedInUsers) {
            if (annotationsInCluster.count < 5) {
                smallPin = YES;
            }
            else {
                smallPin = NO;
            }            
        }

        // If zoomed out, force the smallPin
//        if (self.mapView.region.span.longitudeDelta > kMinimumDeltaForSmallPins) {
//            smallPin = YES;
//        }
        
        // Need to set a unique identifier to prevent any weird formatting issues -- use a combination of annotationsInCluster.count + hasCheckedInUsers value + smallPin value
        NSString *reuseId = [NSString stringWithFormat:@"cluster-%d-%d-%d", (hasCheckedInUsers) ? checkedInUsers : imageSources.count, hasCheckedInUsers, smallPin];
        
        MKAnnotationView *pin = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];

        if (pin == nil)
		{
			pin = [[MKAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
		}
		else
		{
			pin.annotation = annotation;
		}

        if (hasCheckedInUsers) {
            [pin setNumberedPin:checkedInUsers hasCheckins:hasCheckedInUsers smallPin:NO];
        }
        else {           
            [pin setNumberedPin:imageSources.count hasCheckins:hasCheckedInUsers smallPin:smallPin];
        }
      
        pin.enabled = YES;
        pin.canShowCallout = YES;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		button.frame = CGRectMake(0, 0, 32, 32);
//		button.tag = [dataset.annotations indexOfObject:candpanno];
		pin.rightCalloutAccessoryView = button;
        pinToReturn = pin;

    }  
	else if ([annotation isKindOfClass:[CPAnnotation class]])
	{ 
		CPAnnotation *candpanno = (CPAnnotation*)annotation;
        NSString *reuseId;

        if (candpanno.checkedIn) {
            hasCheckedInUsers = YES;
        }

        [NSString stringWithFormat: @"pin-%d-%d", hasCheckedInUsers, 1];

        
		MKAnnotationView *pin = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
		if (pin == nil)
		{
			pin = [[MKAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
		}
		else
		{
			pin.annotation = annotation;
        }
        
        if (hasCheckedInUsers) {
            [pin setNumberedPin:1 hasCheckins:YES smallPin:NO];
        }
        else {
            [pin setNumberedPin:1 hasCheckins:NO smallPin:YES];            
        }
        
		pin.canShowCallout = YES;
		
		// make the left callout image view
//		UIImageView *leftCallout = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
//		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
//		if (candpanno.imageUrl)
//		{
//			[leftCallout setImageWithURL:[NSURL URLWithString:candpanno.imageUrl]
//                        placeholderImage:[UIImage imageNamed:@"63-runner"]];
//		}
//		else
//		{
//			leftCallout.image = [UIImage imageNamed:@"63-runner"];			
//		}
//		pin.leftCalloutAccessoryView = 	leftCallout;
		// make the right callout
		UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		button.frame = CGRectMake(0, 0, 32, 32);
		button.tag = [dataset.annotations indexOfObject:candpanno];
		pin.rightCalloutAccessoryView = button;
        
        pinToReturn = pin;
	}

    // Set up correct offset + callout offset for custom pin images
    
    pinToReturn.centerOffset = CGPointMake(0,-25);
    pinToReturn.calloutOffset = CGPointMake(0,0);
	
	return pinToReturn;
}

- (void)mapView:(CPMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {

    if ([view.annotation isKindOfClass:[OCAnnotation class]]) {
        
        for (OCAnnotation *ann in ((OCAnnotation *)[view annotation]).annotationsInCluster) {
//            NSLog(@"Found: %@", ann.title);
        }

      [self performSegueWithIdentifier:@"ShowUserClusterTable" sender:view];
    }
    else {
        [self performSegueWithIdentifier:@"ShowUserProfileCheckedInFromMap" sender:view];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    SettingsMenuController *settingsMenuController = [AppDelegate instance].settingsMenuController;
    if (settingsMenuController.isMenuShowing) { [settingsMenuController showMenu:NO]; }
    if ([[segue identifier] isEqualToString:@"ShowUserProfileCheckedInFromMap"]) {
        
        // setup a user object with the info we have from the pin and callout
        // so that this information can already be in the resume without having to load it
        User *selectedUser = [[User alloc] init];
        
        if ([sender isKindOfClass: [MKAnnotationView class]]) 
        {
            // figure out which element was tapped
            CPAnnotation *tappedObj = [sender annotation];
            
            selectedUser.nickname = tappedObj.nickname;
            selectedUser.userID = [tappedObj.objectId intValue];
            selectedUser.location = CLLocationCoordinate2DMake(tappedObj.lat, tappedObj.lon);
            selectedUser.status = tappedObj.status;
            selectedUser.skills = tappedObj.skills;
            selectedUser.checkedIn = tappedObj.checkedIn;
        } 
        else if ([sender isKindOfClass: [User class]])
        {
            selectedUser = sender;
        }
            
        
        // set the user object on the UserProfileCheckedInVC to the user we just created
        [[segue destinationViewController] setUser:selectedUser];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserListTable"]) {
        [[segue destinationViewController] setTitleForList: @"List"];
        [[segue destinationViewController] setListType:0];
        [[segue destinationViewController] setMissions: [fullDataset.annotations mutableCopy]];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserClusterTable"]) {
        OCAnnotation *tappedObj = [sender annotation];
        NSArray *annotations = tappedObj.annotationsInCluster;
        [[segue destinationViewController] setTitleForList: tappedObj.title];
        [[segue destinationViewController] setListType:1];
        [[segue destinationViewController] setMissions: [annotations mutableCopy]];
    }
}

////// map delegate

- (void)mapView:(CPMapView *)thisMapView regionDidChangeAnimated:(BOOL)animated
{   
    if (self.mapView.region.span.longitudeDelta > kMinimumDeltaForSmallPins) {
        zoomedIn = YES;
    }
    
    if (self.mapView.region.span.longitudeDelta < kMinimumDeltaForSmallPins) {
        zoomedOut = YES;
    }

    if (zoomedIn && zoomedOut && !bigZoomLevelChange) {
        bigZoomLevelChange = YES;
    }
    else {
        bigZoomLevelChange = NO;
    }

    if (self.mapView.region.span.longitudeDelta > kMinimumDeltaForSmallPins) {
        zoomedOut = NO;
    }
    
    if (self.mapView.region.span.longitudeDelta < kMinimumDeltaForSmallPins) {
        zoomedIn = NO;
    }

	[self refreshLocationsIfNeeded];
}

- (void)mapViewWillStartLocatingUser:(CPMapView *)mapView
{
	NSLog(@"mapViewWillStartLocatingUser");
}

- (void)mapViewDidStopLocatingUser:(CPMapView *)mapView
{
	NSLog(@"mapViewDidStopLocatingUser");
	
}
- (void)mapView:(CPMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
//	NSLog(@"MapTab: didUpdateUserLocation (lat %f, lon %f)",
//          userLocation.location.coordinate.latitude,
//          userLocation.location.coordinate.longitude);
	
	if(userLocation.location.coordinate.latitude != 0 &&
       userLocation.location.coordinate.longitude != 0)
	{
		// save the location for the next time
		[AppDelegate instance].settings.hasLocation= true;
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
- (void)mapView:(CPMapView *)mapView didFailToLocateUserWithError:(NSError *)error
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

@end
