//
//  CheckInDetailsViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckInDetailsViewController.h"
#import "VenueInfoViewController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "UIViewController+isModal.h"
#import "CPCheckinHandler.h"
#import "CPApiClient.h"

@interface CheckInDetailsViewController() <UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSMutableArray *userArray;
@property (weak, nonatomic) IBOutlet UIView *blueOverlay;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *otherUsersScrollView;
@property (weak, nonatomic) IBOutlet UIView *venueInfo;
@property (weak, nonatomic) IBOutlet UILabel *checkInLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (weak, nonatomic) IBOutlet UILabel *placeAddress;
@property (weak, nonatomic) IBOutlet UIView *checkInDetails;
@property (weak, nonatomic) IBOutlet UILabel *willLabel;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UIButton *checkInButton;
@property (weak, nonatomic) IBOutlet UILabel *durationHeader;
@property (weak, nonatomic) IBOutlet UIView *userInfoBubble;
@property (weak, nonatomic) IBOutlet UILabel *infoBubbleNickname;
@property (weak, nonatomic) IBOutlet UILabel *infoBubbleStatus;
@property (weak, nonatomic) IBOutlet UILabel *oneHourLabel;
@property (weak, nonatomic) IBOutlet UILabel *threeHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *fiveHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *sevenHoursLabel;
@property (weak, nonatomic) UIImageView *infoBubbleArrow;
@property (nonatomic) int checkInDuration;
@property (nonatomic) BOOL sliderButtonPressed;
@property (nonatomic) int userArrayIndex;

-(IBAction)sliderChanged:(id)sender;
-(void)showUserInfoBubbleForUserIndex:(int)userIndex andButton:(UIButton *)userImageButton;
-(void)hideUserInfoBubble;
-(void)processOtherCheckedInUsers;

@end

