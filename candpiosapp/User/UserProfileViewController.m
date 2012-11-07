//
//  UserProfileViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserProfileViewController.h"
#import "FoursquareAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "GRMustache.h"
#import "VenueInfoViewController.h"
#import "GTMNSString+HTML.h"
#import "UserProfileLinkedInViewController.h"
#import "FaceToFaceHelper.h"

#define kResumeWebViewOffsetTop 304

@interface UserProfileViewController() <UIWebViewDelegate, UIActionSheetDelegate, GRMustacheTemplateDelegate>

@property (strong, nonatomic) UITapGestureRecognizer *tapRecon;
@property (strong, nonatomic) NSString* resumeHTML;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *checkedIn;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *userCard;
@property (weak, nonatomic) IBOutlet UIImageView *cardImage;
@property (weak, nonatomic) IBOutlet UILabel *cardStatus;
@property (weak, nonatomic) IBOutlet UILabel *cardNickname;
@property (weak, nonatomic) IBOutlet UILabel *cardJobPosition;
@property (weak, nonatomic) IBOutlet UIView *venueView;
@property (weak, nonatomic) IBOutlet UIButton *venueViewButton;
@property (weak, nonatomic) IBOutlet UILabel *venueName;
@property (weak, nonatomic) IBOutlet UILabel *venueAddress;
@property (weak, nonatomic) IBOutlet UIImageView *venueOthersIcon;
@property (weak, nonatomic) IBOutlet UILabel *venueOthers;
@property (weak, nonatomic) IBOutlet UIView *availabilityView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursAvailable;
@property (weak, nonatomic) IBOutlet UILabel *minutesAvailable;
@property (weak, nonatomic) IBOutlet UIView *resumeView;
@property (weak, nonatomic) IBOutlet UILabel *resumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *resumeRate;
@property (weak, nonatomic) IBOutlet UILabel *resumeEarned;
@property (weak, nonatomic) IBOutlet UILabel *loveReceived;
@property (weak, nonatomic) IBOutlet UIWebView *resumeWebView;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *f2fButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (weak, nonatomic) IBOutlet UIImageView *goMenuBackground;
@property (weak, nonatomic) IBOutlet UILabel *propNoteLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mapMarker;
@property (weak, nonatomic) UIView *blueOverlayExtend;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL firstLoad;
@property (nonatomic) int othersAtPlace;
@property (nonatomic) NSInteger selectedFavoriteVenueIndex;
@property (nonatomic) BOOL mapAndDistanceLoaded;

-(NSString *)htmlStringWithResumeText;
-(IBAction)plusButtonPressed:(id)sender;
-(IBAction)minusButtonPressed:(id)sender;
-(IBAction)venueViewButtonPressed:(id)sender;
-(IBAction)chatButtonPressed:(id)sender;

@end

@implementation UserProfileViewController

static GRMustacheTemplate *resumeTemplate;

