//
//  VenueInfoViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueInfoViewController.h"
#import "CPAnnotation.h"
#import "MapTabController.h"
#import "CheckInDetailsViewController.h"
#import "User.h"
#import "UserProfileCheckedInViewController.h"
#import "UIImageView+AFNetworking.h"
#import "CPapi.h"

@interface VenueInfoViewController () <UIAlertViewDelegate>
- (IBAction)tappedAddress:(id)sender;
- (IBAction)tappedPhone:(id)sender;

- (void)populateUserSection:(NSNotification *)notification;

- (void)addUserAnnotation:(CPAnnotation *)userAnnotation
    toArrayForJobCategory:(NSString *)jobCategory;

- (UIView *)categoryViewForCurrentUserCategory:(NSString *)category
                                   withYOrigin:(CGFloat)yOrigin;

- (UIView *)viewForPreviousUsersWithYOrigin:(CGFloat)yOrigin;

- (void)stylingForUserBox:(UIView *)userBox
                withTitle:(NSString *)titleString
        forCheckedInUsers:(BOOL)isCurrentUserBox;

- (void)checkInPressed:(id)sender;


@end

@implementation VenueInfoViewController

@synthesize scrollView = _scrollView;
@synthesize venue = _venue;
@synthesize venuePhoto = _venuePhoto;
@synthesize venueName = _venueName;
@synthesize userSection = _userSection;
@synthesize delegate = _delegate;
@synthesize categoryCount = _categoryCount;
@synthesize currentUsers = _currentUsers;
@synthesize previousUsers = _previousUsers;
@synthesize usersShown = _usersShown;
@synthesize userObjectsForUsersOnScreen = _userObjectsForUsersOnScreen;

- (NSMutableDictionary *)userObjectsForUsersOnScreen
{
    if (!_userObjectsForUsersOnScreen) {
        _userObjectsForUsersOnScreen = [NSMutableDictionary dictionary];
    }
    return _userObjectsForUsersOnScreen;
}