@implementation CheckInDetailsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the title of the nav controller to the place name
    self.title = self.venue.name;
    
    // get the other users that are checked in
    [self processOtherCheckedInUsers];
    
    // custom slider images for the track
    UIImage *sliderMinimum = [[UIImage imageNamed:@"check-in-slider-grooves-light.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self.timeSlider setMinimumTrackImage:sliderMinimum forState:UIControlStateNormal];
    UIImage *sliderMaximum = [[UIImage imageNamed:@"check-in-slider-grooves-dark.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self.timeSlider setMaximumTrackImage:sliderMaximum forState:UIControlStateNormal];
    
    // custom slider image for the handle
    [self.timeSlider setThumbImage:[UIImage imageNamed:@"check-in-slider-handle.png"] forState:UIControlStateNormal];
    self.checkInDuration = self.timeSlider.value;
    
    // add these targets so we can change the font for the number that is selected
    [self.timeSlider addTarget:self action:@selector(sliderTouchDownAction:) forControlEvents:UIControlEventTouchDown];
    [self.timeSlider addTarget:self action:@selector(sliderTouchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];

    // add a subview to the userInfoBubble so we show a rounded bubble with white-ish background
    UIView *bubbleSub = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.userInfoBubble.frame.size.width, self.userInfoBubble.frame.size.height)];
    bubbleSub.backgroundColor = [UIColor colorWithRed:(224.0/255.0) green:(224.0/255.0) blue:(224.0/255.0) alpha:1.0];
    
    // mask the bubble for rounded edges
    // set the radius
    CGFloat radius = 5.0;
    // set the mask frame, and increase the height by the 
    // corner radius to hide bottom corners
    CGRect maskFrame = bubbleSub.bounds;
    // create the mask layer
    CALayer *maskLayer = [CALayer layer];
    maskLayer.cornerRadius = radius;
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    maskLayer.frame = maskFrame;
    // set the mask
    bubbleSub.layer.mask = maskLayer;
    
    // add bubbleSubview to the userInfoBubble
    [self.userInfoBubble insertSubview:bubbleSub atIndex:0];    
    
    
    // make an MKCoordinate region for the zoom level on the map
    MKCoordinateRegion region = MKCoordinateRegionMake(self.venue.coordinate, MKCoordinateSpanMake(0.006, 0.006));
    [self.mapView setRegion:region];
    
    // this will always be the point on iPhones up to iPhone4
    // if this needs to be used on iPad we'll need to do this programatically or use an if-else
    CGPoint moveRight = CGPointMake(71, 136);
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:moveRight toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    
    // set LeagueGothic font where applicable
    for (UILabel *labelNeedsGothic in [NSArray arrayWithObjects:self.checkInLabel, self.durationHeader, nil]) {
        [CPUIHelper changeFontForLabel:labelNeedsGothic toLeagueGothicOfSize:22];
    }

    [CPUIHelper changeFontForLabel:self.willLabel toLeagueGothicOfSize:25];
    
    // add a shadow on the top of the checkInDetails View, the VenueInfo box and the user info bubble
    [CPUIHelper addShadowToView:self.checkInDetails color:[UIColor blackColor] offset:CGSizeMake(0,-2) radius:3 opacity:0.24];
    [CPUIHelper addShadowToView:self.venueInfo color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    [CPUIHelper addShadowToView:self.userInfoBubble color:[UIColor blackColor] offset:CGSizeMake(2, 2) radius:3 opacity:0.38];
    
    // set the diagonal noise texture on the horizontal scrollview
    UIColor *texture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise.png"]];
    self.otherUsersScrollView.backgroundColor = texture;
    
    // set the light diagonal noise texture on the bottom UIView
    UIColor *lightTexture = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-light.png"]];
    self.checkInDetails.backgroundColor = lightTexture;     

    // set the delegates for the textField and the otherUsersScrollView
    self.statusTextField.delegate = self;
    self.otherUsersScrollView.delegate = self;
    
    // set the labels for the venue name and address
    self.placeName.text = self.venue.name;
    self.placeAddress.text = !self.venue.isNeighborhood ? self.venue.address : @"You won't appear on the map.";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController && self.navigationController.navigationBarHidden) {
        // make sure our navigationController isn't hidden from a search on the CheckInListViewController
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

// customer getter for infoBubbleArrow
// lazily instantiates it if it's not on the screen yet
-(UIImageView *)infoBubbleArrow
{
    if (!_infoBubbleArrow) {
        UIImageView *arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.userInfoBubble.frame.size.height, 25, 15)];
        arrowImageView.image = [UIImage imageNamed:@"check-in-status-arrow.png"];
        _infoBubbleArrow = arrowImageView;
        [self.userInfoBubble addSubview:_infoBubbleArrow];
    }
    
    return _infoBubbleArrow;
}

- (IBAction)checkInPressed:(id)sender {
    
    // send the server your lat/lon, number of hours to checkin for and the venue data from the place. 
    // url encode the appropriate values using the functions in CPapi
    
    NSString *statusText = @"";
    if (self.statusTextField.text) {
        statusText = self.statusTextField.text;
    }
    
    [SVProgressHUD showWithStatus:@"Checking In ..."];
    
    NSInteger checkInTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
    NSInteger checkInDuration = self.checkInDuration;    
    NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
    
    [CPApiClient checkInToVenue:self.venue
                      hoursHere:self.checkInDuration
                     statusText:statusText
                      isVirtual:self.checkInIsVirtual
                    isAutomatic:NO
                   completionBlock:^(NSDictionary *json, NSError *error){
        // hide the SVProgressHUD
        if (!error && ![[json objectForKey:@"error"] boolValue]) {
            [SVProgressHUD dismiss];
            
            // a successful checkin passes back venue_id
            // give that to this venue before we store it in NSUserDefaults
            // in case we came from foursquare venue list and didn't have it
            self.venue.venueID = [[json objectForKey:@"venue_id"] intValue];
            
            [CPCheckinHandler queueLocalNotificationForVenue:self.venue checkoutTime:checkOutTime];
            [CPCheckinHandler handleSuccessfulCheckinToVenue:self.venue checkoutTime:checkOutTime];
            
            // hide the checkin screen, we're checked in
            if ([self isModal]) {
                [self dismissModalViewControllerAnimated:YES];
            } else {
                // show an SVProgressHUD since we'll be reloading user data in the venue view
                [SVProgressHUD showWithStatus:@"Loading..."];
                [self.navigationController popViewControllerAnimated:YES];
                
                // our delegate is the venue info view controller
                // tell it to scroll to the user thumbnail after loading new data from this checkin
                [self.delegate setScrollToUserThumbnail:YES];
                [SVProgressHUD dismiss];
            }
        } else {
            // show an alertView letting the user know that an error occured, log the error if debugging
            [SVProgressHUD dismissWithError:@"An error occured while attempting to check in."
                                 afterDelay:kDefaultDismissDelay];
        }
    }];
}

- (void)processOtherCheckedInUsers
{
    // call the function in CPApi to get the other users at this venue
    [CPapi getUsersCheckedInAtFoursquareID:self.venue.foursquareID :^(NSDictionary *json, NSError *error) {
        int count = [[json valueForKeyPath:@"payload.count"] intValue];
        // check if we had an error or nobody else is here
        if (!error && count != 0) {
#if DEBUG
            NSLog(@"%d users at venue returned", count);
#endif
            
            // add a view above the scrollview so we can have a shadow along the top
            UIView *shadowMaker = [[UIView alloc] initWithFrame:CGRectMake(0, self.otherUsersScrollView.frame.origin.y - 5, 320, 5)];
            [CPUIHelper addShadowToView:shadowMaker color:[UIColor blackColor] offset:CGSizeMake(0, 2) radius:3 opacity:0.24];
            int indexOfUserScrollView = [self.scrollView.subviews indexOfObject:self.otherUsersScrollView];
            [self.scrollView insertSubview:shadowMaker atIndex:indexOfUserScrollView + 1];
            
            // bring up the gray scrollView bar which holds users
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.otherUsersScrollView.transform = CGAffineTransformMakeTranslation(0, -self.otherUsersScrollView.frame.size.height);
                shadowMaker.transform = CGAffineTransformMakeTranslation(0, -self.otherUsersScrollView.frame.size.height);
                self.userInfoBubble.transform = CGAffineTransformMakeTranslation(0, -self.otherUsersScrollView.frame.size.height);
                self.venueInfo.transform = CGAffineTransformMakeTranslation(0, -28);
            
            } completion:NULL];
            
            // setup integer variable left offset to keep track of where we are putting user images
            int leftOffset = 10;
            
            // setup the array of user nickname + statuses so we can put info into it
            self.userArray = [NSMutableArray arrayWithCapacity:count];
            
            // iterate through the users we've gotten back to add them to the scrollview
            NSArray *responseArray = [NSArray arrayWithArray:[json valueForKeyPath:@"payload.users"]];
            NSInteger index = 0;
            // reverse the response so we get latest checkins first
            for (NSDictionary *user in [responseArray reverseObjectEnumerator]) {
                
                User *checkedInUser = [[User alloc] init];
                checkedInUser.nickname = [user objectForKey:@"nickname"];
                checkedInUser.status = [user objectForKey:@"status_text"];
                checkedInUser.checkInIsVirtual = [[user objectForKey:@"is_virtual"] boolValue];
                
                // add this user to the user array
                // this is how we put the user's info in the info bubble later
                [self.userArray addObject:checkedInUser];
                
                UIButton *userImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
                userImageButton.frame = CGRectMake(leftOffset, 14, 50, 50);
                [userImageButton addTarget:self action:@selector(userImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                
                // alloc and init an imageview for the user image
                UIImageView *userImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                
                // alloc and init a spinner to put where the image will be, to show while the image is loading
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                // put the spinner in the middle of that imageview
                spinner.frame = CGRectMake((userImage.frame.size.width / 2) - (spinner.frame.size.width / 2),
                                           (userImage.frame.size.height / 2) - (spinner.frame.size.height / 2),
                                           spinner.frame.size.width,
                                           spinner.frame.size.height);
                
                // add a shadow to the imageview
                [CPUIHelper addShadowToView:userImage color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:3 opacity:0.40];
                
                // add the spinner and spin it
                [userImage addSubview:spinner];
                [spinner startAnimating];
                
                // add the imageview to the button
                [userImageButton addSubview:userImage];
                
                //If user is virtually checkedIn then add virtual badge to their profile image
                [CPUIHelper manageVirtualBadgeForProfileImageView:userImage 
                                                 checkInIsVirtual:checkedInUser.checkInIsVirtual];        

                
                // add the button to the scrollview
                [self.otherUsersScrollView addSubview:userImageButton];
                
                NSString *imageUrl = [user objectForKey:@"imageUrl"];
                
                // TODO: should we really be keeping the defaultAvatar locally?
                // why not just pass it back as the user's image so we cut down on app size
                // once it gets requested once it will be cached
                if ([imageUrl isKindOfClass:[NSNull class]]) {
                    // no user image so use the default avatar
                    [userImage setImage:[CPUIHelper defaultProfileImage]];
                    [spinner stopAnimating]; 
                } else {
                    // setup the request for the user's image, use AFNetworking to grab it
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[user objectForKey:@"imageUrl"]]];
                    
                    [userImage setImageWithURLRequest:request placeholderImage:[CPUIHelper defaultProfileImage] 
                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                            [spinner stopAnimating];
                        }
                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                            //If an error occurs, the defaultProfileImage is passed in as the placeholderImage so it will display that instead
                     
                            [spinner stopAnimating];
                    }];
                } 
                
                // increase the leftOffset so the next image is in the right spot
                leftOffset = leftOffset + 62;
                
                if (index == 0) {
                    // show the info bubble for the first user
                    [self userImageButtonPressed:userImageButton];
                }
                
                // increase the index by 1
                index += 1;
            }
            
            // add the "Who's here now?" text
            UILabel *whosHere = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset + 18, 0, 0, 78)];
            whosHere.backgroundColor = [UIColor clearColor];
            whosHere.textAlignment = UITextAlignmentCenter;
            whosHere.font = [UIFont systemFontOfSize:18.0];
            whosHere.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.7];
            whosHere.text = @"Who's here now?";
            [whosHere sizeToFit];
            whosHere.frame = CGRectMake(whosHere.frame.origin.x, whosHere.frame.origin.y, whosHere.frame.size.width, self.otherUsersScrollView.frame.size.height);
            [self.otherUsersScrollView addSubview:whosHere];
            
            // make the scroll view content size accomodate all the users that are checked in
            // it must be at least 320pts wide
            // the extra 177 in content size is for "Who's here now?"
            CGSize contentSize = CGSizeMake(10 + (count*12 - 12) + (count*50) + whosHere.frame.size.width + 30 + 20, 78);
            self.otherUsersScrollView.contentSize = contentSize;
            
        } else {
            // remove the scrollview (although we can't see it anyways)
            [self.otherUsersScrollView removeFromSuperview];
        }
    }];
}