+ (GRMustacheTemplate*) resumeTemplate {
    if (!resumeTemplate) {
        resumeTemplate = [GRMustacheTemplate templateFromResource:@"UserResume" bundle:nil error:NULL];
    }
    return resumeTemplate;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Profile"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    // keep our own queue, so we can safely cancel
    self.operationQueue = [NSOperationQueue new];
    
    // when pulling the scroll view top down, present the map
    self.mapView.frame = CGRectUnion(self.mapView.frame,
                                     CGRectOffset(self.mapView.frame, 0, -self.mapView.frame.size.height));
    // add the blue overlay gradient in front of the map
    [self addGradientWithFrame:self.mapView.frame
                     locations:[NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:0.25],
                                [NSNumber numberWithFloat:0.30],
                                [NSNumber numberWithFloat:0.5],
                                [NSNumber numberWithFloat:0.90],
                                [NSNumber numberWithFloat:1.0],
                                nil]
                        colors:[NSArray arrayWithObjects:
                                (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0] CGColor],
                                (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:0.75] CGColor],
                                (id)[[UIColor colorWithRed:0.40 green:0.62 blue:0.64 alpha:0.4] CGColor],
                                (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:0.75] CGColor],
                                (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0] CGColor],
                                nil]
     ];
    
    // set LeagueGothic font where applicable
    [CPUIHelper changeFontForLabel:self.checkedIn toLeagueGothicOfSize:24];
    [CPUIHelper changeFontForLabel:self.resumeLabel toLeagueGothicOfSize:26];
    [CPUIHelper changeFontForLabel:self.cardNickname toLeagueGothicOfSize:28];
    
    // set the paper background color where applicable
    UIColor *paper = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper-texture.png"]];
    self.userCard.backgroundColor = paper;
    self.resumeView.backgroundColor = paper;
    self.resumeWebView.opaque = NO;
    self.resumeWebView.backgroundColor = paper;
    
    // make sure there's a shadow on the userCard and resumeView
    [CPUIHelper addShadowToView:self.userCard color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    [CPUIHelper addShadowToView:self.resumeView color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // custom back button to allow event capture
    
    if(!_tapRecon){
        _tapRecon = [[UITapGestureRecognizer alloc]
                     initWithTarget:self action:@selector(navigationBarTitleTap:)];
        _tapRecon.numberOfTapsRequired = 1;
        _tapRecon.cancelsTouchesInView = NO;
        [self.navigationController.navigationBar addGestureRecognizer:_tapRecon];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar removeGestureRecognizer:_tapRecon];
    self.tapRecon = nil;
}

- (void)setUser:(User *)newUser
{
    // assign the user
    _user = newUser;
    
    if (_user) {
        // set the booleans this VC uses in later control statements
        self.firstLoad = YES;
        self.mapAndDistanceLoaded = NO;
        
        // set the card image to the user's profile image
        [CPUIHelper profileImageView:self.cardImage
                 withProfileImageUrl:self.user.photoURL];
        
        // hide the go menu if this profile is current user's profile
        if (self.user.userID == [CPUserDefaultsHandler currentUser].userID || self.isF2FInvite) {
            for (NSNumber *viewID in [NSArray arrayWithObjects:[NSNumber numberWithInt:1005], [NSNumber numberWithInt:1006], [NSNumber numberWithInt:1007], [NSNumber numberWithInt:1008], [NSNumber numberWithInt:1009], [NSNumber numberWithInt:1010], [NSNumber numberWithInt:1020], nil]) {
                [self.view viewWithTag:[viewID intValue]].alpha = 0.0;
            }
        } else {
            for (NSNumber *viewID in [NSArray arrayWithObjects:[NSNumber numberWithInt:1005], [NSNumber numberWithInt:1006], [NSNumber numberWithInt:1007], [NSNumber numberWithInt:1008], [NSNumber numberWithInt:1009], [NSNumber numberWithInt:1010], [NSNumber numberWithInt:1020], nil]) {
                [self.view viewWithTag:[viewID intValue]].alpha = 1.0;
            }
            self.minusButton.alpha = 0.0;
            
        }
        
        // set the labels on the user business card
        self.cardNickname.text = self.user.nickname;
        [self setUserStatusWithQuotes:self.user.status];
        self.cardJobPosition.text = self.user.jobTitle;
        
        // set the navigation controller title to the user's nickname
        self.title = self.user.nickname;  
        
        // don't allow scrolling in the mustache view until it's loaded
        self.resumeWebView.userInteractionEnabled = NO;
        
        // check if this is an F2F invite
        if (self.isF2FInvite) {
            // we're in an F2F invite
            [self placeUserDataOnProfile];
        } else {  
            // lock the scrollView
            self.scrollView.scrollEnabled = NO;
            
            // put three animated dots after the Loading Resume text
            [CPUIHelper animatedEllipsisAfterLabel:self.resumeLabel start:YES];
            [CPUIHelper animatedEllipsisAfterLabel:self.checkedIn start:YES];
            
            // get a user object with resume data
            [self.user loadUserResumeOnQueue:self.operationQueue completion:^(NSError *error) {
                if (!error) {
                    // fill out the resume and unlock the scrollView
                    NSLog(@"Received resume response.");
                    self.scrollView.scrollEnabled = YES;
                    [self placeUserDataOnProfile];
                } else {
                    // error checking for load of user
                    NSLog(@"Error loading resume: %@", error);
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Resume Load"
                                                                    message:[error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }];
        }
    }
}

- (void)addGradientWithFrame:(CGRect)frame locations:(NSArray*)locations colors:(NSArray*)colors 
{
    // add gradient overlay
    UIView *overlay = [[UIView alloc] initWithFrame:frame];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = overlay.bounds;
    gradient.colors = colors;
    gradient.locations = locations;
    [overlay.layer insertSublayer:gradient atIndex:0];
    [self.scrollView insertSubview:overlay atIndex:1];
}

- (void)updateLastUserCheckin
{
    if (self.firstLoad) {
        // if the user is checked in show how much longer they'll be available for
        if ([self.user.checkoutEpoch timeIntervalSinceNow] > 0) {
            self.checkedIn.text = @"Checked in";
            // get the number of seconds until they'll checkout
            NSTimeInterval secondsToCheckout = [self.user.checkoutEpoch timeIntervalSinceNow];
            // convert to minutes and then hours + minutes to next our
            int minutesToCheckout = floor(secondsToCheckout / 60.0);
            int hoursToCheckout = floor(minutesToCheckout / 60.0);
            int minutesToHour = minutesToCheckout % 60;
            
            // only show hours if there's at least one
            if (hoursToCheckout > 0) {
                self.hoursAvailable.text = [NSString stringWithFormat:@"%d hrs", hoursToCheckout];
            } else {
                self.hoursAvailable.text = @"";
            }            
            self.minutesAvailable.text = [NSString stringWithFormat:@"%d mins", minutesToHour];
            // show the availability view
            self.availabilityView.alpha = 1.0;
            [UIView animateWithDuration:0.4 animations:^{self.availabilityView.alpha = 1.0;}];
        } else {
            // change the label since the user isn't here anymore
            self.checkedIn.text = @"Last checked in";
            
            // otherwise don't show the availability view
            self.availabilityView.alpha = 0.0;
            self.hoursAvailable.text = @"";
            self.minutesAvailable.text = @"";
        }
    }
    
    self.venueName.text = self.user.placeCheckedIn.name;
    self.venueAddress.text = self.user.placeCheckedIn.address;
    
    self.othersAtPlace = self.user.checkedIn ? self.user.placeCheckedIn.checkinCount - 1 : self.user.placeCheckedIn.checkinCount;
    
    if (self.firstLoad) {
        if (self.othersAtPlace == 0) {
            // hide the little man, nobody else is here
            self.venueOthersIcon.alpha = 0.0;
            self.venueOthers.text = @"";
            
        } else {
            // show the little man
            self.venueOthersIcon.alpha = 1.0;
            // otherwise put 1 other or x others here now
            self.venueOthers.text = [NSString stringWithFormat:@"%d %@ here now", self.othersAtPlace, self.othersAtPlace == 1 ? @"other" : @"others"];
        }
        
        self.firstLoad = NO;
    }    
    
    // animate the display of the venueView and availabilityView
    // if they aren't already on screen
    [CPUIHelper animatedEllipsisAfterLabel:self.checkedIn start:NO];
    [UIView animateWithDuration:0.4 animations:^{self.venueView.alpha = 1.0;}];
}

- (void)updateMapAndDistanceToUser
{
    if (!self.mapAndDistanceLoaded) {
        // make an MKCoordinate region for the zoom level on the map
        MKCoordinateRegion region = MKCoordinateRegionMake(self.user.location, MKCoordinateSpanMake(0.005, 0.005));
        [self.mapView setRegion:region];
        
        // this will always be the point on iPhones up to iPhone4
        // if this needs to be used on iPad we'll need to do this programatically or use an if-else
        CGPoint rightAndUp = CGPointMake(84, 232);
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:rightAndUp toCoordinateFromView:self.mapView];
        [self.mapView setCenterCoordinate:coordinate animated:NO];
        
        CLLocation *myLocation = [CPAppDelegate locationManager].location;
        CLLocation *otherUserLocation = [[CLLocation alloc] initWithLatitude:self.user.location.latitude longitude:self.user.location.longitude];
        NSString *distance = [CPUtils localizedDistanceofLocationA:myLocation awayFromLocationB:otherUserLocation];
        
        [self.scrollView insertSubview:self.mapView atIndex:0];
        self.distanceLabel.text = distance;
        [UIView animateWithDuration:0.3 animations:^{
            self.mapView.alpha = 1;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:1 animations:^{
                    self.distanceLabel.alpha = 1;
                    self.mapMarker.alpha = 1;
                }];
            }
        }];
        self.mapAndDistanceLoaded = YES;
    }
}

