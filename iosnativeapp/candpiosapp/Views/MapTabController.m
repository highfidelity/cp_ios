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

@interface Mission : NSObject< MKAnnotation >
{
	
}
@property (nonatomic,assign) double lat;
@property (nonatomic,assign) double lon;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *imageUrl;
-(id)initFromDictionary:(NSDictionary*)jsonDict;


@end
@implementation Mission
@synthesize lat,lon;
@synthesize title,description,nickname,imageUrl;
-(id)initFromDictionary:(NSDictionary*)jsonDict
{
	self=[super init];
	if(self)
	{
		lat = [[jsonDict objectForKey:@"lat"]doubleValue];
		lon = [[jsonDict objectForKey:@"lng"] doubleValue];
		title = [jsonDict objectForKey:@"title"];
		description = [jsonDict objectForKey:@"description"];
		nickname = [jsonDict objectForKey:@"nickname"];
		id imageUrlObj = [jsonDict objectForKey:@"filename"];
		if(imageUrlObj && imageUrlObj != [NSNull null])
			imageUrl = imageUrlObj;
		else
		{
			int z = 0;
		}
	}
	return self;
}
// for MKAnnotation protocol
// @property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//
-(CLLocationCoordinate2D) coordinate
{
	return CLLocationCoordinate2DMake(lat, lon);
}


@end

@implementation MapTabController
@synthesize mapView;
@synthesize missions;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		missions = [NSMutableArray array];
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
	
	// kick off a request to load the map items near the given lat & lon
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
					

	NSOperationQueue *queue = [NSOperationQueue mainQueue];
	//NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	BOOL wasSuspended = queue.isSuspended;
	[queue setSuspended: NO];
	int zsda = 99;
}

- (void)viewDidUnload
{
	[self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.coffeeandpower.com/api.php?action=mission&lat=36&lon=-122"]];
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSArray *payloadArray = [JSON objectForKey:@"payload"];
		NSLog(@"Got %d missions.", [payloadArray count]);
		for(NSDictionary *missionDict in payloadArray)
		{
			//NSLog(@"Mission %d: %@", )
			int z = 0;
			Mission *mission = [[Mission alloc]initFromDictionary:missionDict];
			[missions addObject:mission];
			[mapView addAnnotation:mission];
		}
		//[mapView addAnnotations:missions];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		int z = 99;
	}];
	
	NSOperationQueue *queue = [NSOperationQueue mainQueue];
	//NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperation:operation];

	
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// mapView:viewForAnnotation: provides the view for each annotation.
// This method may be called for all or some of the added annotations.
// For MapKit provided annotations (eg. MKUserLocation) return nil to use the MapKit provided annotation view.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *pinToReturn = nil;
	if([annotation isKindOfClass:[Mission class]])
	{
		MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"asdf"];
		if (pin == nil)
		{
			pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"asdf"];
		}
		else
		{
			pin.annotation = annotation;
		}
		pin.pinColor = MKPinAnnotationColorRed;
		pin.animatesDrop = NO;
		pin.canShowCallout = YES;
		Mission *mission = (Mission*)annotation;
		if(mission.imageUrl)
		{
			UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
			[leftCallout setImageWithURL:[NSURL URLWithString:mission.imageUrl]
						   placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
			pin.leftCalloutAccessoryView = 	leftCallout;
		}
		UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		button.frame =CGRectMake(0, 0, 32, 32);
		pin.rightCalloutAccessoryView = button;
		
		pinToReturn = pin;
	}

	return pinToReturn;
}
@end
