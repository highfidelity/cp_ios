#import <QuartzCore/QuartzCore.h>
#import "CheckInDetailsViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "AFJSONRequestOperation.h"
#import "SignupController.h"
#import "UserTableViewCell.h"
#import "WebViewController.h"
#import "UIImageView+WebCache.h"

@implementation CheckInDetailsViewController

@synthesize slider, place;

NSMutableArray *timeIntervals;
UITextField *statusTextField;
NSMutableArray *usersCheckedIn;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

- (void)logoutButtonAction:(id)sender {
    [[AppDelegate instance] logoutEverything];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    usersCheckedIn = [[NSMutableArray alloc] init];
    
    // Check for any other checked in users
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=getUsersCheckedIn&foursquare=%@&lat=%.7f&lng=%.7f&distance=5", kCandPWebServiceUrl, place.foursquareID, place.lat, place.lng];
    
    NSURL *locationURL = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(
                                             DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: 
                        locationURL];
        [self performSelectorOnMainThread:@selector(processUsersCheckedIn:) 
                               withObject:data waitUntilDone:YES];
    });   

    
    self.title = [NSString stringWithFormat:@"Welcome, %@", [AppDelegate instance].settings.userNickname];

    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonAction:)];
    
    self.navigationItem.rightBarButtonItem = logoutButton;

    
    self.tableView.backgroundColor = [UIColor colorWithRed:(0xF1 / 255.0) green:(0xF1 / 255.0) blue:(0xF1 / 255.0) alpha:1.0];
    
//    [UIColor colorWithRed:(0x79 / 255.0) green:(0x79 / 255.0) blue:(0x79 / 255.0) alpha:1.0];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 290)];

    UIView *locationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, headerView.frame.size.width, 70)];
    UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, locationView.frame.size.height, headerView.frame.size.width, 145)];
    UIView *checkinView = [[UIView alloc] initWithFrame:CGRectMake(0, statusView.frame.origin.y + statusView.frame.size.height, headerView.frame.size.width, 75)];

    
    // Set up the locationView
    UILabel *placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 225, 18)];
    placeNameLabel.backgroundColor = [UIColor clearColor];
    placeNameLabel.text = place.name;
    placeNameLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [locationView addSubview:placeNameLabel];

    UILabel *placeAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, placeNameLabel.frame.origin.y + placeNameLabel.frame.size.height, 225, 40)];
    placeAddressLabel.backgroundColor = [UIColor clearColor];
    placeAddressLabel.numberOfLines = 2;
    placeAddressLabel.text = [NSString stringWithFormat:@"%@%@%@%@%@%@%@", 
                              (place.address) ? place.address : @"", 
                              (place.address) ? @"\n" : @"", 
                              (place.city) ? place.city : @"", 
                              (place.state) ? @", " : @" ", 
                              (place.state) ? place.state : @"", 
                              (place.zip) ? @"  " : @"", 
                              (place.zip) ? place.zip : @""];
    
    placeAddressLabel.font = [UIFont systemFontOfSize:13.0];
    [locationView addSubview:placeAddressLabel];

    UIView *mapViewSmall = [[UIView alloc] initWithFrame:CGRectMake(250, 10, 50, 50)];
    mapViewSmall.clipsToBounds = YES;
    
    
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(-25, -25, 100, 100)];        
    MKCoordinateRegion newRegion;
    
    newRegion.center.latitude = place.lat;
    newRegion.center.longitude = place.lng;

    newRegion.span.latitudeDelta = 0.003;
    newRegion.span.longitudeDelta = 0.003;
    
    [mapView setRegion:newRegion animated:NO];
    mapView.userInteractionEnabled = NO;
    
    [mapViewSmall addSubview:mapView];
    [locationView addSubview:mapViewSmall];
    
    
    // Set up the statusView
    statusView.backgroundColor = [UIColor colorWithRed:(0x79 / 255.0) green:(0x79 / 255.0) blue:(0x79 / 255.0) alpha:1.0];

    statusTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 15, 290, 40)];
    statusTextField.borderStyle = UITextBorderStyleRoundedRect;
    statusTextField.textColor = [UIColor blackColor];
    statusTextField.font = [UIFont systemFontOfSize:13.0];
    statusTextField.placeholder = @"What are you available to do?";
    statusTextField.backgroundColor = [UIColor whiteColor];
