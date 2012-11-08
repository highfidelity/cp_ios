//
//  VenueInfoViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueInfoViewController.h"
#import "MapTabController.h"
#import "UserProfileViewController.h"
#import "CPUserSessionHandler.h"
#import "CPUserAction.h"
#import "VenueUserCell.h"
#import "VenueCategoryCell.h"

static VenueInfoViewController *_onScreenVenueVC;

@interface VenueInfoViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *bottomPhotoOverlayView;
@property (weak, nonatomic) UIButton *phoneButton;
@property (weak, nonatomic) UIButton *addressButton;
@property (strong, nonatomic) NSMutableDictionary *userObjectsForUsersOnScreen;
@property (nonatomic) BOOL checkInIsVirtual;
@property (nonatomic) BOOL hasPhone;
@property (nonatomic) BOOL hasAddress;
@property (nonatomic, readonly) CGFloat cellWidth;

@end

@implementation VenueInfoViewController

+ (VenueInfoViewController *)onScreenVenueVC
{
    return _onScreenVenueVC;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add a notification catcher for refreshVenueAfterCheckin to refresh the view
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshVenueData:) 
                                                 name:@"refreshVenueAfterCheckin" 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(populateUserSection) 
                                                 name:@"LoginStateChanged" 
                                               object:nil];
    
    // set the title of the navigation controller
    self.title = self.venue.name;
    
    // don't try to scroll to the user's thumbnail, not a checkin
    self.scrollToUserThumbnail = NO;
    
    // put the photo in the top box
    UIImage *comingSoon = [UIImage imageNamed:@"picture-coming-soon-rectangle.jpg"];
    if (![self.venue.photoURL isKindOfClass:[NSNull class]]) {
        [self.venuePhoto setImageWithURL:[NSURL URLWithString:self.venue.photoURL] placeholderImage:comingSoon];
    } else {
        [self.venuePhoto setImage:comingSoon];
    }
    
    // shadow that shows above user info
    [CPUIHelper addShadowToView:[self.view viewWithTag:3548]  color:[UIColor blackColor] offset:CGSizeMake(0, 1) radius:5 opacity:0.7];
    
    {
        self.phoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomPhotoOverlayView addSubview:self.phoneButton];
        
        if ([self.venue.formattedPhone length] > 0) {
            self.hasPhone = YES;
            [self setupVenueButton:self.phoneButton withIconNamed:@"place-phone" andlabelText:self.venue.formattedPhone];
            [self.phoneButton addTarget:self action:@selector(tappedPhone:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            self.hasPhone = NO;
            [self setupVenueButton:self.phoneButton withIconNamed:@"place-phone" andlabelText:@"N/A"];
        }
    }
    
    {
        self.addressButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomPhotoOverlayView addSubview:self.addressButton];
        
        if ([self.venue.address length] > 0) {
            self.hasAddress = YES;
            [self setupVenueButton:self.addressButton withIconNamed:@"place-location" andlabelText:self.venue.address];
            [self.addressButton addTarget:self action:@selector(tappedAddress:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            self.hasAddress = NO;
            [self setupVenueButton:self.addressButton withIconNamed:@"place-location" andlabelText:@"N/A"];
        }
    }
    
    [self repositionAddressAndPhone];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-first-aid-kit"]];
        
    // table view header
    [self.scrollView removeFromSuperview];
    self.tableView.tableHeaderView = self.scrollView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self populateUserSection]; 
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _onScreenVenueVC = self;

    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];

    [self unhighlightCells:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _onScreenVenueVC = nil;
}

