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
#import "CPUserAction.h"
#import "CPMarkerManager.h"
#import "UIViewController+CPUserActionCellAdditions.h"

#define kResumeWebViewOffsetTop 304

@interface UserProfileViewController() <UIWebViewDelegate, UIActionSheetDelegate>

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
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UILabel *propNoteLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mapMarker;
@property (weak, nonatomic) IBOutlet CPUserActionCell *userActionCell;
@property (weak, nonatomic) UIView *blueOverlayExtend;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL firstLoad;
@property (nonatomic) int othersAtPlace;
@property (nonatomic) NSInteger selectedFavoriteVenueIndex;
@property (nonatomic) BOOL mapAndDistanceLoaded;

-(NSString *)htmlStringWithResumeText;
-(IBAction)venueViewButtonPressed:(id)sender;

@end

@implementation UserProfileViewController

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
    
    // set the navigation controller title to the user's nickname
    self.title = self.user.nickname;
    
    // set the booleans this VC uses in later control statements
    self.firstLoad = YES;
    self.mapAndDistanceLoaded = NO;
    
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
    
    self.userActionCell.user = self.user;
    self.userActionCell.delegate = self;
    
    // set the labels on the user business card
    self.cardNickname.text = self.user.nickname;
    [self setUserStatusWithQuotes:self.user.lastCheckIn.statusText];
    self.cardJobPosition.text = self.user.jobTitle;
    
    // set the card image to the user's profile image
    [CPUIHelper profileImageView:self.cardImage
             withProfileImageUrl:self.user.photoURL];
    
    // don't allow scrolling in the mustache view until it's loaded
    self.resumeWebView.userInteractionEnabled = NO;
    
    if (self.isF2FInvite) {
        self.userActionCell.rightStyle = CPUserActionCellSwipeStyleNone;
        
        // we're in an F2F invite
        [self placeUserDataOnProfile];
    } else {
        // lock the scrollView
        self.scrollView.scrollEnabled = NO;
        
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // when pulling the scroll view top down, present the map
    self.mapView.frame = CGRectUnion(self.mapView.frame,
                                     CGRectOffset(self.mapView.frame, 0, -self.mapView.frame.size.height));
    
    // add the blue overlay gradient in front of the map
    [self addGradientWithFrame:self.mapView.frame
                     locations:@[[NSNumber numberWithFloat:0.25],
                                 [NSNumber numberWithFloat:0.30],
                                 [NSNumber numberWithFloat:0.5],
                                 [NSNumber numberWithFloat:0.90],
                                 [NSNumber numberWithFloat:1.0]]
                        colors:@[(id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0] CGColor],
                                 (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:0.75] CGColor],
                                 (id)[[UIColor colorWithRed:0.40 green:0.62 blue:0.64 alpha:0.4] CGColor],
                                 (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:0.75] CGColor],
                                 (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0] CGColor]]
     ];
    
    // make sure there's a shadow on the userCard and resumeView
    [CPUIHelper addShadowToView:self.userCard color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    [CPUIHelper addShadowToView:self.resumeView color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    
    // check if this is an F2F invite
    if (!self.isF2FInvite) {     
        // put three animated dots after the Loading Resume text
        [CPUIHelper animatedEllipsisAfterLabel:self.resumeLabel start:YES];
        [CPUIHelper animatedEllipsisAfterLabel:self.checkedIn start:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.isF2FInvite) {
        [self animateSlideWaveWithCPUserActionCells:@[self.userActionCell]];
    }
    
    // custom back button to allow event capture
    
    if(!_tapRecon){
        _tapRecon = [[UITapGestureRecognizer alloc]
                     initWithTarget:self action:@selector(navigationBarTitleTap:)];
        _tapRecon.numberOfTapsRequired = 1;
        _tapRecon.cancelsTouchesInView = NO;
        [self.navigationController.navigationBar addGestureRecognizer:_tapRecon];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar removeGestureRecognizer:_tapRecon];
    self.tapRecon = nil;
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
        if ([self.user.lastCheckIn.checkoutDate timeIntervalSinceNow] > 0) {
            self.checkedIn.text = @"Checked in";
            // get the number of seconds until they'll checkout
            NSTimeInterval secondsToCheckout = [self.user.lastCheckIn.checkoutDate timeIntervalSinceNow];
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
    
    self.venueName.text = self.user.lastCheckIn.venue.name;
    self.venueAddress.text = self.user.lastCheckIn.venue.address;
    
    self.othersAtPlace = self.user.lastCheckIn.isCurrentlyCheckedIn
        ? [self.user.lastCheckIn.venue.checkedInNow intValue] - 1
        : [self.user.lastCheckIn.venue.checkedInNow intValue];
    
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
        
        // use method in CPUIHelper to shift the map to the right spot
        [CPUIHelper shiftMapView:self.mapView forPinCenterInMapview:[self.mapView convertPoint:self.mapMarker.center fromView:self.scrollView]];
        
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
    if (status.length > 0 && self.user.lastCheckIn.isCurrentlyCheckedIn) {
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
    
    [self setUserStatusWithQuotes:self.user.lastCheckIn.statusText];
        
    // if the user has an hourly rate then put it, otherwise it comes up as N/A
    if (self.user.hourlyRate) {
        self.resumeRate.text = self.user.hourlyRate;
    }

    self.resumeEarned.text = [NSString stringWithFormat:@"%d", self.user.totalHours];
    self.loveReceived.text = [self.user.reviews objectForKey:@"love_received"];
    
    if ([self.user.isContact boolValue]) {
        self.userActionCell.rightStyle = CPUserActionCellSwipeStyleReducedAction;
    }
    
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

- (NSString *)htmlStringWithResumeText
{
    if (!self.resumeHTML) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.user, @"user",nil];
        NSArray *reviews = [self.user.reviews objectForKey:@"rows"];
        
        NSDictionary *originalData = @{
            @"reviews": reviews,
            @"user_id": self.user.userID,
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
        
        NSError *mustacheError;       
        self.resumeHTML = [GRMustacheTemplate renderObject:dictionary fromResource:@"UserResume" bundle:nil error:&mustacheError];
        
#if DEBUG
        if (mustacheError) {
            NSLog(@"Error mustaching user resume: %@", mustacheError.localizedDescription);
        }
#endif
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
        NSNumber *venueID = @([url.host integerValue]);
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"venueID == %@", venueID];
        NSMutableArray *venues = self.user.favoritePlaces;
        [venues filterUsingPredicate:predicate];
        CPVenue *place = [venues objectAtIndex:0];
        
        CPVenue *activeVenue = [[CPMarkerManager sharedManager] markerVenueWithID:venueID];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ProfileToOneOnOneSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
    }
    else if ([[segue identifier] isEqualToString:@"ProfileToPayUserSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
    } else if ([[segue identifier] isEqualToString:@"ShowLinkedInProfileWebView"]) {
        // set the linkedInPublicProfileUrl in the destination VC
        [[segue destinationViewController] setLinkedInProfileUrlAddress:self.user.linkedInPublicProfileUrl];
    } else if ([[segue identifier] isEqualToString:@"SendLoveToUser"]) {
        [[segue destinationViewController] setUser:self.user];
        [[segue destinationViewController] setDelegate:self];
    }
}

-(IBAction)venueViewButtonPressed:(id)sender {
    VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    CPVenue *markerVenue = [[CPMarkerManager sharedManager] markerVenueWithID:self.user.lastCheckIn.venue.venueID];
    
    venueVC.venue = markerVenue ? markerVenue : self.user.lastCheckIn.venue;
    
    [self.navigationController pushViewController:venueVC animated:YES];
}

- (void)navigationBarTitleTap:(UIGestureRecognizer*)recognizer {
    [_scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}


#pragma mark - CPUserActionCellDelegate

- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(CPUser *)user
{
    [CPUserAction cell:cell sendLoveFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(CPUser *)user
{
    [CPUserAction cell:cell sendMessageFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(CPUser *)user
{
    [CPUserAction cell:cell exchangeContactsFromViewController:self];
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
