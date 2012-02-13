//
//  UserProfileCheckedInViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserProfileCheckedInViewController.h"
#import "AFHTTPClient.h"
#import "UIImageView+WebCache.h"
#import "AppDelegate.h"
#import "LocalizedDistanceCalculator.h"
#import "FoursquareAPIRequest.h"
#import "AFJSONRequestOperation.h"
#import <QuartzCore/QuartzCore.h>

@interface UserProfileCheckedInViewController() <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UILabel *checkedIn;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIView *userCard;
@property (nonatomic, weak) IBOutlet UIImageView *cardImage;
@property (nonatomic, weak) IBOutlet UILabel *cardStatus;
@property (nonatomic, weak) IBOutlet UILabel *cardNickname;
@property (nonatomic, weak) IBOutlet UIView *venueView;
@property (nonatomic, weak) IBOutlet UIImageView *venueIcon;
@property (nonatomic, weak) IBOutlet UILabel *venueName;
@property (nonatomic, weak) IBOutlet UILabel *venueAddress;
@property (nonatomic, weak) IBOutlet UIImageView *venueOthersIcon;
@property (nonatomic, weak) IBOutlet UILabel *venueOthers;
@property (nonatomic, weak) IBOutlet UIView *availabilityView;
@property (nonatomic, weak) IBOutlet UILabel *loadingPt1;
@property (nonatomic, weak) IBOutlet UILabel *loadingPt2;
@property (nonatomic, weak) IBOutlet UILabel *loadingPt3;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UILabel *hoursAvailable;
@property (nonatomic, weak) IBOutlet UILabel *minutesAvailable;
@property (weak, nonatomic) IBOutlet UIView *resumeView;
@property (weak, nonatomic) IBOutlet UILabel *resumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *resumeRate;
@property (weak, nonatomic) IBOutlet UILabel *resumeEarned;
@property (weak, nonatomic) IBOutlet UILabel *resumeSpent;
@property (weak, nonatomic) IBOutlet UIWebView *resumeWebView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookVerified;
@property (weak, nonatomic) IBOutlet UIImageView *linkedinVerified;

-(void)animateVenueLoadingPoints;
-(void)stopAnimatingVenueLoadingPoints;
-(NSString *)htmlStringWithResumeText;
@end

@implementation UserProfileCheckedInViewController