- (void)dealloc
{
     [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableDictionary *)userObjectsForUsersOnScreen
{
    if (!_userObjectsForUsersOnScreen) {
        _userObjectsForUsersOnScreen = [NSMutableDictionary dictionary];
    }
    return _userObjectsForUsersOnScreen;
}

- (void)addUserToDictionaryOfUserObjectsFromUser:(User *)user
{
    [self.userObjectsForUsersOnScreen setObject:user forKey:[NSString stringWithFormat:@"%d", user.userID]];
}

- (BOOL)isCheckedInHere
{
    return [CPUserDefaultsHandler isUserCurrentlyCheckedIn] && [CPUserDefaultsHandler currentVenue].venueID == self.venue.venueID;
}

- (void)refreshVenueData:(NSNotification *)notification
{
    // we'll get a notification if this venue has been updated (by an API call)
    // so set our venue to that as information will be updated
    self.venue = notification.object;

    // repopulate user data with new info
    [self populateUserSection];
}

- (NSArray *)orderedCategories {
    // make sure the other category will come last, no matter the number of users
    if (!_orderedCategories) {
        NSMutableArray *categoriesByCount = [[self.categoryCount keysSortedByValueUsingSelector:@selector(compare:)] mutableCopy];
        
        if ([self.categoryCount objectForKey:@"other"]) {
            [categoriesByCount removeObject:@"other"];
            [categoriesByCount insertObject:@"other" atIndex:0];
        }
        _orderedCategories = [[categoriesByCount reverseObjectEnumerator] allObjects];
    }
    return _orderedCategories;
}

- (NSArray *)orderedPreviousUsers {
    // sort the previous users by the number of checkins here
    if (!_orderedPreviousUsers) {
        NSArray *sortedPreviousUsers = [self.previousUsers sortedArrayUsingComparator:^NSComparisonResult(User *u1, User *u2) {
            int ch1 = [[[self.venue.activeUsers objectForKey:[NSString stringWithFormat:@"%d", u1.userID]] objectForKey:@"checkin_count"] integerValue];
            int ch2 = [[[self.venue.activeUsers objectForKey:[NSString stringWithFormat:@"%d", u2.userID]] objectForKey:@"checkin_count"] integerValue];
            if (ch1 > ch2) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if (ch1 < ch2) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        _orderedPreviousUsers = [[sortedPreviousUsers reverseObjectEnumerator] allObjects];
    }
    return _orderedPreviousUsers;
}

- (void)processUsers {
    // TODO: If this venue wasn't loaded by the map it will appear as if it has no active users
    // Add the ability to make an API call to get that data
    NSMutableDictionary *activeUsers = self.venue.activeUsers;
    
    // init the data structures
    self.currentUsers = [NSMutableDictionary dictionary];
    self.categoryCount = [NSMutableDictionary dictionary];
    self.previousUsers = [[NSMutableArray alloc] init];
    
    for (NSString *userID in activeUsers) {
        User *user = [[CPAppDelegate settingsMenuController].mapTabController userFromActiveUsers:[userID integerValue]];
        
        // make sure we get a user here
        // otherwise we'll crash when trying to add nil to self.previousUsers
        if (user) {
            if ([[[activeUsers objectForKey:userID] objectForKey:@"checked_in"] boolValue]) {
                [self addUser:user toArrayForJobCategory:user.majorJobCategory];
                // if the major and minor job categories differ also add this person to the minor category
                if (![user.majorJobCategory isEqualToString:user.minorJobCategory] &&
                    ![user.minorJobCategory isEqualToString:@"other"] &&
                    ![user.minorJobCategory isEqualToString:@""]) {
                    [self addUser:user toArrayForJobCategory:user.minorJobCategory];
                }
            } else {
                // this is a non-checked in user
                // add them to the previous users dictionary
                [self.previousUsers addObject:user];
            }
        }
    }
}

- (void)populateUserSection
{
    // reset our data
    [self processUsers];
    self.orderedCategories = nil;
    self.orderedPreviousUsers = nil;
    [self.tableView reloadData];
}
                            
- (void)addUser:(User *)user
    toArrayForJobCategory:(NSString *)jobCategory
{
    //If the jobCategory has a null value then don't show anything
    if(jobCategory)
    {
        // check if we already have an array for this category
        // and create one if we don't
        if (![self.currentUsers objectForKey:jobCategory]) {
            [self.currentUsers setObject:[NSMutableArray array] forKey:jobCategory];
            [self.categoryCount setObject:[NSNumber numberWithInt:0] forKey:jobCategory];
        }
        // add this user to that array
        [[self.currentUsers objectForKey:jobCategory] addObject:user];
        int currentCount = [[self.categoryCount objectForKey:jobCategory] intValue];
        [self.categoryCount setObject:[NSNumber numberWithInt:1 + currentCount] forKey:jobCategory];
    }
    else {
        #if DEBUG
            NSLog(@"User has nil value job category!!!!");
        #endif
    }
}

- (UIColor *)borderColor {
    return RGBA(198, 198, 198, 1.0);
}

- (UIColor *)cellBackgroundColor {
    return RGBA(237, 237, 237, 1.0);
}

- (void)stylingForUserBox:(UIView *)userBox
                withTitle:(NSString *)titleString
        forCheckedInUsers:(BOOL)isCurrentUserBox
{
    // border on category view
    userBox.layer.borderColor = [[self borderColor] CGColor];
    userBox.layer.borderWidth = 1.0;
    
    // background color for category view
    userBox.backgroundColor = [self cellBackgroundColor];
    
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

- (void)dismissViewControllerAnimated {
    [self dismissModalViewControllerAnimated:YES];
}

#define kButtonPhoneXOffset 2
#define kButtonAddressXOffset 10
#define kButtonYOffset 3

- (void)repositionAddressAndPhone
{
    if (self.hasAddress || self.hasPhone) {        
        // set the basic frame for the phone and address buttons
        CGRect phoneFrame = self.phoneButton.frame;
        phoneFrame.origin.x = self.bottomPhotoOverlayView.frame.size.width - phoneFrame.size.width - kButtonPhoneXOffset;
        phoneFrame.origin.y = kButtonYOffset;
        
        CGRect addressFrame = self.addressButton.frame;
        addressFrame.origin.x = kButtonAddressXOffset;
        addressFrame.origin.y = kButtonYOffset;
    
        if (!self.hasAddress || !self.hasPhone) {
            // only need to make changes if one is missing
            UIButton *move;
            if (!self.hasAddress) {
                move = self.phoneButton;
                self.addressButton.hidden = YES;
                    
                // move the phone button to the middle
                phoneFrame.origin.x = (self.bottomPhotoOverlayView.frame.size.width / 2) - (phoneFrame.size.width / 2);
            } else {
                move = self.addressButton;
                self.phoneButton.hidden = YES;
                    
                // move the address button to the middle
                addressFrame.origin.x = (self.bottomPhotoOverlayView.frame.size.width / 2) - (addressFrame.size.width / 2);
            }
        }
        
        self.phoneButton.frame = phoneFrame; 
        self.addressButton.frame = addressFrame;
    } else {        
        // hide both buttons - no need to show two "N/A" labels
        self.addressButton.hidden = YES;
        self.phoneButton.hidden = YES;        
        self.bottomPhotoOverlayView.alpha = 0.0;
        self.bottomPhotoOverlayView.userInteractionEnabled = NO;
    }
}

- (void)setupVenueButton:(UIButton *)venueButton
    withIconNamed:(NSString *)imageName
        andlabelText:(NSString *)labelText
{
    CGRect venueButtonFrame = venueButton.frame;
    venueButtonFrame.size.height = 36;
    venueButton.frame = venueButtonFrame;
    
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
    [CPUIHelper changeFontForLabel:buttonLabel toLeagueGothicOfSize:17];
    
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
    if ([self.venue.formattedPhone length] > 0 &&
        [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
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

- (IBAction)userImageButtonPressed:(UIButton *)sender
{
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showLoginBanner];
        
    }   else {
        UserProfileViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        
        // set the user object on that view controller
        // using the tag on the button to pull this user out of the NSMutableDictionary of user objects
        userVC.user = [self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", sender.tag]];
        
        // push the user profile onto this navigation controller stack
        [self.navigationController pushViewController:userVC animated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // variable to hold string that will open local app on phone
        NSString *urlString;
        
        if (alertView.tag == 1045) {
            // get the user's current location
            CLLocationCoordinate2D currentLocation = [CPAppDelegate locationManager].location.coordinate;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.categoryCount.count + (self.previousUsers.count > 0 ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < self.categoryCount.count) {
        return 1;
    } else {
        return self.previousUsers.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section < self.categoryCount.count) {
        // Display a single cell with all users in that category
        NSString *cellIdentifier = @"VenueCategoryCell";
        VenueCategoryCell *cell = (VenueCategoryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[VenueCategoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *category = [[self orderedCategories] objectAtIndex:indexPath.section];
        [self updateCategoryViewForCurrentUserCategory:category forCell:cell];
        return cell;
    } else {
        // Display one user per row
        NSString *cellIdentifier = @"VenueUserCell";
        VenueUserCell *cell = (VenueUserCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[VenueUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [CPUIHelper changeFontForLabel:cell.nameLabel toLeagueGothicOfSize:18];
        }
        User *user = [self.orderedPreviousUsers objectAtIndex:indexPath.row];
        cell.user = user;
        if (indexPath.row == self.orderedPreviousUsers.count - 1) {
            cell.separatorView.hidden = YES;
        } else {
            cell.separatorView.hidden = NO;
        }
        // assign the checkin hours
        NSString *userID = [NSString stringWithFormat:@"%d", user.userID];
        int checkinTime = [[[self.venue.activeUsers objectForKey:userID] objectForKey:@"checkin_time"] integerValue];
        cell.hoursLabel.text = [NSString stringWithFormat:@"%d hrs/week", checkinTime / 3600];

        cell.delegate = self;
        
        return cell;
    }
}

#pragma mark - Table view delegate
#define HEADER_HEIGHT 29
#define INTER_SECTION_SPACING 10
#define FOOTER_HEIGHT 5
#define CELL_GUTTER_WIDTH 10
#define BORDER_SIZE 1
#define IMAGE_TOP_OFFSET 5

- (UIButton *)thumbnailButtonForUser:(User *)user
                       withSquareDim:(CGFloat)thumbnailDim
                          andXOffset:(CGFloat)xOffset
                          andYOffset:(CGFloat)yOffset
{
    // setup a button for the user thumbnail
    UIButton *thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
    thumbButton.frame = CGRectMake(xOffset, yOffset, thumbnailDim, thumbnailDim);
    
    // set the tag to the user ID
    thumbButton.tag = user.userID;
    
    // add a target for this user thumbnail button
    [thumbButton addTarget:self action:@selector(userImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *userThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbnailDim, thumbnailDim)];
    
    //If the user is checkedIn virutally add a virtual badge to their image
    if(user.checkedIn) {
        [CPUIHelper manageVirtualBadgeForProfileImageView:userThumbnail
                                         checkInIsVirtual:user.checkInIsVirtual];
    } else {
        //Never show a virtual badge if they aren't checkin
        [CPUIHelper manageVirtualBadgeForProfileImageView:userThumbnail
                                         checkInIsVirtual:NO];
    }
    
    [CPUIHelper profileImageView:userThumbnail
             withProfileImageUrl:user.photoURL];
    // add a shadow to the imageview
    [CPUIHelper addShadowToView:userThumbnail color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:3 opacity:0.40];
    
    [thumbButton addSubview:userThumbnail];
    return thumbButton;
}

- (void)updateCategoryViewForCurrentUserCategory:(NSString *)category
                                         forCell:(VenueCategoryCell *)cell
{
    // remove previous contents
    for (UIView *subview in cell.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    if (self.currentUsers.count > 0) {
        CGFloat thumbnailDim = 71;
        CGFloat xOffset = 10;
        CGFloat gradientWidth = 45;
        for (User *user in [self.currentUsers objectForKey:category]) {
            UIButton *thumbButton = [self thumbnailButtonForUser:user
                                                   withSquareDim:thumbnailDim
                                                      andXOffset:xOffset
                                                      andYOffset:IMAGE_TOP_OFFSET];
            
            // add the thumbnail to the category view
            [cell.scrollView addSubview:thumbButton];
            
            // add to the xOffset for the next thumbnail
            xOffset += 10 + thumbButton.frame.size.width;
            
            if (![self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", user.userID]]) {
                [self addUserToDictionaryOfUserObjectsFromUser:user];
            }
        }
        // set the content size on the scrollview
        CGFloat newWidth = [[self.currentUsers objectForKey:category] count] * (thumbnailDim + 10) + gradientWidth;
        cell.scrollView.contentSize = CGSizeMake(newWidth, cell.scrollView.contentSize.height);
        cell.scrollView.showsHorizontalScrollIndicator = NO;
    }
}

- (CGFloat)cellWidth {
    return self.view.frame.size.width - (2 * CELL_GUTTER_WIDTH);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HEADER_HEIGHT + INTER_SECTION_SPACING;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *fullView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT + INTER_SECTION_SPACING)];
    fullView.backgroundColor = tableView.backgroundColor;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(CELL_GUTTER_WIDTH,
                                                            INTER_SECTION_SPACING,
                                                            self.cellWidth,
                                                            HEADER_HEIGHT)];
    [fullView addSubview:view];
    
    if (section < self.categoryCount.count) {
        NSString *title =  [[self orderedCategories] objectAtIndex:section];
        [self stylingForUserBox:view withTitle:title forCheckedInUsers:YES];
    } else {
        NSString *title = [self.previousUsers count] > 1 ? @"Have worked here..." : @"Has worked here...";
        [self stylingForUserBox:view withTitle:title forCheckedInUsers:NO];
    }
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(CELL_GUTTER_WIDTH + BORDER_SIZE,
                                                                    HEADER_HEIGHT + INTER_SECTION_SPACING - BORDER_SIZE,
                                                                    self.cellWidth - (2 * BORDER_SIZE),
                                                                    BORDER_SIZE)];
    bottomBorder.backgroundColor = view.backgroundColor;
    [fullView addSubview:bottomBorder];
    
    return fullView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    CGFloat kCellWidth = self.view.frame.size.width - (2 * CELL_GUTTER_WIDTH);
    UIView *fullView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, FOOTER_HEIGHT)];
    fullView.backgroundColor = tableView.backgroundColor;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(CELL_GUTTER_WIDTH, 0, kCellWidth, FOOTER_HEIGHT)];
    view.backgroundColor = [self borderColor];
    UIView *topBorder = [[UIView alloc]initWithFrame:CGRectMake(BORDER_SIZE, 0, kCellWidth - (2 * BORDER_SIZE), FOOTER_HEIGHT - BORDER_SIZE)];
    topBorder.backgroundColor = [self cellBackgroundColor];
    [view addSubview:topBorder];
    [fullView addSubview:view];
    return fullView;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
    [self unhighlightCells:YES];
}

# pragma mark - CPUserActionCellDelegate

- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(User*)user
{
    [CPUserAction cell:cell sendLoveFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(User*)user
{
    [CPUserAction cell:cell sendMessageFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(User*)user
{
    [CPUserAction cell:cell exchangeContactsFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(User*)user
{
    [CPUserAction cell:cell showProfileFromViewController:self];
}

- (void)unhighlightCells:(BOOL)animated {
    NSTimeInterval duration = 0;
    if (animated) {
        duration = 0.1;
    }
    
    [UIView animateWithDuration:duration animations:^{
        for (VenueUserCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:[VenueUserCell class]]) {
                cell.visibleView.backgroundColor = cell.inactiveColor;
            }
        }
    } completion:nil];
}

@end