- (id)initWithNibName:(NSString *)nibNameOrNil  bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add a notification catcher for refreshViewOnCheckin to refresh the view
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(populateUserSection:) 
                                                 name:@"refreshViewOnCheckin" 
                                               object:nil];
    
    // set the title of the navigation controller
    if (self.venue.othersHere != 0) {
        self.title = [NSString stringWithFormat:@"%d %@ here", self.venue.othersHere, self.venue.othersHere == 1 ? @"other" : @"others"];
    } else {
        self.title = self.venue.name;
    }   
    
    // the map tab controller is going to be our delegate
    self.delegate = [CPAppDelegate settingsMenuController].mapTabController;
    
    // put the photo in the top box
    UIImage *comingSoon = [UIImage imageNamed:@"picture-coming-soon-rectangle.jpg"];
    if (![self.venue.photoURL isKindOfClass:[NSNull class]]) {
        [self.venuePhoto setImageWithURL:[NSURL URLWithString:self.venue.photoURL] placeholderImage:comingSoon];
    } else {
        [self.venuePhoto setImage:comingSoon];
    }
    
    // leage gothic for venue name
    [CPUIHelper changeFontForLabel:self.venueName toLeagueGothicOfSize:30.0];
    
    // shadow that shows above user info
    [CPUIHelper addShadowToView:[self.view viewWithTag:3548]  color:[UIColor blackColor] offset:CGSizeMake(0, 1) radius:5 opacity:0.7];
    
    // set the venue info in the box
    self.venueName.text = self.venue.name;
    
    // get the info bar that's below the line
    UIView *infoBar = [self.view viewWithTag:8014];
    
    // setup the address button
    UIButton *address = [UIButton buttonWithType:UIButtonTypeCustom];
    // add the address button to the infobar
    [infoBar addSubview:address];
    
    // setup the phone button
    UIButton *phone;
    
    // check if we're putting a phone number or just the address
    if ([self.venue.formattedPhone length] > 0) {
        // frame for address button
        address.frame = CGRectMake(0, 2, infoBar.frame.size.width / 2, infoBar.frame.size.height - 2);
        
        // we'll also need a phone button
        phone = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect newFrame = address.frame;
        newFrame.origin.x = (infoBar.frame.size.width / 2);
        phone.frame = newFrame;
        
        [self setupVenueButton:phone withIconNamed:@"place-phone" andlabelText:self.venue.formattedPhone];
        
        // add the phone button to the infobar
        [infoBar addSubview:phone];
        
        [phone addTarget:self action:@selector(tappedPhone:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        // setup the frame for the address button
        address.frame = CGRectMake(0, 2, infoBar.frame.size.width, infoBar.frame.size.height - 2);
    }
    
    [self setupVenueButton:address withIconNamed:@"place-location" andlabelText:self.venue.address];
    // set the target for the address button
    [address addTarget:self action:@selector(tappedAddress:) forControlEvents:UIControlEventTouchUpInside];
    
    // put the texture in the bottom view
    self.userSection.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-first-aid-kit"]];
    
    [self populateUserSection:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // hide the normal check in button
}

- (void)viewDidUnload
{
    [self setVenueName:nil];
    [self setVenuePhoto:nil];
    [self setUserSection:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)populateUserSection:(NSNotification *)notification
{
    // clear out the current user section
    for (UIView *subview in [self.userSection subviews]) {
        [subview removeFromSuperview];
    }
    
    // this is where we add the users and the check in button to the bottom of the scroll view
    
    // grab the user data by calling a delegate method on the map and grabbing the data from there
    NSArray *checkedInUsers = [self.delegate getCheckinsByGroupTag:self.venue.foursquareID];
        
    // init the data structures
    self.currentUsers = [NSMutableDictionary dictionary];
    self.categoryCount = [NSMutableDictionary dictionary];
    self.previousUsers = [[NSMutableArray alloc] init];
    self.usersShown =  [NSMutableSet set];
    
    for (CPAnnotation *userAnnotation in checkedInUsers) {
        if (userAnnotation.checkedIn) {
            [self addUserAnnotation:userAnnotation toArrayForJobCategory:userAnnotation.majorJobCategory];
            // if the major and minor job categories differ also add this person to the minor category
            if (![userAnnotation.majorJobCategory isEqualToString:userAnnotation.minorJobCategory] && ![userAnnotation.minorJobCategory isEqualToString:@"other"]) {
                [self addUserAnnotation:userAnnotation toArrayForJobCategory:userAnnotation.minorJobCategory];
            }
        } else {
            // this is a non-checked in user
            // add them to the previous users dictionary
            [self.previousUsers addObject:userAnnotation];
        }
    }
    
    // setup a frame to keep spacing between elements
    CGRect newFrame;
    newFrame.origin.y = 16;
    
    // look for currently checked in users to put on screen
    
    // make sure the other category will come last, no matter the number of users
    
    NSMutableArray *categoriesByCount = [[self.categoryCount keysSortedByValueUsingSelector:@selector(compare:)] mutableCopy];
    
    if ([self.categoryCount objectForKey:@"other"]) {
        [categoriesByCount removeObject:@"other"];
        [categoriesByCount insertObject:@"other" atIndex:0];
    }   
    
    for (NSString *category in [categoriesByCount reverseObjectEnumerator]) {
        // if the category exists there is at least one user annotation
        // setup the view that will hold them
        
        // call a method to get back a view for the category
        UIView *categoryView = [self categoryViewForCurrentUserCategory:category withYOrigin:newFrame.origin.y + 1];
        newFrame.origin.y += categoryView.frame.size.height;
        // add the category view to the userSection view
        [self.userSection addSubview:categoryView];
    }
    
    // place previously checked in users on screen
    UIView *previousView = [self viewForPreviousUsersWithYOrigin:newFrame.origin.y + 15];
    
    // show the previousView if it exists
    if (previousView) {
        [self.userSection addSubview:previousView];
        newFrame.origin.y = previousView.frame.origin.y + previousView.frame.size.height;
    }    
    
    // label for check in text
    UILabel *checkInLabel = [[UILabel alloc] init];
        
    // set the text on the label
    checkInLabel.text = [NSString stringWithFormat:@"Check in to %@", self.venue.name];
    
    // change the font to league gothic
    [CPUIHelper changeFontForLabel:checkInLabel toLeagueGothicOfSize:18];
    
    // get the size we'll need for the label to center it
    CGSize toFit = [checkInLabel.text sizeWithFont:checkInLabel.font];
    
    // change the newFrame properties to what we need
    
    newFrame.origin.x = (self.userSection.frame.size.width / 2) - (toFit.width / 2);
    
    // check if there are no users currently or previously checked in (in last week) and set the y-origin based on that
    newFrame.origin.y += newFrame.origin.y == 16 ? 4 : 20;
    newFrame.size = toFit;
        
    // give that frame to the label
    checkInLabel.frame = newFrame;
    
    // move the newframe origin down for the check in button
    // this is commented out because the button image is larger than the actual
    // button and it fits well without moving it down
    // newFrame.origin.y += newFrame.size.height;
    
    // change the color and background color of the check in label text
    checkInLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    checkInLabel.backgroundColor = [UIColor clearColor];
    
    // add the check in label to the view
    [self.userSection addSubview:checkInLabel];  
    
    // check in button
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *checkInImage = [UIImage imageNamed:@"check-in-big"];
    
    // image for the check in button
    [checkInButton setImage:checkInImage forState:UIControlStateNormal];
    
    // change the newFrame properties to what we need
    newFrame.size = checkInImage.size;
    newFrame.origin.x = (self.userSection.frame.size.width / 2) - (newFrame.size.width / 2);
    newFrame.origin.y += 6;
    
    checkInButton.frame = newFrame;
    
    // target for check in button
    [checkInButton addTarget:self action:@selector(checkInPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // add the check in button to the view
    [self.userSection addSubview:checkInButton];
    
    // resize the user section frame
    CGRect newSectionFrame = self.userSection.frame;
    newSectionFrame.size.height = newFrame.origin.y + newFrame.size.height;
    if (newSectionFrame.size.height > self.userSection.frame.size.height) {
        self.userSection.frame = newSectionFrame;
    }    
    
    // set the scrollview content size
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.venuePhoto.frame.size.height + self.userSection.frame.size.height);    
}
                            
- (void)addUserAnnotation:(CPAnnotation *)userAnnotation
    toArrayForJobCategory:(NSString *)jobCategory
{
    // check if we already have an array for this category
    // and create one if we don't
    if (![self.currentUsers objectForKey:jobCategory]) {
        [self.currentUsers setObject:[NSMutableArray array] forKey:jobCategory];
        [self.categoryCount setObject:[NSNumber numberWithInt:0] forKey:jobCategory];
    }
    // add this user to that array
    [[self.currentUsers objectForKey:jobCategory] addObject:userAnnotation];
    int currentCount = [[self.categoryCount objectForKey:jobCategory] intValue];
    [self.categoryCount setObject:[NSNumber numberWithInt:1 + currentCount] forKey:jobCategory];
}

- (void)addUserToDictionaryOfUserObjectsFromCPAnnotation:(CPAnnotation *)userAnnotation
{
    // alloc init a user object
    User *user = [[User alloc] init];
    user.userID = userAnnotation.userId;
    user.nickname = userAnnotation.nickname;
    user.status = userAnnotation.status;
    user.location = CLLocationCoordinate2DMake(userAnnotation.lat, userAnnotation.lon);
    user.checkedIn = userAnnotation.checkedIn;
    user.jobTitle = userAnnotation.headline;
    [self.userObjectsForUsersOnScreen setObject:user forKey:[NSString stringWithFormat:@"%d", user.userID]];
}

- (UIButton *)thumbnailButtonForAnnotation:(CPAnnotation *)userAnnotation
                             withSquareDim:(CGFloat)thumbnailDim
                                andXOffset:(CGFloat)xOffset
                                andYOffset:(CGFloat)yOffset
{
    // setup a button for the user thumbnail
    UIButton *thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
    thumbButton.frame = CGRectMake(xOffset, yOffset, thumbnailDim, thumbnailDim);

    // set the tag to the user ID
    thumbButton.tag = userAnnotation.userId;

    // add a target for this user thumbnail button
    [thumbButton addTarget:self action:@selector(userImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *userThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbnailDim, thumbnailDim)];
    [userThumbnail setImageWithURL:[NSURL URLWithString:userAnnotation.imageUrl] placeholderImage:[CPUIHelper defaultProfileImage]];

    // add a shadow to the imageview
    [CPUIHelper addShadowToView:userThumbnail color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:3 opacity:0.40];

    [thumbButton addSubview:userThumbnail];
    
    return thumbButton;
}

- (UIView *)categoryViewForCurrentUserCategory:(NSString *)category
                        withYOrigin:(CGFloat)yOrigin;
{
    UIView *categoryView = [[UIView alloc] initWithFrame:CGRectMake(10, yOrigin, self.view.frame.size.width - 20, 113)]; 
    
    [self stylingForUserBox:categoryView withTitle:category forCheckedInUsers:YES];
    
    CGFloat thumbnailDim = 71;
    
    UIScrollView *usersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 29, categoryView.frame.size.width, thumbnailDim)];
    
    // add the scroll view to the category box
    [categoryView addSubview:usersScrollView];
    
    CGFloat xOffset = 10;
    for (CPAnnotation *userAnnotation in [self.currentUsers objectForKey:category]) {
        
        UIButton *thumbButton = [self thumbnailButtonForAnnotation:userAnnotation withSquareDim:thumbnailDim andXOffset:xOffset andYOffset:0];
        
        // add the thumbnail to the category view
        [usersScrollView addSubview:thumbButton];
        
        // add to the xOffset for the next thumbnail
        xOffset += 10 + thumbButton.frame.size.width;
        
        // add this user to the usersShown set so we know we have them
        [self.usersShown addObject:[NSNumber numberWithInt:userAnnotation.userId]];
        
        if (![self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", userAnnotation.userId]]) {
            [self addUserToDictionaryOfUserObjectsFromCPAnnotation:userAnnotation];
        }        
    }
    
    // set the content size on the scrollview
    CGFloat newWidth = [[self.currentUsers objectForKey:category] count] * (thumbnailDim + 10) + 45;
    usersScrollView.contentSize = CGSizeMake(newWidth, usersScrollView.contentSize.height);
    usersScrollView.showsHorizontalScrollIndicator = NO;
    
    // gradient on the right side of the scrollview
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(usersScrollView.frame.size.width - 45, usersScrollView.frame.origin.y, 45, usersScrollView.frame.size.height);
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:0.0] CGColor],
                       (id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0] CGColor],
                       (id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0] CGColor],
                       nil];
    [gradient setStartPoint:CGPointMake(0.0, 0.5)];
    [gradient setEndPoint:CGPointMake(1.0, 0.5)];
    gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.65], [NSNumber numberWithFloat:1.0], nil];
    [categoryView.layer addSublayer:gradient];
        
    // return the view
    return categoryView;
}

