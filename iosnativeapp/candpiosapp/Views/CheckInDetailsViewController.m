#import "CheckInDetailsViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "AFJSONRequestOperation.h"
#import "SignupController.h"

@implementation CheckInDetailsViewController

@synthesize slider, place;

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
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGFloat margin = 40;
    CGFloat width = 320 - margin * 2;
    
    slider = [[UISlider alloc] initWithFrame:CGRectMake(margin, margin, width, 40)];
    [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    slider.continuous = NO;
    slider.minimumValue = 0.5;
    slider.maximumValue = 8;
    slider.value = 2;
    [self.view addSubview:slider];
    
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [checkInButton addTarget:self action:@selector(checkInPressed:) forControlEvents:UIControlEventTouchDown];
    [checkInButton setTitle:@"Check In" forState:UIControlStateNormal];
    checkInButton.frame = CGRectMake(margin, margin * 3, width, 40);
    [self.view addSubview:checkInButton];
}

- (void)checkInPressed:(id)sender {
    // send the server your lat/lon, checkin_time (now), checkout_time (now + duration from slider), and the venue data from the place. 

    // checkOutTime is equal to the slider value (represented in hours) * 60 minutes * 60 seconds to normalize the units into seconds
    NSInteger checkInTime = [[NSDate date] timeIntervalSince1970];
    NSInteger checkOutTime = checkInTime + slider.value * 3600;
    NSString *foursquareID = place.foursquareID;
    
	[SVProgressHUD showWithStatus:@"Checking In..."];

    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=checkin&lat=%.7f&lng=%.7f&checkin=%d&checkout=%d&foursquare=%@", kCandPWebServiceUrl, place.lat, place.lng, checkInTime, checkOutTime, foursquareID];

//    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=checkin&lat=%.7f&lng=%.7f&checkin=%d&checkout=%d&foursquare=%@", @"http://dev.worklist.net/~emcro/candpweb/web/", place.lat, place.lng, checkInTime, checkOutTime, foursquareID];

    NSURL *locationURL = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: 
                        locationURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) 
                               withObject:data waitUntilDone:YES];
    });   

    // Fire a notification 5 minutes before checkout time
    NSInteger minutesBefore = 5;
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif) {
        localNotif.alertBody = @"You will be automatically checked out of C&P in 5 min and your listings will not be visible until you checkin again.";
        localNotif.alertAction = @"Check In";

        localNotif.fireDate = [NSDate dateWithTimeIntervalSince1970:(checkOutTime - minutesBefore * 60)];
//        localNotif.fireDate = [NSDate dateWithTimeIntervalSince1970:(checkInTime + 10)];
        localNotif.timeZone = [NSTimeZone defaultTimeZone];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    }    
}


- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions 
                          error:&error];
    

    NSLog(@"json: %@, data: %@", json, responseData);

    [SVProgressHUD dismiss];
    
    if ([[json objectForKey:@"reponse"] isEqualToString:@"1"]) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must be logged in to C&P in order to check in." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alertView show];

        SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)sliderMoved:(id)sender {
    UISlider *thisSlider = (UISlider *)sender;

    // Only allow choices for 30 minutes, 1, 2, 4 and 8 hours
    
    float val = thisSlider.value;
    
    if (val > 0.5 && val < 0.75) {
        thisSlider.value = 0.5;
    }
    else if (val >= 0.75 && val < 1.5) {
        thisSlider.value = 1;
    }
    else if (val >= 1.5 && val < 3) {
        thisSlider.value = 2;
    }
    else if (val >= 3 && val < 6) {
        thisSlider.value = 4;
    }
    else if (val >= 6) {
        thisSlider.value = 8;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