//    statusTextField.textAlignment = UITextAlignmentCenter;
    statusTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    statusTextField.keyboardType = UIKeyboardTypeDefault;
    statusTextField.returnKeyType = UIReturnKeyDone;
    
    statusTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

    statusTextField.delegate = self;
    
    [statusView addSubview:statusTextField];
    
    UILabel *durationHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 70, headerView.frame.size.width, 20)];
    durationHeaderLabel.textColor = [UIColor whiteColor];
    durationHeaderLabel.backgroundColor = [UIColor clearColor];
    durationHeaderLabel.font = [UIFont boldSystemFontOfSize:13.0];
    durationHeaderLabel.text = @"For how long?";
    durationHeaderLabel.shadowColor = [UIColor blackColor];
    durationHeaderLabel.shadowOffset = CGSizeMake(1, 1);
    
    [statusView addSubview:durationHeaderLabel];
    
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
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20 + labelWidth * labelNumber, 90, labelWidth, 20)];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:10.0];
        label.text = [dict objectForKey:@"text"];
        label.textAlignment = UITextAlignmentCenter;
        labelNumber++;
        [statusView addSubview:label];
    }
    
    
    // Add the slider + check in button to the view
    CGFloat margin = 30;
    CGFloat width = 320 - margin * 2;

    slider = [[UISlider alloc] initWithFrame:CGRectMake(margin, 100, width, 40)];
    [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    slider.continuous = NO;
    slider.minimumValue = 0;
    slider.maximumValue = timeIntervals.count - 1;
    slider.value = 0;
    [statusView addSubview:slider];
    
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [checkInButton addTarget:self action:@selector(checkInPressed:) forControlEvents:UIControlEventTouchDown];
    [checkInButton setTitle:@"Check In" forState:UIControlStateNormal];
    [checkInButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    checkInButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    checkInButton.frame = CGRectMake(margin, 15, width, 45);

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = checkInButton.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor grayColor] CGColor], nil];
    [checkInButton.layer insertSublayer:gradient atIndex:0];
    checkInButton.layer.cornerRadius = 5;
    checkInButton.clipsToBounds = YES;

    [checkinView addSubview:checkInButton];

    [headerView addSubview:locationView];
    [headerView addSubview:statusView];
    [headerView addSubview:checkinView];

    self.tableView.tableHeaderView = headerView;
}

- (void)checkInPressed:(id)sender {
    // send the server your lat/lon, checkin_time (now), checkout_time (now + duration from slider), and the venue data from the place. 
    
    // checkOutTime is equal to the slider value (represented in hours) * 60 minutes * 60 seconds to normalize the units into seconds
    NSInteger checkInTime = [[NSDate date] timeIntervalSince1970];
    NSInteger checkInDuration = [[(NSDictionary *)[timeIntervals objectAtIndex:slider.value] objectForKey:@"interval"] integerValue];    
    NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
    NSString *foursquareID = place.foursquareID;
    NSString *statusText = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                        (__bridge CFStringRef) statusTextField.text,
                                                                                        NULL,
                                                                                        (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                        kCFStringEncodingUTF8);
    
    NSString *venueName = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                              (__bridge CFStringRef) place.name,
                                                                              NULL,
                                                                              (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                              kCFStringEncodingUTF8);

    if (statusText == NULL) {
        statusText = @"";
    }

	[SVProgressHUD showWithStatus:@"Checking In..."];
    
    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=checkin&lat=%.7f&lng=%.7f&checkin=%d&checkout=%d&foursquare=%@&status=%@&venue_name=%@", kCandPWebServiceUrl, place.lat, place.lng, checkInTime, checkOutTime, foursquareID, statusText, venueName];

//    NSString *urlString = [NSString stringWithFormat:@"%@api.php?action=checkin&lat=%.7f&lng=%.7f&checkin=%d&checkout=%d&foursquare=%@&status=%@", @"http://dev.worklist.net/~emcro/candpweb/web/", place.lat, place.lng, checkInTime, checkOutTime, foursquareID, [statusTextField.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];

//    NSLog(@"string: %@", urlString);

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

- (void)processUsersCheckedIn:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions 
                          error:&error];

    if (json == NULL) {
        return;
    }
    else {
        usersCheckedIn = [json objectForKey:@"usersAtCheckin"];
//        NSLog(@"json: %@", json);
//        NSLog(@"usersCheckedIn: %@", usersCheckedIn);

        [self.tableView reloadData];
    }
}