- (void)setUserStatusWithQuotes:(NSString *)status
{
    if ([self.user.status length] > 0 && self.user.checkedIn) {
        self.cardStatus.text = [NSString stringWithFormat:@"\"%@\"", status];
    } else {
        self.cardStatus.text = @"";
    }
}

- (void)placeUserDataOnProfile
{    
    // dismiss the SVProgressHUD if it's up
    [SVProgressHUD dismiss];
    
    [CPUIHelper profileImageView:self.cardImage
             withProfileImageUrl:self.user.photoURL];
    self.cardNickname.text = self.user.nickname;

    self.title = self.user.nickname;  

    self.cardJobPosition.text = self.user.jobTitle;
    
    [self setUserStatusWithQuotes:self.user.status];
        
    // if the user has an hourly rate then put it, otherwise it comes up as N/A
    if (self.user.hourlyRate) {
        self.resumeRate.text = self.user.hourlyRate;
    }

    self.resumeEarned.text = [NSString stringWithFormat:@"%d", self.user.totalHours];
    self.loveReceived.text = [self.user.reviews objectForKey:@"love_received"];
    
    dispatch_queue_t q_profile = dispatch_queue_create("com.candp.profile", NULL);
    dispatch_async(q_profile, ^{
        // load html into the bottom of the resume view for all the user data
        // get the mustache rendering off the main thread
        NSString *htmlString = [self htmlStringWithResumeText];
        [self updateResumeWithHTML:htmlString];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMapAndDistanceToUser];
            [self updateLastUserCheckin];
        });
    });
}

