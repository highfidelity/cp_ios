//
//  CheckInDetailsViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckInDetailsViewController.h"
#import "SVProgressHUD.h"
#import "CPUIHelper.h"
#import "SignupController.h"
#import "AppDelegate.h"

@interface CheckInDetailsViewController() <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *blueOverlay;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *checkInLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (weak, nonatomic) IBOutlet UILabel *placeAddress;
@property (weak, nonatomic) IBOutlet UIView *checkInDetails;
@property (weak, nonatomic) IBOutlet UILabel *willLabel;
@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UILabel *wantLabel;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (assign, nonatomic) int checkInDuration;
@property (weak, nonatomic) IBOutlet UILabel *durationString;

-(IBAction)sliderChanged:(id)sender;

@end

@implementation CheckInDetailsViewController
@synthesize blueOverlay = _blueOverlay;
@synthesize mapView = _mapView;
@synthesize scrollView = _scrollView;
@synthesize checkInLabel = _checkInLabel;
@synthesize placeName = _placeName;
@synthesize placeAddress = _placeAddress;
@synthesize checkInDetails = _checkInDetails;
@synthesize willLabel = _willLabel;
@synthesize orLabel = _orLabel;
@synthesize wantLabel = _wantLabel;
@synthesize statusTextField = _statusTextField;
@synthesize timeSlider = _timeSlider;
@synthesize place = _place;
@synthesize checkInDuration = _checkInDuration;
@synthesize durationString = _durationString;

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

-(void)setCheckInDuration:(int)checkInDuration
{
    self.durationString.text = [NSString stringWithFormat:@"%d hours", checkInDuration];
    _checkInDuration = checkInDuration;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.place.name;
    
    // make an MKCoordinate region for the zoom level on the map
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(self.place.lat, self.place.lng), MKCoordinateSpanMake(0.003, 0.003));
    [self.mapView setRegion:region];
    
    // this will always be the point on iPhones up to iPhone4
    // if this needs to be used on iPad we'll need to do this programatically or use an if-else
    CGPoint moveRight = CGPointMake(71, 58);
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:moveRight toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    
    // set LeagueGothic font where applicable
    UIFont *gothic = [UIFont fontWithName:@"LeagueGothic" size:26.f];
    for (UILabel *labelNeedsGothic in [NSArray arrayWithObjects:self.checkInLabel, self.willLabel, self.orLabel, self.wantLabel, nil]) {
        labelNeedsGothic.font = gothic;
    }
    
    [CPUIHelper addShadowToView:self.checkInDetails color:[UIColor blackColor] offset:CGSizeMake(0, -2) radius:3 opacity:0.24];
    [CPUIHelper addShadowToView:self.blueOverlay color:[UIColor blackColor] offset:CGSizeMake(0,2) radius:3 opacity:0.24];
    
    // set the diagonal noise texture on the horizontal scrollview
    UIColor *texture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise.png"]];
    self.scrollView.backgroundColor = texture;
    
    // set the light diagonal noise texture on the bottom UIView
    UIColor *lightTexture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-light.png"]];
    self.checkInDetails.backgroundColor = lightTexture; 
    
    self.statusTextField.delegate = self;
    
    self.placeName.text = self.place.name;
    self.placeAddress.text = self.place.address;
    
    [self.timeSlider setThumbImage:[UIImage imageNamed:@"check-in-slider-handle.png"] forState:UIControlStateNormal];
    self.checkInDuration = self.timeSlider.value;
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setScrollView:nil];
    [self setPlaceName:nil];
    [self setPlaceAddress:nil];
    [self setCheckInLabel:nil];
    [self setCheckInDetails:nil];
    [self setBlueOverlay:nil];
    [self setWillLabel:nil];
    [self setOrLabel:nil];
    [self setWantLabel:nil];
    [self setStatusTextField:nil];
    [self setTimeSlider:nil];
    [self setDurationString:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)checkInPressed:(id)sender {
    // send the server your lat/lon, checkin_time (now), checkout_time (now + duration from slider), and the venue data from the place. 
    // checkOutTime is equal to the slider value (represented in hours) * 60 minutes * 60 seconds to normalize the units into seconds
    
    NSInteger checkInTime = [[NSDate date] timeIntervalSince1970];
    NSInteger checkInDuration = self.checkInDuration;    
    NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
    NSString *foursquareID = self.place.foursquareID;
    NSString *statusText = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                        (__bridge CFStringRef) self.statusTextField.text,
                                                                                        NULL,
                                                                                        (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                        kCFStringEncodingUTF8);
    
    NSString *venueName = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                       (__bridge CFStringRef) self.place.name,
                                                                                       NULL,
                                                                                       (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                       kCFStringEncodingUTF8);
    
    if (statusText == NULL) {
        statusText = @"";
    }
    
    [SVProgressHUD showWithStatus:@"Checking In..."];
    
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=checkin&lat=%.7f&lng=%.7f&checkin=%d&checkout=%d&foursquare=%@&status=%@&venue_name=%@",
                           kCandPWebServiceUrl,
                           self.place.lat,
                           self.place.lng,
                           checkInTime,
                           checkOutTime,
                           foursquareID,
                           statusText,
                           venueName];
    
    NSURL *locationURL = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: 
                        locationURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) 
                               withObject:data
                            waitUntilDone:YES];
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

-(IBAction)sliderChanged:(id)sender
{
    float value = self.timeSlider.value;
    if (value < 2) {
        value = 1;
    } else if (value < 4) {
        value = 3;
    } else if (value < 6) {
        value = 5;
    } else {
        value = 7;
    }
    
    UILabel *previousSelectedValueLabel = (UILabel *)[self.view viewWithTag:(1000 + self.checkInDuration)];
    previousSelectedValueLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    previousSelectedValueLabel.font = [UIFont boldSystemFontOfSize:20.0];
    
    UILabel *selectedValueLabel = (UILabel *)[self.view viewWithTag:(1000 + value)];
    selectedValueLabel.textColor = self.durationString.textColor;
    selectedValueLabel.font = [UIFont boldSystemFontOfSize:28.0];
    
    [self.timeSlider setValue:value animated:YES];
    self.checkInDuration = value;
}

@end