- (UIView *)viewForPreviousUsersWithYOrigin:(CGFloat)yOrigin
{
    UIView *previousUsersView = [[UIView alloc] initWithFrame:CGRectMake(10, yOrigin, self.view.frame.size.width - 20, 113)];
    
    NSString *title = [self.previousUsers count] > 1 ? @"Have worked here..." : @"Has worked here...";
    [self stylingForUserBox:previousUsersView withTitle:title forCheckedInUsers:NO];
    
    CGRect newFrame = previousUsersView.frame;
    
    CGFloat yOffset = 29;
    BOOL atLeastOne = NO;
    
    UIView *lastLine;
    
    for (CPAnnotation *userAnnotation in self.previousUsers) {
        // make sure we aren't already showing this user as checked in or as a previous user
        if (![self.usersShown containsObject:[NSNumber numberWithInt:userAnnotation.userId]]) {
            // setup the user thumbnail
            UIButton *userThumbnailButton = [self thumbnailButtonForAnnotation:userAnnotation withSquareDim:71 andXOffset:10 andYOffset:yOffset];
            
            // add the thumbnail to the view
            [previousUsersView addSubview:userThumbnailButton];
            
            CGFloat maxLabelWidth = previousUsersView.frame.size.width - (userThumbnailButton.frame.size.width + userThumbnailButton.frame.origin.x) - 20;
            CGFloat leftOffset = userThumbnailButton.frame.origin.x + userThumbnailButton.frame.size.width + 10;
            
            // label for the user name
            UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, yOffset + 10, maxLabelWidth, 20)];
            userName.text = userAnnotation.nickname;
            [CPUIHelper changeFontForLabel:userName toLeagueGothicOfSize:18];
            userName.backgroundColor = [UIColor clearColor];
            userName.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            
            // add the username to the previousUsersView
            [previousUsersView addSubview:userName];
            
            CGFloat labelOffset = yOffset;
            
            UIColor *lightGray = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
            
            if ([userAnnotation.headline length] > 0) {
                // label for user headline
                labelOffset += 27;
                UILabel *userHeadline = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, labelOffset, maxLabelWidth, 20)];
                userHeadline.text = userAnnotation.headline;
                
                userHeadline.backgroundColor = [UIColor clearColor];
                userHeadline.textColor = lightGray;
                userHeadline.font = [UIFont systemFontOfSize:12];
                
                // add the label to the previousUsersView
                [previousUsersView addSubview:userHeadline];
            } else {
                labelOffset += 11;
            }
            
            UILabel *userCheckins = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, labelOffset + 16, maxLabelWidth, 20)];
            userCheckins.text = [NSString stringWithFormat:@"%d check ins", userAnnotation.checkinCount];
            
            userCheckins.font = [UIFont boldSystemFontOfSize:12];
            
            userCheckins.backgroundColor = [UIColor clearColor];
            userCheckins.textColor = lightGray;
            userCheckins.font = [UIFont systemFontOfSize:12];
            
            // add the label to the previousUsersView
            [previousUsersView addSubview:userCheckins];
            
            // set the new y-offset for the next user
            yOffset += userThumbnailButton.frame.size.height + 11;
            
            newFrame.size.height = yOffset;
            
            // add this user to the usersShown mutable set so they won't be shown again
            [self.usersShown addObject:[NSNumber numberWithInt:userAnnotation.userId]];
            
            atLeastOne = YES;
            
            // put a line to seperate the users
            UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(userThumbnailButton.frame.origin.x, yOffset - 6, previousUsersView.frame.size.width - 20, 1)];
            seperator.backgroundColor = [UIColor colorWithRed:(198.0/255.0) green:(198.0/255.0) blue:(198.0/255.0) alpha:0.75];
            
            [previousUsersView addSubview:seperator];   
            
            // this is the new last line
            lastLine = seperator;
            
            [self addUserToDictionaryOfUserObjectsFromCPAnnotation:userAnnotation];            
        }        
    }
    // remove the last line since we won't need it
    [lastLine removeFromSuperview];
    
    // grow the previousUsersView frame to accomodate all users
    previousUsersView.frame = newFrame;
    
    // if there's at least on user to show then return a view otherwise be nil
    if (atLeastOne) {
        return previousUsersView; 
    } else {
        return nil;
    }
       
}