- (NSString *)htmlStringWithResumeText {
    if (!self.resumeHTML) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.user, @"user",nil];
        NSArray *reviews = [self.user.reviews objectForKey:@"rows"];
        
        NSDictionary *originalData = @{
            @"reviews": reviews,
            @"user_id": @(self.user.userID),
            @"server_api_url": [NSString stringWithFormat:@"%@api.php", kCandPWebServiceUrl]
        };
        NSError *error;
        NSString *originalDataJSON = [[NSString alloc] initWithData:
                                      [NSJSONSerialization dataWithJSONObject:originalData
                                                                      options:kNilOptions
                                                                        error:&error]
                                                           encoding:NSUTF8StringEncoding];
        
        [dictionary setValue:[NSNumber numberWithBool:reviews.count > 0] forKey:@"hasAnyReview"];
        [dictionary setValue:originalDataJSON forKey:@"originalData"];
        
        GRMustacheTemplate *template = [UserProfileViewController resumeTemplate];
        template.delegate = self;
        self.resumeHTML = [template renderObject:dictionary];
    }
    return self.resumeHTML;
}

- (void) updateResumeWithHTML:(NSString*)html
{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    [self.resumeWebView loadHTMLString:html baseURL:baseURL];
    NSLog(@"HTML updated.");
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    
    if ([url.scheme isEqualToString:@"favorite-venue-id"]) {
        NSInteger venueID = [url.host integerValue];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"venueID == %d", venueID];
        NSMutableArray *venues = self.user.favoritePlaces;
        [venues filterUsingPredicate:predicate];
        CPVenue *place = [venues objectAtIndex:0];
        
        CPVenue *activeVenue = [[CPAppDelegate settingsMenuController].mapTabController venueFromActiveVenues:venueID];
        if (activeVenue) {
            // we had this venue in the map dictionary of activeVenues so use that
            place = activeVenue;
        }
        
        VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        venueVC.venue = place;
        
        [self.navigationController pushViewController:venueVC animated:YES];
        
        return NO;
    }
    if ([url.scheme isEqualToString:@"linkedin-view"]) {
        [self performSegueWithIdentifier:@"ShowLinkedInProfileWebView" sender:self];
        return NO;
    }
    
    if ([url.scheme isEqualToString:@"recompute-webview-height"]) {
        [self performSelector:@selector(resetResumeWebViewHeight)
                   withObject:nil
                   afterDelay:0.05];
        return NO;
    }

    return YES;
}