- (void)sliderMoved:(id)sender {
    UISlider *thisSlider = (UISlider *)sender;
    
    // Only allow full hour choices    
    float val = thisSlider.value;
    
    thisSlider.value = roundf(val);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
	// create the parent view that will hold header Label
	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)];
	customView.backgroundColor = [UIColor colorWithRed:(0x69 / 255.0) green:(0x84 / 255.0) blue:(0x9F / 255.0) alpha:1.0];
	
	// create the button object
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.textColor = [UIColor whiteColor];
    headerLabel.numberOfLines = 1;
	headerLabel.font = [UIFont systemFontOfSize:12.0];
    headerLabel.textAlignment = UITextAlignmentCenter;

    NSString *title;
    
    if ([place.foursquareID isEqualToString:@"0"]) {
        title = @"Also Near Here";
    }
    else {
        title = [NSString stringWithFormat:@"Also @ %@", place.name];
    }
    
	headerLabel.text = title;

    // Resize label, then make full width to be centered correctly
    [headerLabel sizeToFit];
//    headerLabel.center = CGPointMake(customView.frame.size.width / 2, customView.frame.size.height / 2);
	headerLabel.frame = CGRectMake(0.0, 0.0, customView.frame.size.width, headerLabel.frame.size.height);

	[customView addSubview:headerLabel];
    
	return customView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 17;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = [NSString stringWithFormat:@"Also @ %@", self.title];
    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
//    
//    if (usersCheckedIn.count > 0) {
//        return 1;
//    }
//    else {
//        return 0;
//    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return usersCheckedIn.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
        
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
//    cell.backgroundColor = [UIColor whiteColor];
//    cell.backgroundView.backgroundColor = [UIColor whiteColor];

    cell.nicknameLabel.text = [[usersCheckedIn objectAtIndex:indexPath.row] objectForKey:@"nickname"];
    cell.skillsLabel.text = [[usersCheckedIn objectAtIndex:indexPath.row] objectForKey:@"status_text"];

    NSString *imageUrl = [[usersCheckedIn objectAtIndex:indexPath.row] objectForKey:@"imageUrl"];
    
    if (imageUrl != [NSNull null]) {
        UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
		
		leftCallout.contentMode = UIViewContentModeScaleAspectFill;
        
        [leftCallout setImageWithURL:[NSURL URLWithString:imageUrl]
                    placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
        
        cell.imageView.image = leftCallout.image;

    }
    else
    {        
        cell.imageView.image = [UIImage imageNamed:@"63-runner.png"];			
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WebViewController *controller = [[WebViewController alloc] initWithNibName:@"WebView" bundle:nil];
    NSString *url = [NSString stringWithFormat:@"%@profile.php?u=%@", kCandPWebServiceUrl, [[usersCheckedIn objectAtIndex:indexPath.row] objectForKey:@"id"]];
    controller.urlAddress = url;
    controller.title = [[usersCheckedIn objectAtIndex:indexPath.row] objectForKey:@"nickname"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
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
