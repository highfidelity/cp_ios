#import "CheckInDetailsViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "AFJSONRequestOperation.h"
#import "SignupController.h"

@implementation CheckInDetailsViewController

@synthesize slider, place;

NSMutableArray *timeIntervals;

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
    
    timeIntervals = [[NSMutableArray alloc] initWithCapacity:5];

    NSArray *intervalArray = [NSArray arrayWithObjects:
                              [NSNumber numberWithInteger:1],
                              [NSNumber numberWithInteger:3],                              
                              [NSNumber numberWithInteger:5],
                              [NSNumber numberWithInteger:8],
                              nil];

    for (NSNumber *x in intervalArray) {
        NSInteger time = [x integerValue];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              x, @"interval", 
                              [NSString stringWithFormat:@"%d hr%@", time, (time > 1) ? @"s" : @""], @"text",
                              nil];
        [timeIntervals addObject:dict];
    }
    

    // Draw the labels for each time interval
    NSInteger labelNumber = 0;
    NSInteger labelWidth = 70;
    
    for (NSDictionary *dict in timeIntervals) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20 + labelWidth * labelNumber, 30, labelWidth, 20)];
        label.font = [UIFont systemFontOfSize:10.0];
        label.text = [dict objectForKey:@"text"];
        label.textAlignment = UITextAlignmentCenter;
        labelNumber++;
        [self.view addSubview:label];
    }
    
    
    // Add the slider + check in button to the view
    CGFloat margin = 40;
    CGFloat width = 320 - margin * 2;

    slider = [[UISlider alloc] initWithFrame:CGRectMake(margin, margin, width, 40)];
    [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    slider.continuous = NO;
    slider.minimumValue = 0;
    slider.maximumValue = timeIntervals.count - 1;
    slider.value = 0;
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
    NSInteger checkInDuration = [[(NSDictionary *)[timeIntervals objectAtIndex:slider.value] objectForKey:@"interval"] integerValue];    
    NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
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
        // Cancel all old local notifications
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        localNotif.alertBody = @"You will be checked out of C&P in 5 min and will no longer be shown on the map.";
        localNotif.alertAction = @"Check In";
        localNotif.soundName = UILocalNotificationDefaultSoundName;
        
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
    
    
    [SVProgressHUD dismiss];
    
    if ([[json objectForKey:@"response"] intValue] == 1) {
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
    
    // Only allow full hour choices    
    float val = thisSlider.value;
    
    thisSlider.value = roundf(val);
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