- (void)stylingForUserBox:(UIView *)userBox
                withTitle:(NSString *)titleString
        forCheckedInUsers:(BOOL)isCurrentUserBox
{
    // border on category view
    userBox.layer.borderColor = [[UIColor colorWithRed:(198.0/255.0) green:(198.0/255.0) blue:(198.0/255.0) alpha:1.0] CGColor];
    userBox.layer.borderWidth = 1.0;
    
    // background color for category view
    userBox.backgroundColor = [UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0];
    
    // setup the label for the top of the category
    UILabel *categoryLabel = [[UILabel alloc] init];
    if (isCurrentUserBox) {
        categoryLabel.text = [titleString capitalizedString];
    } else {
        categoryLabel.text = titleString;
    }
    
    
    // font styling
    [CPUIHelper changeFontForLabel:categoryLabel toLeagueGothicOfSize:18];
    categoryLabel.backgroundColor = [UIColor clearColor];
    categoryLabel.textColor = [UIColor colorWithRed:(16.0/255.0) green:(128.0/255.0) blue:(134.0/255.0) alpha:1.0];
    
    // set the frame on the label
    CGSize labelSize = [categoryLabel.text sizeWithFont:categoryLabel.font];
    categoryLabel.frame = CGRectMake(10, 5, labelSize.width, labelSize.height);
    
    // add the category label to the view
    [userBox addSubview:categoryLabel];   
    
    // if this is a box for currently checked in users then we have a number of checked in users to show
    if (isCurrentUserBox) {
        
        // setup the label using the frame of the category label
        UILabel *userCount = [[UILabel alloc] initWithFrame:categoryLabel.frame];
        CGRect countFrame = userCount.frame;
        
        // put it to the right of the category label
        countFrame.origin.x = categoryLabel.frame.origin.x + categoryLabel.frame.size.width + 2;
        
        // set the text and text styling
        userCount.text = [NSString stringWithFormat:@"- %@", [self.categoryCount objectForKey:titleString]];
        userCount.backgroundColor = [UIColor clearColor];
        userCount.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        userCount.font = categoryLabel.font;
        
        // size to fit the label
        CGSize countSize = [userCount.text sizeWithFont:userCount.font];
        countFrame.size = countSize;
        
        // set the frame on the count
        userCount.frame =  countFrame;
        
        // add the count to the userBox view
        [userBox addSubview:userCount];
    }
}