// action when user presses slider handle
- (IBAction)sliderTouchDownAction:(id)sender {
    self.sliderButtonPressed = YES;
    // don't let the user accidentally checkin while sliding
    self.checkInButton.userInteractionEnabled = NO;
}

// action when user is done pressing slider handle
- (IBAction)sliderTouchUpInsideAction:(id)sender {    
    if (self.sliderButtonPressed) {
        self.sliderButtonPressed = NO;
        // let the user checkin now that they are done sliding
        self.checkInButton.userInteractionEnabled = YES;
    }
}

-(IBAction)sliderChanged:(id)sender
{
    // hide the hrs labels
    self.oneHourLabel.hidden = YES;
    self.threeHoursLabel.hidden = YES;
    self.fiveHoursLabel.hidden = YES;
    self.sevenHoursLabel.hidden = YES;
    
    // get the value of the slider and set it to one of the accepted values, revealing the associated hour label
    float value = self.timeSlider.value;
    if (value < 2) {
        value = 1;
        self.oneHourLabel.hidden = NO;
    } else if (value < 4) {
        value = 3;
        self.threeHoursLabel.hidden = NO;
    } else if (value < 6) {
        value = 5;
        self.fiveHoursLabel.hidden = NO;
    } else {
        value = 7;
        self.sevenHoursLabel.hidden = NO;
    }
    
    // remove the font change to the previous selected value
    UILabel *previousSelectedValueLabel = (UILabel *)[self.view viewWithTag:(1000 + self.checkInDuration)];
    previousSelectedValueLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    previousSelectedValueLabel.font = [UIFont boldSystemFontOfSize:20.0];
    
    // change the font on the new selected value
    UILabel *selectedValueLabel = (UILabel *)[self.view viewWithTag:(1000 + value)];
    selectedValueLabel.textColor = RGBA(66, 130, 140, 1);
    selectedValueLabel.font = [UIFont boldSystemFontOfSize:28.0];
    
    // set the slider to the accepted value
    [self.timeSlider setValue:value animated:YES];
    // set the checkInDuration to the accepted value
    self.checkInDuration = value;
}

