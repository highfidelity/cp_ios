//
//  MapTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "MapTabController.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "UIImageView+WebCache.h"
#import "MissionAnnotation.h"
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "MyWebTabController.h"
#import "UserSubview.h"
#import "SA_ActionSheet.h"
#import "FacebookLoginSequence.h"
#import "EmailLoginSequence.h"
#import "CreateEmailAccountController.h"
#import "UserListTableViewController.h"
#import "SignupController.h"
#import "MapDataSet.h"

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

    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [UIImage imageNamed:@"refresh"];
    [refreshButton setImage:refreshImage forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshLocations) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.frame = CGRectMake(0, 0, 120, 60);
    refreshButton.center = CGPointMake(self.view.frame.size.width / 2.0, self.tabBarController.tabBar.frame.origin.y - 100.0);
    [self.view addSubview:refreshButton];

	self.navigationController.delegate = self;
	hasUpdatedUserLocation = false;
	
	// every 10 seconds, see if it's time to refresh the data
	// (the data invalidates every 2 minutes, but we check more often)
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
												   target:self
												 selector:@selector(refreshLocationsIfNeeded)
												 userInfo:nil
												  repeats:YES];
	
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"List"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self 
                                                                           action:@selector(listButtonTapped)];
	
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
	
	// show the loading screen but only the first time
	if(!hasShownLoadingScreen)
	{
		[SVProgressHUD showWithStatus:@"Loading..."];
		hasShownLoadingScreen = true;
	}
	
	[self updateLoginButton];

	// http://www.coffeeandpower.com/api.php?action=userdetail?id=5872

	// kick off a request to load the map items near the given lat & lon
	// http://www.coffeeandpower.com/api.php?action=userlist
	//	{
	//	error: false,
	//	payload: [
	//		{
	//		distance: "0",
	//		online: "1",
	//			id: "5872",
	//		nickname: "Charlie White",
	//		status_text: "",
	//		photo: "11105",
	//		filename: "http://coffeeandpower-prod.s3.amazonaws.com/image/profile/5872_1325441007_256.jpg",
	//		lat: "0.000000",
	//		lng: "0.000000",
	//		APNToken: null,
	//		active: "Y",
	//		favorite_enabled: "0",
	//		video_chat: "1",
	//		ratings: "0",
	//		skills: null
	//		},
	//		{
	//		distance: "4948.15104391205",
	//		online: "1",
	//			id: "5852",
	//		nickname: "Greg Beaver",
	//		status_text: "",
	//		photo: "11065",
	//		filename: "http://coffeeandpower-prod.s3.amazonaws.com/image/profile/5852_1325274001_256.jpg",
	//		lat: "44.631891",
	//		lng: "-63.577996",
	//		APNToken: null,
	//		active: "Y",
	//		favorite_enabled: "0",
	//		video_chat: "0",
	//		ratings: "0",
	//		skills: null
	//		},
	//   ]
	// }
	
	
	
	// http://www.coffeeandpower.com/api.php?action=mission&lat=36&lon=-122
	// response is in the form:
	//	{
	//		"error": false,
	//		"payload": [{
	//			"distance": "124.727576005202",
	//			"id": "3761",
	//			"author_id": "476",
	//			"author_phone": "",
	//			"author_email": "secondlife@coffeeandpower.com",
	//			"title": "you to place a C&P kiosk in Second Life",
	//			"description": "Calling all SL Avatars! \n\nWe need your help to spread the word about C&P inside Second Life. Earn some extra C$ to spend on real life services by placing a C&P kiosk on your land and bonus C$ for getting avatars to click on it.\n\nHow It works:\n1. Go inworld to: http:\/\/maps.secondlife.com\/secondlife\/P%20Squared\/53\/147\/92 and pick up a Coffee & Power Kiosk (click the button below the screen to get your copy) \n2. Set the kiosk out on your land\n3. Make an offer on this mission, be sure to include your SL Name and Kiosk location for verification\n4. C&P will pay you C$5 for each kiosk you set up (you can place up to 3 kiosks)\n5. Bonus: C&P will pay you C$2.50 for every 25 unique avatar clicks you get to the kiosk (up to C$20)\n\nNOTE: Don't forget to include your SL name in your offer. This is a limited time promotion, so don't delay! ",
	//			"type": "want",
	//			"status": "On",
	//			"proposed_price": "5.00",
	//			"create_date": "2011-11-16 20:35:28",
	//			"deadline": "2011-12-29 22:22:15",
	//			"location_text": null,
	//			"lat": "37.771119",
	//			"lng": "-122.423889",
	//			"is_deleted": "0",
	//			"deleted_by_user_id": "0",
	//			"video": "",
	//			"has_invite_list": "0",
	//			"invite_favorites": "0",
	//			"is_private": "0",
	//			"skill_id": "34",
	//			"read_status_agent": "read",
	//			"read_status_client": "read",
	//			"updated": null,
	//			"hit_count": "215",
	//			"last_switched_on": "2011-12-28 22:22:15",
	//			"expenses_c_dollars": "No",
	//			"expenses_us_dollars": "No",
	//			"expenses_credit_card": "No",
	//			"expenses_other": "",
	//			"fb_likes": "4",
	//			"is_on_top": "1",
	//			"is_giftable": "0",
	//			"nickname": "JeskaD",
	//			"photo": "1096",
	//			"filename": "http:\/\/coffeeandpower-prod.s3.amazonaws.com\/image\/profile\/476_1318241551_256.jpg"
	//		},
	//		...
	//	  ]
	//	}
	//	
    
    [self refreshLocationsIfNeeded];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)refreshLocationsIfNeeded
{
	MKMapRect mapRect = mapView.visibleMapRect;

	if(!dataset || ![dataset isValidFor:mapRect])
	{
		[self refreshLocations];
	}
		

}
- (void)refreshLocations 
{
	MKMapRect mapRect = mapView.visibleMapRect;
		[MapDataSet beginLoadingNewDataset:mapRect
								completion:^(MapDataSet *newDataset, NSError *error) {
									
									
									if(newDataset)
									{
										// remove the old pins
										// TODO: update/merge existing elements instead of removing them all
										if(dataset)
											[mapView removeAnnotations:dataset.annotations];
										
										// add new the new ones
										[mapView addAnnotations:newDataset.annotations];
										
										dataset = newDataset;
									}
									
									[SVProgressHUD dismiss];
									
									
								}];


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

-(void)listButtonTapped
{
    UserListTableViewController *userListTableViewController = [[UserListTableViewController alloc] init];
    userListTableViewController.missions = dataset.annotations;
    [self.navigationController pushViewController:userListTableViewController animated:YES];
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

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *pinToReturn = nil;
	if([annotation isKindOfClass:[CandPAnnotation class]])
	{
		CandPAnnotation *candpanno = (CandPAnnotation*)annotation;

		
		MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"asdf"];
		if (pin == nil)
		{
			pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"asdf"];
		}
		else
		{
			pin.annotation = annotation;
		}
		pinToReturn = pin;
		pin.pinColor = MKPinAnnotationColorRed;
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
		[button addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	return pinToReturn;
}

-(void)accessoryButtonTapped:(UIButton*)sender
{
	// figure out which element was tapped, and open the page
	int index = sender.tag;
	NSArray *annotations = dataset.annotations;
	if(index < [annotations count])
	{
		CandPAnnotation *tappedObj = [annotations objectAtIndex:index];
		// 
		MyWebTabController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewOfCandPUser"];
		NSString *url = [NSString stringWithFormat:@"%@profile.php?u=%@", kCandPWebServiceUrl, tappedObj.objectId];
		controller.urlToLoad = url;
	    [self.navigationController pushViewController:controller animated:YES];
	}
}

////// map delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
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
	NSLog(@"MapTab: didUpdateUserLocation (lat %f, lon %f)", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
	
	if(userLocation.location.coordinate.latitude != 0 && userLocation.location.coordinate.longitude != 0)
	{
		// save the location for the next time
		[AppDelegate instance].settings.hasLocation= true;
		[AppDelegate instance].settings.lastKnownLocation = userLocation.location;
		[[AppDelegate instance] saveSettings];
		
		// zoom to it, but only the first time
		if(!hasUpdatedUserLocation)
		{
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

	[mapView setRegion:viewRegion];
	
}

@end