- (void)resetResumeWebViewHeight
{
    self.resumeWebView.scrollView.scrollsToTop = NO;
    self.resumeWebView.userInteractionEnabled = YES;
    
    // resize the webView frame depending on the size of the content
    CGRect frame = self.resumeWebView.frame;
    frame.size.height = 1;
    self.resumeWebView.frame = frame;
    CGSize fittingSize = [self.resumeWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    self.resumeWebView.frame = frame;
    
    CGRect resumeFrame = self.resumeView.frame;
    resumeFrame.size.height = self.resumeWebView.frame.origin.y + fittingSize.height;
    self.resumeView.frame = resumeFrame;
    
    [CPUIHelper addShadowToView:self.resumeView color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    
    // if this is an f2f invite we need some extra height in the scrollview content size
    double f2fbar = 0;
    if (self.isF2FInvite) {
        f2fbar = 81;
    }
    
    // set the scrollview content size to accomodate for the resume data
    self.scrollView.contentSize = CGSizeMake(320, self.resumeView.frame.origin.y + self.resumeView.frame.size.height + 50 + f2fbar);
    
    self.blueOverlayExtend.frame = CGRectMake(0, 416, 320, self.scrollView.contentSize.height - 416);

    if (self.scrollToReviews) {
        self.scrollToReviews = NO;

        int offsetTop = [[self.resumeWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('reviews').offsetTop"] intValue];

        if (offsetTop > 0) {
            offsetTop += kResumeWebViewOffsetTop;
            int bottomOffset = (int) (self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
            [self.scrollView setContentOffset:CGPointMake(0, MIN(offsetTop, bottomOffset)) animated:YES];
        }
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [self resetResumeWebViewHeight];
    
    // add the blue overlay where the gradient ends
    [self.scrollView insertSubview:self.blueOverlayExtend atIndex:0];
    
    // call the JS function in the mustache file that will lazyload the images
    [aWebView stringByEvaluatingJavaScriptFromString:@"lazyLoad();"];

    // reveal the resume
    [UIView animateWithDuration:0.3 animations:^{
        self.resumeWebView.alpha = 1.0;
    }];
    
    [CPUIHelper animatedEllipsisAfterLabel:self.resumeLabel start:NO];
}

-(IBAction)plusButtonPressed:(id)sender {
    self.payButton.hidden = YES;
    
    // animate the spinning of the plus button and replacement by the minus button
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{ 
        self.plusButton.transform = CGAffineTransformMakeRotation(M_PI); 
        self.minusButton.transform = CGAffineTransformMakeRotation(M_PI);
        self.minusButton.alpha = 1.0;
    } completion: NULL];
    // alpha transition on the plus button so there isn't a gap where we see the background
    [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationCurveEaseInOut animations:^{
        self.plusButton.alpha = 0.0;
    } completion:NULL];
    // animation of menu buttons shooting out
    
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        if (self.user.isContact) {
            self.f2fButton.hidden = YES;
            self.goMenuBackground.transform = CGAffineTransformMakeTranslation(0, -110);
        } else {
            self.f2fButton.hidden = NO;
            self.f2fButton.transform = CGAffineTransformMakeTranslation(0, -165);            
            self.goMenuBackground.transform = CGAffineTransformMakeTranslation(0, -165);
        }
        self.chatButton.transform = CGAffineTransformMakeTranslation(0, -110);
        self.reviewButton.transform = CGAffineTransformMakeTranslation(0, -55);
        //self.payButton.transform = CGAffineTransformMakeTranslation(0, -55);
    } completion:^(BOOL finished){
        [self.view viewWithTag:1005].userInteractionEnabled = YES;
    }];
}

-(IBAction)minusButtonPressed:(id)sender {
    // animate the spinning of the minus button and replacement by the plus button
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{ 
        self.minusButton.transform = CGAffineTransformMakeRotation((M_PI*2)-0.0001); 
        self.plusButton.transform = CGAffineTransformMakeRotation((M_PI*2)-0.0001);
        self.plusButton.alpha = 1.0;
    } completion: NULL];
    // alpha transition on the minus button so there isn't a gap where we see the background
    [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationCurveEaseInOut animations:^{
        self.minusButton.alpha = 0.0;
    } completion:NULL];
    // animation of menu buttons being sucked back in
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        self.f2fButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.chatButton.transform = CGAffineTransformMakeTranslation(0, 0);
        //self.payButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.reviewButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.goMenuBackground.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished){
        [self.view viewWithTag:1005].userInteractionEnabled = NO;
    }];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ProfileToOneOnOneSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
        [self minusButtonPressed:nil];
    }
    else if ([[segue identifier] isEqualToString:@"ProfileToPayUserSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
        [self minusButtonPressed:nil];        
    } else if ([[segue identifier] isEqualToString:@"ShowLinkedInProfileWebView"]) {
        // set the linkedInPublicProfileUrl in the destination VC
        [[segue destinationViewController] setLinkedInProfileUrlAddress:self.user.linkedInPublicProfileUrl];
    } else if ([[segue identifier] isEqualToString:@"SendLoveToUser"]) {
        // hide the go menu
        [self minusButtonPressed:nil];  
        
        [[segue destinationViewController] setUser:self.user];
        [[segue destinationViewController] setDelegate:self];
    }
}