- (void)checkInPressed:(id)sender
{
    CheckInDetailsViewController *checkinVC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckinDetailsViewController"];
    checkinVC.place = self.venue;
    
    [self.navigationController pushViewController:checkinVC animated:YES];
}

- (void)cancelCheckinModal
{
    [self.modalViewController dismissModalViewControllerAnimated:YES];
}

- (void)setupVenueButton:(UIButton *)venueButton
    withIconNamed:(NSString *)imageName
        andlabelText:(NSString *)labelText
{
    // alloc-init the icon
    UIImageView *buttonIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    
    // center the icon
    CGRect centerIcon = buttonIcon.frame;
    centerIcon.origin.y = (venueButton.frame.size.height / 2) - (centerIcon.size.height / 2);
    buttonIcon.frame = centerIcon;
    
    // add the icon to the button
    [venueButton addSubview:buttonIcon];
    
    // alloc-init the address label
    UILabel *buttonLabel = [[UILabel alloc] init];
    
    // league gothic for the label
    [CPUIHelper changeFontForLabel:buttonLabel toLeagueGothicOfSize:15];
    
    // sizing and styling for label
    CGSize labelSize = [labelText sizeWithFont:buttonLabel.font];
    
    buttonLabel.frame = CGRectMake(12, (venueButton.frame.size.height / 2) - (labelSize.height / 2) , labelSize.width, labelSize.height);
    
    buttonLabel.backgroundColor = [UIColor clearColor];
    buttonLabel.textColor = [UIColor whiteColor];
    
    // set the label text to the address
    buttonLabel.text = labelText;
    
    // add the label to the button
    [venueButton addSubview:buttonLabel];
    
    // move the label to the right spot
    CGRect newFrame = venueButton.frame;
    newFrame.size.width = buttonIcon.frame.size.width + buttonLabel.frame.origin.x + buttonLabel.frame.size.width;
    newFrame.origin.x = newFrame.origin.x + (venueButton.frame.size.width / 2) - (newFrame.size.width / 2);
    venueButton.frame = newFrame;
}