@synthesize scrollView = _scrollView;
@synthesize checkedIn = _checkedIn;
@synthesize mapView = _mapView;
@synthesize user = _user;
@synthesize userCard = _userCard;
@synthesize cardImage = _cardImage;
@synthesize cardStatus = _cardStatus;
@synthesize cardNickname = _cardNickname;
@synthesize distanceLabel = _distanceLabel;
@synthesize venueView = _venueView;
@synthesize venueIcon = _venueIcon;
@synthesize venueName = _venueName;
@synthesize venueAddress = venueAddress;
@synthesize venueOthersIcon = _venueOthersIcon;
@synthesize venueOthers = venueOthers;
@synthesize availabilityView = _availabilityView;
@synthesize hoursAvailable = _hoursAvailable;
@synthesize minutesAvailable = _minutesAvailable;
@synthesize resumeView = _resumeView;
@synthesize resumeLabel = _resumeLabel;
@synthesize resumeRate = _resumeRate;
@synthesize resumeEarned = _resumeEarned;
@synthesize resumeSpent = _resumeSpent;
@synthesize resumeWebView = _resumeWebView;
@synthesize facebookVerified = _facebookVerified;
@synthesize linkedinVerified = _linkedinVerified;
@synthesize loadingPt1 = _loadingPt1;
@synthesize loadingPt2 = _loadingPt2;
@synthesize loadingPt3 = _loadingPt3;


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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // set the webview delegate to this VC so we can resize it based on the contents
    self.resumeWebView.delegate = self;
    
    // add the blue overlay gradient in front of the map
    UIView *blueOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = blueOverlay.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.40 green:0.62 blue:0.64 alpha:0.4] CGColor],
                       (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:0.75] CGColor],
                       (id)[[UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0] CGColor],
                       nil];
    gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.80], [NSNumber numberWithFloat:1.0], nil];
    [blueOverlay.layer insertSublayer:gradient atIndex:0];
    [self.scrollView insertSubview:blueOverlay atIndex:1];
        
    // set LeagueGothic font where applicable
    UIFont *gothic = [UIFont fontWithName:@"LeagueGothic" size:24.f];
    for (UILabel *labelNeedsGothic in [NSArray arrayWithObjects:self.checkedIn, self.loadingPt1, self.loadingPt2, self.loadingPt3, self.cardNickname, self.resumeLabel, nil]) {
        labelNeedsGothic.font = gothic;
    }
    
    // set the navigation controller title to the user's nickname
    self.title = self.user.nickname;
    
    // set the paper background color where applicable
    UIColor *paper = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper-texture.jpg"]];
    self.userCard.backgroundColor = paper;
    self.resumeView.backgroundColor = paper;
    self.resumeWebView.opaque = NO;
    self.resumeWebView.backgroundColor = paper;
    
    // shadow on business card and resume
    CGColorRef shadowColor = [[UIColor blackColor] CGColor];
    CGSize shadowOffset = CGSizeMake(2,2);
    double shadowRadius = 3;
    double shadowOpacity = 0.38;
    for (UIView *needsShadow in [NSArray arrayWithObjects:self.userCard, self.resumeView, nil]) {
        needsShadow.layer.shadowColor = shadowColor;
        needsShadow.layer.shadowOffset = shadowOffset;
        needsShadow.layer.shadowRadius = shadowRadius;
        needsShadow.layer.shadowOpacity = shadowOpacity;
    }   
    
    // make an MKCoordinate region for the zoom level on the map
    MKCoordinateRegion region = MKCoordinateRegionMake(self.user.location, MKCoordinateSpanMake(0.005, 0.005));
    [self.mapView setRegion:region];
    
    // this will always be the point on iPhones up to iPhone4
    // if this needs to be used on iPad we'll need to do this programatically or use an if-else
    CGPoint rightAndUp = CGPointMake(123, 230);
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:rightAndUp toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    
    
    if (!self.user.checkedIn) {
        // change the label since the user isn't here anymore
        self.checkedIn.text = @"WAS CHECKED IN";
       
        // move the loading points to the right so they're in the right spot
        NSArray *pts = [NSArray arrayWithObjects:self.loadingPt1, self.loadingPt2, self.loadingPt3, nil];
        for (UILabel *pt in pts) {
            CGRect ptFrame = pt.frame;
            ptFrame.origin.x += 33;
            pt.frame = ptFrame;    
        }
    }
    
    // animate the three dots after checked in
    [self animateVenueLoadingPoints];
    
    // set the labels on the user business card
    self.cardNickname.text = [self.user.nickname uppercaseString];
    self.cardStatus.text = [NSString stringWithFormat:@"\"%@\"", self.user.status];
    
    // if we have a location from this user then set the distance label to show how far the other user is
    if ([AppDelegate instance].settings.hasLocation) {
        CLLocation *myLocation = [[AppDelegate instance].settings lastKnownLocation];
        CLLocation *otherUserLocation = [[CLLocation alloc] initWithLatitude:self.user.location.latitude longitude:self.user.location.longitude];
        NSString *distance = [LocalizedDistanceCalculator localizedDistanceBetweenLocationA:myLocation andLocationB:otherUserLocation];
        self.distanceLabel.text = distance;
    }
    
    // get a user object with resume data
    [self.user loadUserResumeData:^(User *user, NSError *error) {
        if (!error) {
            self.user = user;  
            // set the card image to the user's profile image
            [self.cardImage  setImageWithURL:self.user.urlPhoto];
                        
            // if the user is checked in show how much longer they'll be available for
            if (self.user.checkedIn) {
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
                    // otherwise show just the minutes, move it so it's where hours would be
                    CGRect minutesFrame = self.minutesAvailable.frame;
                    minutesFrame.origin = self.hoursAvailable.frame.origin;
                    self.minutesAvailable.frame = minutesFrame;
                    self.minutesAvailable.font = [UIFont boldSystemFontOfSize:self.minutesAvailable.font.pointSize];
                }            
                self.minutesAvailable.text = [NSString stringWithFormat:@"%d mins", minutesToHour];
            } else {
                // otherwise don't show the availability view
                [self.availabilityView removeFromSuperview];
            }
            
            // hide the icons for which the user isn't verified
            if (!self.user.facebookVerified) {
                [self.facebookVerified removeFromSuperview];
                if (!self.user.linkedInVerified) {
                    [self.linkedinVerified removeFromSuperview];
                }
            } else if (!self.user.linkedInVerified) {
                self.facebookVerified.frame = self.linkedinVerified.frame;
                [self.linkedinVerified removeFromSuperview];
            }
            
            // if the user has an hourly rate then put it, otherwise it comes up as N/A
            if (self.user.hourlyRate) {
                self.resumeRate.text = self.user.hourlyRate;
            }            
            
            // show total spent and total earned   
            NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
            [decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            self.resumeEarned.text = [@"$" stringByAppendingString:[decimalFormatter stringFromNumber:[NSNumber numberWithDouble:self.user.totalEarned]]];
            self.resumeSpent.text = [@"$" stringByAppendingString:[decimalFormatter stringFromNumber:[NSNumber numberWithDouble:self.user.totalSpent]]];
            
            // load html into the bottom of the resume view for all the user data
            [self.resumeWebView loadHTMLString:[self htmlStringWithResumeText] baseURL:nil];
                        
            // show the resume now that all the data is there
            [UIView animateWithDuration:0.4 animations:^{self.resumeView.alpha = 1.0;}];
            
            // request using the FoursquareAPIRequest class to get the venue data
            [FoursquareAPIRequest dictForVenueWithFoursquareID:self.user.placeCheckedIn.foursquareID :^(NSDictionary *fsDict, NSError *error) {
                if (!error) {
                    // show the available for and the venue info, stop animating the ellipsis
                    [self stopAnimatingVenueLoadingPoints];
                    
                    // set the CPPlace data on the user object we're holding
                    self.user.placeCheckedIn.name = [fsDict valueForKeyPath:@"response.venue.name"];
                    self.user.placeCheckedIn.address = [fsDict valueForKeyPath:@"response.venue.location.address"];
                   
                    // put it on the view
                    self.venueName.text = self.user.placeCheckedIn.name;
                    self.venueAddress.text = self.user.placeCheckedIn.address;
                    if (self.user.placeCheckedIn.othersHere == 0) {
                        // hide the little man, nobody else is here
                        [self.venueOthersIcon removeFromSuperview];
                        
                        // move the data in the venueView down so it's vertically centered
                        NSArray *venueInfo = [NSArray arrayWithObjects:self.venueIcon, self.venueName, self.venueAddress, nil];
                        for (UIView *venueItem in venueInfo) {
                            CGRect frame = venueItem.frame;
                            frame.origin.y += 8;
                            venueItem.frame = frame;
                        }
                    } else {
                        // otherwise put 1 other or x others here now
                        self.venueOthers.text = [NSString stringWithFormat:@"%d %@ here now", self.user.placeCheckedIn.othersHere, self.user.placeCheckedIn.othersHere == 1 ? @"other" : @"others"];
                    }           
                    // animate the display of the venueView and availabilityView
                    [UIView animateWithDuration:0.4 animations:^{self.venueView.alpha = 1.0; self.availabilityView.alpha = 1.0;}];
                } else {
                    // error for load of foursquare data
                }
            }];            
        } else {
            // error checking for load of user 
        }
    }];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setCheckedIn:nil];
    [self setMapView:nil];
    [self setUserCard:nil];
    [self setCardImage:nil];
    [self setCardStatus:nil];
    [self setCardNickname:nil];
    [self setVenueView:nil];
    [self setVenueIcon:nil];
    [self setVenueName:nil];
    [self setVenueAddress:nil];
    [self setVenueOthersIcon:nil];
    [self setVenueOthers:nil];
    [self setAvailabilityView:nil];
    [self setLoadingPt1:nil];
    [self setLoadingPt2:nil];
    [self setLoadingPt3:nil];
    [self setDistanceLabel:nil];
    [self setHoursAvailable:nil];
    [self setMinutesAvailable:nil];
    [self setResumeLabel:nil];
    [self setResumeView:nil];
    [self setResumeRate:nil];
    [self setResumeEarned:nil];
    [self setResumeSpent:nil];
    [self setFacebookVerified:nil];
    [self setLinkedinVerified:nil];
    [self setScrollView:nil];
    [self setResumeWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSString *)htmlStringWithResumeText {
    // beginning of the string is styling info
    NSString *html = @"<style type='text/css'>body {font-family: Helvetica; font-size: 15px; color: rgb(68,68,68); padding: 5px 5px;}</style>\n";
    // add the bio if we have it
    if (self.user.bio.length > 0) {
        html = [html stringByAppendingString:[NSString stringWithFormat:@"<p><b>Bio:</b> %@</p>", self.user.bio]];
    }
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p><b>Trusted by %d people</b></p>", self.user.trusted_by]];
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p><b>Joined:</b> %@</p>", self.user.join_date]];
    return html;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    // resize the webView frame depending on the size of the content
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    aWebView.frame = frame;
    
    // set the content size on the scrollview so we can actually scroll
    self.scrollView.contentSize = CGSizeMake(320, self.resumeView.frame.origin.y + self.resumeWebView.frame.origin.y + fittingSize.height + 50);
    // add the blue overlay where the gradient ends
    UIView *blueOverlayExtend = [[UIView alloc] initWithFrame:CGRectMake(0, 416, 320, self.scrollView.contentSize.height - 416)];
    blueOverlayExtend.backgroundColor = [UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0];
    [self.scrollView insertSubview:blueOverlayExtend atIndex:0];
}

-(void)animateVenueLoadingPoints
{
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{self.loadingPt1.alpha = 1.0;} completion:NULL];
    [UIView animateWithDuration:0.5 delay:0.25 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{self.loadingPt2.alpha = 1.0;} completion:NULL];
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{self.loadingPt3.alpha = 1.0;} completion:NULL];
}

-(void)stopAnimatingVenueLoadingPoints
{
    [self.loadingPt1.layer removeAllAnimations];
    [self.loadingPt2.layer removeAllAnimations];
    [self.loadingPt3.layer removeAllAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