-(IBAction)venueViewButtonPressed:(id)sender {
    VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    venueVC.venue = self.user.placeCheckedIn;
    
    [self.navigationController pushViewController:venueVC animated:YES];
}

- (IBAction)chatButtonPressed:(id)sender
{
    if (self.user.contactsOnlyChat && !self.user.isContact && !self.user.hasChatHistory) {
        NSString *errorMessage = [NSString stringWithFormat:@"You can not chat with %@ until the two of you have exchanged contact information", self.user.nickname];
        [SVProgressHUD showErrorWithStatus:errorMessage
                                  duration:kDefaultDismissDelay];
    } else {
        [self performSegueWithIdentifier:@"ProfileToOneOnOneSegue" sender:sender];
    }
    [self minusButtonPressed:nil];
}

- (IBAction)f2fInvite {
    // use the FaceToFaceHelper to show the contact request UIActionSheet
    [[FaceToFaceHelper sharedHelper] showContactRequestActionSheetForUserID:self.user.userID];
    
    // drop the action menu
    [self minusButtonPressed:nil];
}

- (void)navigationBarTitleTap:(UIGestureRecognizer*)recognizer {
    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}

#pragma mark - properties

- (UIView *)blueOverlayExtend
{
    if (!_blueOverlayExtend) {
        UIView *blueOverlayExtend = [[UIView alloc] initWithFrame:CGRectMake(0, 416, 320, self.scrollView.contentSize.height - 416)];
        blueOverlayExtend.backgroundColor = [UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0];
        self.view.backgroundColor = blueOverlayExtend.backgroundColor;
    }
    return _blueOverlayExtend;
}

@end