- (IBAction)tappedAddress:(id)sender 
{
    NSString *message = [NSString stringWithFormat:@"Do you want directions to %@?", self.venue.name];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Directions" 
                                                        message:message
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Launch Map", nil];
    alertView.tag = 1045;
    [alertView show];
}

- (IBAction)tappedPhone:(id)sender
{
    // only do something here if we can actually make a call
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        NSString *title = [NSString stringWithFormat:@"Call %@?", self.venue.name];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title 
                                                            message:self.venue.formattedPhone
                                                           delegate:self 
                                                  cancelButtonTitle:@"Cancel" 
                                                  otherButtonTitles:@"Call", nil];
        alertView.tag = 1046;
        [alertView show];
    }   
}

- (IBAction)userImageButtonPressed:(id)sender
{
    UserProfileCheckedInViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    
    UIButton *thumbnailButton = (UIButton *)sender;
    
    // set the user object on that view controller
    // using the tag on the button to pull this user out of the NSMutableDictionary of user objects
    userVC.user = [self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", thumbnailButton.tag]]; 
    
    // push the user profile onto this navigation controller stack
    [self.navigationController pushViewController:userVC animated:YES];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // variable to hold string that will open local app on phone
        NSString *urlString;
        
        if (alertView.tag == 1045) {
            // get the user's current location
            CLLocationCoordinate2D currentLocation = [CPAppDelegate settings].lastKnownLocation.coordinate;
            NSString *fullAddress = [NSString stringWithFormat:@"%@, %@, %@", self.venue.address, self.venue.city, self.venue.state];
            // setup the url to open google maps
            urlString = [NSString stringWithFormat: @"http://maps.google.com/maps?saddr=%f,%f&daddr=%@",
                                   currentLocation.latitude, currentLocation.longitude,
                                   [CPapi urlEncode:fullAddress]];
            
        } else if (alertView.tag == 1046) {
            // setup the url to call venue
            urlString = [NSString stringWithFormat: @"tel:%@", self.venue.phone];
        }
        
        // open maps or phone from the url string
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: urlString]];
    }         
}

@end
