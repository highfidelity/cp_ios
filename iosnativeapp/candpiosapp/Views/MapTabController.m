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
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "UserListTableViewController.h"
#import "SignupController.h"
#import "MapDataSet.h"
#import "UserProfileCheckedInViewController.h"
#import "ClusterAnnotation.h"

#define qHideTopNavigationBarOnMapView			0

@interface MapTabController()
-(void)zoomTo:(CLLocationCoordinate2D)loc;
-(void)updateLoginButton;

-(void)accessoryButtonTapped:(UIButton*)sender;
@property (nonatomic, strong) NSTimer *reloadTimer;
-(void)refreshLocationsIfNeeded;

@end

@implementation MapTabController
@synthesize mapView;
@synthesize dataset;
@synthesize reloadTimer;
@synthesize mapHasLoaded;


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


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapHasLoaded = NO;

    self.navigationController.delegate = self;
	hasUpdatedUserLocation = false;
	
	// every 10 seconds, see if it's time to refresh the data
	// (the data invalidates every 2 minutes, but we check more often)
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
												   target:self
												 selector:@selector(refreshLocationsIfNeeded)
												 userInfo:nil
												  repeats:YES];
		
	if([AppDelegate instance].settings.candpUserId ||
	   [[AppDelegate instance].facebook isSessionValid])
	{
		self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc]initWithTitle:@"Logout"
																				  style:UIBarButtonItemStylePlain
																				 target:self 
																				 action:@selector(logoutButtonTapped)];
		
		self.navigationItem.title = [AppDelegate instance].settings.userNickname;
	}
	else
	{
		self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc]initWithTitle:@"Login..."
																				  style:UIBarButtonItemStylePlain
																				 target:self 
																				 action:@selector(loginButtonTapped)];
        
		self.navigationItem.title = @"C&P";
	}

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
}

- (void)viewDidUnload
{
	[self setMapView:nil];
    [super viewDidUnload];
	[reloadTimer invalidate];
	reloadTimer = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
	
	[self updateLoginButton];    
    [self refreshLocationsIfNeeded];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)refreshButtonClicked:(id)sender
{
    [mapView removeAnnotations: mapView.annotations];
    [self refreshLocations];
}

-(void)refreshLocationsIfNeeded
{
	MKMapRect mapRect = mapView.visibleMapRect;

    // prevent the refresh of locations when we have a valid dataset or the map is not yet loaded
	if(self.mapHasLoaded && (!dataset || ![dataset isValidFor:mapRect]))
	{
		[self refreshLocations];
	}
}

-(void)refreshLocations
{
    MKMapRect mapRect = mapView.visibleMapRect;
    [MapDataSet beginLoadingNewDataset:mapRect
                            completion:^(MapDataSet *newDataset, NSError *error) {
                                if(newDataset)
                                {
                                    NSSet *visiblePins = [mapView 
                                                          annotationsInMapRect: mapView.visibleMapRect];
                                    
                                    NSLog(@"Visible pins: %d", [visiblePins count]);

                                    for (CandPAnnotation *ann in visiblePins) {
                                        if ([ann isKindOfClass: [OCAnnotation class]]) {
                                            [mapView removeAnnotation: ann];
                                            
                                        }
                                    }
                                    
                                    for (CandPAnnotation *ann in visiblePins) {
                                        if ([[newDataset annotations] containsObject: ann]) {
                                            [[newDataset annotations] removeObject: ann];
                                        } else {
                                            [mapView removeAnnotation:ann];
                                        }
                                    }
                                    
                                    [mapView addAnnotations: [newDataset annotations]];
                                    dataset = newDataset;
                                }
                                
                                [SVProgressHUD dismiss];
                            }];
    
}

- (IBAction)locateMe:(id)sender
{
    [self zoomTo: [[mapView userLocation] coordinate]];
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
	[self updateLoginButton];
	
}
-(void)updateLoginButton
{	
	if([AppDelegate instance].settings.candpUserId)
	{
		self.navigationItem.rightBarButtonItem.title = @"Logout";
		self.navigationItem.rightBarButtonItem.action = @selector(logoutButtonTapped);
		self.navigationItem.title = [AppDelegate instance].settings.userNickname;
	}
	else
	{	
		self.navigationItem.rightBarButtonItem.title = @"Login...";
		self.navigationItem.rightBarButtonItem.action = @selector(loginButtonTapped);
		self.navigationItem.title = @"C&P";
	}
	
}

- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        if ([[view annotation] isKindOfClass:[CandPAnnotation class]]) {
            CandPAnnotation *ann = (CandPAnnotation *)view.annotation;
            if (ann.checkedIn) {   
                [[view superview] bringSubviewToFront:view];
            } else {
                [[view superview] sendSubviewToBack:view];
            }
        }
    }
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[OCAnnotation class]]) {
        
        OCAnnotation *clusterAnnotation = (OCAnnotation *)annotation;
        NSString *reuseId = @"cluster-pin";
		ClusterAnnotation *pin = (ClusterAnnotation *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
        if (!pin) {
            pin = [[ClusterAnnotation alloc] initWithAnnotation:annotation reuseIdentifier: reuseId];
            pin.image = [UIImage imageNamed:@"cluster.png"];
        }
        [pin setClusterText: [NSString stringWithFormat:@"%d", [clusterAnnotation.annotationsInCluster count]]];
        return pin;
    }
    
	MKAnnotationView *pinToReturn = nil;
	if([annotation isKindOfClass:[CandPAnnotation class]])
	{ 
		CandPAnnotation *candpanno = (CandPAnnotation*)annotation;
        NSString *reuseId = [NSString stringWithFormat: @"pin-%d", candpanno.checkinId];

		if (!candpanno.checkedIn) 
		{
            reuseId = @"pin";
        }
        
		MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: reuseId];
		if (pin == nil)
		{
			pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: reuseId];
		}
		else
		{
			pin.annotation = annotation;
		}
		pinToReturn = pin;
        
		if (candpanno.checkedIn) 
		{
			UIImage *pinImage;
            if (candpanno.imageUrl == nil)
			{
				pinImage = [UIImage imageNamed:@"defaultAvatar50.png"];
			} 
			else 
			{
				UIImage *frame = [UIImage imageNamed:@"pin-frame"];
				UIImage *profileImage  = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: candpanno.imageUrl]]];
                
				UIGraphicsBeginImageContext(CGSizeMake(38, 43));
				[profileImage drawInRect:CGRectMake(3, 3, 32, 32)];
				[frame drawInRect: CGRectMake(0, 0, 38, 43)];
				pinImage = UIGraphicsGetImageFromCurrentImageContext();
			}
            
			pin.image = pinImage;
		} 
		else
		{
			pin.pinColor = MKPinAnnotationColorRed;
		}
        
		pin.animatesDrop = NO;
		pin.canShowCallout = YES;
		
		// make the left callout image view
		UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
		
		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
		if(candpanno.imageUrl)
		{
			[leftCallout setImageWithURL:[NSURL URLWithString:candpanno.imageUrl]
						   placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
		}
		else
		{
			leftCallout.image = [UIImage imageNamed:@"63-runner.png"];			
		}
		pin.leftCalloutAccessoryView = 	leftCallout;
		// make the right callout
		UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		button.frame =CGRectMake(0, 0, 32, 32);
		button.tag = [dataset.annotations indexOfObject:candpanno];
		pin.rightCalloutAccessoryView = button;
	}
	
	return pinToReturn;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"ShowUserProfileCheckedInFromMap" sender:view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([[segue identifier] isEqualToString:@"ShowUserProfileCheckedInFromMap"]) {
        // figure out which element was tapped
        UserAnnotation *tappedObj = [sender annotation];
        // setup a user object with the info we have from the pin and callout
        // so that this information can already be in the resume without having to load it
        User *selectedUser = [[User alloc] init];
        selectedUser.nickname = tappedObj.nickname;
        selectedUser.userID = [tappedObj.objectId intValue];
        selectedUser.location = CLLocationCoordinate2DMake(tappedObj.lat, tappedObj.lon);
        selectedUser.status = tappedObj.status;
        selectedUser.skills = tappedObj.skills;   
#if DEBUG
        NSLog(@"Showing resume for user with ID: %d", selectedUser.userID);
#endif
        // set the user object on the UserProfileCheckedInVC to the user we just created
        [[segue destinationViewController] setUser:selectedUser];
    }
    else if ([[segue identifier] isEqualToString:@"ShowUserListTable"]) {
        [[segue destinationViewController] setMissions: dataset.annotations];
    }
}

////// map delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self refreshLocationsIfNeeded];
    [[self mapView] doClustering];
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
	NSLog(@"MapTab: didUpdateUserLocation (lat %f, lon %f)", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
	
	if(userLocation.location.coordinate.latitude != 0 && userLocation.location.coordinate.longitude != 0)
	{
		// save the location for the next time
		[AppDelegate instance].settings.hasLocation= true;
		[AppDelegate instance].settings.lastKnownLocation = userLocation.location;
		[[AppDelegate instance] saveSettings];
		
        if (!hasUpdatedUserLocation) {
            NSLog(@"MapTab: didUpdateUserLocation a zoomto (lat %f, lon %f)", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
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

@end