-(void)userImageButtonPressed:(UIButton *)sender
{        
    // get the index of the user in the userArray (based on button index)
    int userIndex = [self.otherUsersScrollView.subviews indexOfObject:sender];
      
    // check if the info bubble isn't already on screen
    if (self.userInfoBubble.alpha == 0) {
        // the bubble is hidden so it's time to show it
        // with the data from userArray
        [self showUserInfoBubbleForUserIndex:userIndex andButton:sender];
    }
    else {
        // the bubble is on screen 
        // we're either showing a different bubble or hiding this one
        // check if the same button was clicked on again
        // hide it if that's the case
        if (userIndex == self.userArrayIndex) {
            [self hideUserInfoBubble];
        } else {
            // we need to show a different info bubble
            self.userArrayIndex = userIndex;
            [self showUserInfoBubbleForUserIndex:userIndex andButton:sender];
        }        
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // the user dragged the scrollview so hide the info bubble
    [self hideUserInfoBubble];
}

-(void)showUserInfoBubbleForUserIndex:(int)userIndex andButton:(UIButton *)userImageButton
{
    
    // set the nickname and status on the info bubble
    // decode the HTML entities
    self.infoBubbleNickname.text = [[self.userArray objectAtIndex:userIndex] nickname];
    NSString *status = [[self.userArray objectAtIndex:userIndex] status];
    if ([status length] > 0) {
        self.infoBubbleStatus.text = [NSString stringWithFormat:@"\"%@\"", status];
    } else {
        self.infoBubbleStatus.text = @"No status set...";
    }
    
    // vertically the status text so it's at the top if it's one line
    CGSize sizeToFit = [self.infoBubbleStatus.text sizeWithFont:self.infoBubbleStatus.font
                                              constrainedToSize:CGSizeMake(169, 42)
                                                  lineBreakMode:self.infoBubbleStatus.lineBreakMode];
    CGRect textFrame = self.infoBubbleStatus.frame;
    textFrame.size.height = sizeToFit.height;
    self.infoBubbleStatus.frame = textFrame;
    
        
    CGPoint newOffset = self.otherUsersScrollView.contentOffset;
    // figure out if the user image is on the edge and scroll it back to the left edge if that is the case
    if (self.otherUsersScrollView.contentOffset.x > userImageButton.frame.origin.x - 10) {
        newOffset = CGPointMake(userImageButton.frame.origin.x - 10, 0);
    }   
    // move the user image back into the scrollview if it's on the right edge
    else if (self.otherUsersScrollView.contentOffset.x + self.otherUsersScrollView.frame.size.width < userImageButton.frame.origin.x + userImageButton.frame.size.width + 10) {
        newOffset = CGPointMake(userImageButton.frame.origin.x + userImageButton.frame.size.width + 10 - self.otherUsersScrollView.frame.size.width, 0);
    }
    
    // animate the changing of the scrollview offset (should it need to be changed)
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        [self.otherUsersScrollView setContentOffset:newOffset];
    } completion:^(BOOL finished){
        if (finished) {
            // this is all called once the scrollview has moved
            
            
            // move the little arrow to be centered on this userImage
            CGRect moveInfoBubble = self.userInfoBubble.frame;
            CGRect moveArrow = self.infoBubbleArrow.frame;
            moveArrow.origin.x = userImageButton.frame.origin.x - self.otherUsersScrollView.contentOffset.x + (userImageButton.frame.size.width / 2) - (moveArrow.size.width / 2) - 10;
            
            // move the info bubble to the left or right edge depending on which user image was tapped
            if (userImageButton.frame.origin.x + userImageButton.frame.size.width - self.otherUsersScrollView.contentOffset.x > 10 + self.userInfoBubble.frame.size.width) {        
                moveInfoBubble.origin.x = self.view.frame.size.width - moveInfoBubble.size.width - 10;
                moveArrow.origin.x = moveArrow.origin.x - moveInfoBubble.origin.x + 10;
            } else {
                moveInfoBubble.origin.x = 10;
            }
            
            // fade in the userInfoBubble if it's hidden
            if (self.userInfoBubble.alpha == 0) {
                // place it in the right spot before fading it in
                self.userInfoBubble.frame = moveInfoBubble;
                self.infoBubbleArrow.frame = moveArrow;
                [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationTransitionNone animations:^{
                    self.userInfoBubble.alpha = 1.0;
                } completion:NULL];
            } else {
                // animate moving of info bubble and arrow
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
                    self.userInfoBubble.frame = moveInfoBubble;
                    self.infoBubbleArrow.frame = moveArrow;
                } completion:NULL]; 
            }
        }        
    }];   
}

-(void)hideUserInfoBubble
{
    // fade out the userInfoBubble
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationTransitionNone animations:^{
        self.userInfoBubble.alpha = 0.0;
    } completion:NULL];
}

- (void)dismissViewControllerAnimated {
    [self dismissModalViewControllerAnimated:YES];
}

@end
