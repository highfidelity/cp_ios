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
#import "CPUtils.h"
#import "FoursquareAPIRequest.h"
#import "AFJSONRequestOperation.h"
#import "CPUIHelper.h"
#import "CPapi.h"

@interface UserProfileCheckedInViewController() <UIWebViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UILabel *checkedIn;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIView *userCard;
@property (nonatomic, weak) IBOutlet UIImageView *cardImage;
@property (nonatomic, weak) IBOutlet UILabel *cardStatus;
@property (nonatomic, weak) IBOutlet UILabel *cardNickname;
@property (nonatomic, weak) IBOutlet UILabel *cardJobPosition;
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
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *f2fButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UIImageView *goMenuBackground;

-(void)animateVenueLoadingPoints;
-(void)stopAnimatingVenueLoadingPoints;
-(NSString *)htmlStringWithResumeText;
-(IBAction)plusButtonPressed:(id)sender;
-(IBAction)minusButtonPressed:(id)sender;
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
@synthesize plusButton = _plusButton;
@synthesize minusButton = _minusButton;
@synthesize f2fButton = _f2fButton;
@synthesize chatButton = _chatButton;
@synthesize payButton = _payButton;
@synthesize goMenuBackground = _goMenuBackground;
@synthesize loadingPt1 = _loadingPt1;
@synthesize loadingPt2 = _loadingPt2;
@synthesize loadingPt3 = _loadingPt3;
@synthesize cardJobPosition = _cardJobPosition;
@synthesize isF2FInvite = _isF2FInvite;

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
    
    // hide the go menu if this profile is current user's profile
    if (self.user.userID == [[[AppDelegate instance].settings candpUserId] intValue] || self.isF2FInvite) {
        for (NSNumber *viewID in [NSArray arrayWithObjects:[NSNumber numberWithInt:1005], [NSNumber numberWithInt:1006], [NSNumber numberWithInt:1007], [NSNumber numberWithInt:1008], [NSNumber numberWithInt:1009], [NSNumber numberWithInt:1010], nil]) {
            [[self.view viewWithTag:[viewID intValue]] removeFromSuperview];
        }
    }
    
    // add the blue overlay gradient in front of the map
    UIView *blueOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.mapView.frame.size.width, self.mapView.frame.size.height)];
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
    
    // set the paper background color where applicable
    UIColor *paper = [UIColor colorWithPatternImage:[UIImage imageNamed:@"paper-texture.jpg"]];
    self.userCard.backgroundColor = paper;
    self.resumeView.backgroundColor = paper;
    self.resumeWebView.opaque = NO;
    self.resumeWebView.backgroundColor = paper;
    
    [CPUIHelper addShadowToView:self.userCard color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    
    // make an MKCoordinate region for the zoom level on the map
    MKCoordinateRegion region = MKCoordinateRegionMake(self.user.location, MKCoordinateSpanMake(0.005, 0.005));
    [self.mapView setRegion:region];
    
    // this will always be the point on iPhones up to iPhone4
    // if this needs to be used on iPad we'll need to do this programatically or use an if-else
    CGPoint rightAndUp = CGPointMake(84, 232);
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:rightAndUp toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
        
    // animate the three dots after checked in
    [self animateVenueLoadingPoints];
    
    // set the labels on the user business card
    self.cardNickname.text = [self.user.nickname uppercaseString];
    self.cardStatus.text = [NSString stringWithFormat:@"\"%@\"", self.user.status];
    
    // if we have a location from this user then set the distance label to show how far the other user is
    if ([AppDelegate instance].settings.hasLocation) {
        CLLocation *myLocation = [[AppDelegate instance].settings lastKnownLocation];
        CLLocation *otherUserLocation = [[CLLocation alloc] initWithLatitude:self.user.location.latitude longitude:self.user.location.longitude];
        NSString *distance = [CPUtils localizedDistanceofLocationA:myLocation awayFromLocationB:otherUserLocation];
        self.distanceLabel.text = distance;
    }
    
    // check if this is an F2F invite
    if (self.isF2FInvite) {
        // we're in an F2F invite
        [self placeUserDataOnProfile];
    } else {
        // set the navigation controller title to the user's nickname
        self.title = self.user.nickname;
        // get a user object with resume data
        [self.user loadUserResumeData:^(User *user, NSError *error) {
            if (!error) {
                self.user = user;
                [self placeUserDataOnProfile];
            } else {
                // error checking for load of user 
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.isF2FInvite) {
        // make sure the check in button is on screen
        [[AppDelegate instance] showCheckInButton];
    }    
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
    [self setPlusButton:nil];
    [self setMinusButton:nil];
    [self setF2fButton:nil];
    [self setChatButton:nil];
    [self setPayButton:nil];
    [self setGoMenuBackground:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)placeUserDataOnProfile
{
    
    self.cardJobPosition.text = self.user.jobTitle;
    // set the card image to the user's profile image
    [self.cardImage  setImageWithURL:self.user.urlPhoto];
    
    // if the user is checked in show how much longer they'll be available for
    if ([self.user.checkoutEpoch timeIntervalSinceNow] > 0) {
        self.checkedIn.text = @"CHECKED IN";
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
        // change the label since the user isn't here anymore
        self.checkedIn.text = @"WAS CHECKED IN";
        
        // move the loading points to the right so they're in the right spot
        NSArray *pts = [NSArray arrayWithObjects:self.loadingPt1, self.loadingPt2, self.loadingPt3, nil];
        for (UILabel *pt in pts) {
            CGRect ptFrame = pt.frame;
            ptFrame.origin.x += 33;
            pt.frame = ptFrame;    
        }
        
        
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
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    [self.resumeWebView loadHTMLString:[self htmlStringWithResumeText] baseURL:baseURL];
    
    // TODO: get venue name and venue address from list cell or map annotation this profile was pulled up from
    // venue name should already be there, address needs to be added in return from api.php
    
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
}

- (NSString *)htmlStringWithResumeText {
    NSMutableArray *resumeHtml = [NSMutableArray array];
    // beginning of the string is styling info
    [resumeHtml addObject:@"<style type='text/css'>body {font-family: Helvetica; font-size: 11pt; color: rgb(68,68,68); padding: 5pt 5pt; word-wrap: break-word;} .listing {width: 150pt; padding: 5pt 5pt 5pt 0pt; border-right: 1pt solid #C1C1C1;} .price {padding-left: 5pt;} table {font-size: 11pt; border-collapse: collapse;} th {text-align: left; padding-bottom: 5pt;} td {border-top: 1pt solid #C1C1C1;} a {color: #333;} #more_reviews a {display:inline-block; width: 100%; text-align: center} #more_reviews {padding: 0;margin: 0 0 15px;} </style>\n"];
    
    [resumeHtml addObject:[NSString stringWithFormat:@"<p><b>Joined:</b> %@</p>", self.user.join_date]];
    // add the bio if we have it
    if (self.user.bio.length > 0) {
        [resumeHtml addObject:[NSString stringWithFormat:@"<p><b>Bio:</b> %@</p>", self.user.bio]];
    }
    
    // user work information
    if (self.user.workInformation.count > 0) {
        // add the title
        [resumeHtml addObject:@"<p><b>Work</b></p>"];
        // go through each position in the workInformation array
        for (NSDictionary *position in self.user.workInformation) {
            // setup the div for each position
            [resumeHtml addObject:@"<div>"];
            // show the title beside the company if we have it
            if (![[position objectForKey:@"title"] isKindOfClass:[NSNull class]]) {
                [resumeHtml addObject:[NSString stringWithFormat:@"%@ at %@", [position objectForKey:@"title"], [position objectForKey:@"company"]]];
            } else {
                // otherwise just the company
                [resumeHtml addObject:[position objectForKey:@"company"]];
            }
            // if we have a start date show it alongside the end date
            if (![[position objectForKey:@"startDate"] isKindOfClass:[NSNull class]]) {
                [resumeHtml addObject:[NSString stringWithFormat:@" from %@ to %@", [position objectForKey:@"startDate"], [position objectForKey:@"endDate"]]];
            }
            // close the div
            [resumeHtml addObject:@"</div>"];
        }
    }
    
    // user education
    if (self.user.educationInformation.count > 0) {
        // add the title
        [resumeHtml addObject:@"<p><b>Education</b></p>"];
        // go through each school in educationInformation array (in reverse for the right chronological order)
        for (NSDictionary *school in [self.user.educationInformation reverseObjectEnumerator]) {
            // setup the div for each school
            [resumeHtml addObject:@"<div>"];
            // put the school name
            [resumeHtml addObject:[school objectForKey:@"school"]];
            // if we have an end date show it
            if (![[school objectForKey:@"endDate"] isKindOfClass:[NSNull class]]) {
                // show it with the start date if we have it
                if (![[school objectForKey:@"startDate"] isKindOfClass:[NSNull class]]) {
                    [resumeHtml addObject:[NSString stringWithFormat:@", %@-%@", [school objectForKey:@"startDate"], [school objectForKey:@"endDate"]]];
                } else {
                    // otherwise show it by itself
                    [resumeHtml addObject:[NSString stringWithFormat:@", %@", [school objectForKey:@"endDate"]]];
                }
            }
            // show the degree if we have it
            if (![[school objectForKey:@"degree"] isKindOfClass:[NSNull class]]) {
                // show it with the concentrations if we have them
                if (![[school objectForKey:@"concentrations"] isKindOfClass:[NSNull class]]) {
                    [resumeHtml addObject:[NSString stringWithFormat:@"</br>%@, %@", [school objectForKey:@"degree"], [school objectForKey:@"concentrations"]]];
                } else {
                    [resumeHtml addObject:[NSString stringWithFormat:@"</br>%@", [school objectForKey:@"degree"]]];
                }
            }
            // otherwise check if we just have the concentration
            else if (![[school objectForKey:@"concentrations"] isKindOfClass:[NSNull class]]) {
                [resumeHtml addObject:[NSString stringWithFormat:@"</br>%@", [school objectForKey:@"concentrations"]]];
            }
            // close the div
            [resumeHtml addObject:@"</div>"];
        }
    }
    
    // add user trust information
    [resumeHtml addObject:[NSString stringWithFormat:@"<p><b>Trusted by %d people</b></p>", self.user.trusted_by]];
    
    //reviews
    int total_reviews = [[[[self user] reviews] objectForKey:@"records"] intValue];
    if (total_reviews > 0) {
        [resumeHtml addObject:@"<p><b>Reviews</b></p>"];
        
        int review_row = 0;
        
        for (NSDictionary *review in [[[self user] reviews] objectForKey:@"rows"]) {
            review_row++;
            
            if (review_row == 6) {
                NSString *more_link = @"<p id='more_reviews'><a href='javascript:document.getElementById(\"more_reviews\").style.display=\"none\";document.getElementById(\"extra_reviews\").style.display=\"block\";'>more reviews</a></p>";
                [resumeHtml addObject: more_link];
                [resumeHtml addObject: @"<div style='display: none;' id='extra_reviews'>"];
            }
            
            NSString *ratingImg = @"thumbs-up.png";
            
            if ([[review objectForKey:@"rating"] intValue] == -1) {
                ratingImg = @"thumbs-down.png";
            }
            
            [resumeHtml addObject:[NSString 
                                   stringWithFormat:@"<p><img src='%@' width='12' height='14'/> \"%@\"</p>", ratingImg, [review objectForKey:@"review"]]];
        }
        
        if (review_row > 5) {
            [resumeHtml addObject: @"</div>"];
        }
        
        [resumeHtml addObject: @"<br/>"];
    }
    
    // show listings as Agent in a table
    if (self.user.listingsAsAgent.count > 0) {
        [resumeHtml addObject:@"<table><tr><th>Listing as Agent</th><th>Price</th></tr>"];
        for (NSDictionary *agentListing in self.user.listingsAsAgent) {
            [resumeHtml addObject:[NSString stringWithFormat:@"<tr><td class='listing'>\"%@\"</td>", [agentListing objectForKey:@"listing"]]];
            [resumeHtml addObject:[NSString stringWithFormat:@"<td class='price'>$%@</td></tr>", [agentListing objectForKey:@"price"]]];
        }
        [resumeHtml addObject:@"</table></br>"];
    }
    
    // show listings as Client in a table
    if (self.user.listingsAsClient.count > 0) {
        [resumeHtml addObject:@"<table><tr><th>Listing as Client</th><th>Price</th></tr>"];
        for (NSDictionary *clientListing in self.user.listingsAsClient) {
            [resumeHtml addObject:[NSString stringWithFormat:@"<tr><td class='listing'>\"%@\"</td>", [clientListing objectForKey:@"listing"]]];
            [resumeHtml addObject:[NSString stringWithFormat:@"<td class='price'>$%@</td></tr>", [clientListing objectForKey:@"price"]]];
        }
        [resumeHtml addObject:@"</table></br>"];
    }
    // return the HTML by joining the array into a string
    return [resumeHtml componentsJoinedByString:@""];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    // resize the webView frame depending on the size of the content
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    aWebView.frame = frame;
    
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
    
    // add the blue overlay where the gradient ends
    UIView *blueOverlayExtend = [[UIView alloc] initWithFrame:CGRectMake(0, 416, 320, self.scrollView.contentSize.height - 416)];
    blueOverlayExtend.backgroundColor = [UIColor colorWithRed:0.67 green:0.83 blue:0.94 alpha:1.0];
    [self.scrollView insertSubview:blueOverlayExtend atIndex:0];
    // show the resume now that all the data is there
    [UIView animateWithDuration:0.4 animations:^{self.resumeView.alpha = 1.0;}];
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

-(IBAction)plusButtonPressed:(id)sender {
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
        self.f2fButton.transform = CGAffineTransformMakeTranslation(0, -165);
        self.chatButton.transform = CGAffineTransformMakeTranslation(0, -110);
        self.payButton.transform = CGAffineTransformMakeTranslation(0, -55);
        self.goMenuBackground.transform = CGAffineTransformMakeTranslation(0, -165);
    } completion:NULL];
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
        self.payButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.goMenuBackground.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:NULL];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ProfileToOneOnOneSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
        [self minusButtonPressed:nil];
        [[AppDelegate instance] hideCheckInButton];
    }
    else if ([[segue identifier] isEqualToString:@"ProfileToPayUserSegue"])
    {
        [[segue destinationViewController] setUser:self.user];
        [self minusButtonPressed:nil];        
    }
}

- (IBAction)f2fInvite {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Send Face to Face invite?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Send"
                                  otherButtonTitles: nil
                                  ];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([actionSheet title] == @"Send Face to Face invite?") {
        [self minusButtonPressed:nil];
        if (buttonIndex != [actionSheet cancelButtonIndex]) {
            [CPapi sendF2FInvite:self.user.userID];
        }
    }
}

@end
