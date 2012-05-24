//
//  VenueInfoViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueInfoViewController.h"
#import "MapTabController.h"
#import "CheckInDetailsViewController.h"
#import "UserProfileViewController.h"
#import "MapDataSet.h"
#import "VenueChat.h"
#import "VenueChatEntry.h"
#import "CheckinChatEntry.h"
#import "UIButton+AnimatedClockHand.h"

#define CHAT_MESSAGE_ORIGIN_X 11

@interface VenueInfoViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSTimer *chatReloadTimer;
@property (nonatomic, strong) VenueChat *venueChat;
@property (weak, nonatomic) IBOutlet UIView *bottomPhotoOverlayView;
@property (weak, nonatomic) IBOutlet UIView *venueChatBox;
@property (weak, nonatomic) IBOutlet UIView *venueChatBoxVerticalLine;
@property (weak, nonatomic) IBOutlet UILabel *activeChatters;
@property (weak, nonatomic) IBOutlet UIImageView *activeChattersIcon;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activeChattersIndicator;
@property (weak, nonatomic) IBOutlet UILabel *activeChatText;
@property (weak, nonatomic) UIButton *checkInButton;
@property (weak, nonatomic) UIButton *phoneButton;
@property (weak, nonatomic) UIButton *addressButton;
@property (assign, nonatomic) BOOL hadNoChat;
@property (assign, nonatomic) BOOL checkInIsVirtual;
@property (assign, nonatomic) BOOL hasPhone;
@property (assign, nonatomic) BOOL hasAddress;

- (IBAction)tappedAddress:(id)sender;
- (IBAction)tappedPhone:(id)sender;
- (void)refreshVenueData:(CPVenue *)venue;
- (void)populateUserSection;
- (void)checkInPressed:(id)sender;
- (void)reloadVenueChat;

- (void)addUser:(User *)user
    toArrayForJobCategory:(NSString *)jobCategory;

- (UIView *)categoryViewForCurrentUserCategory:(NSString *)category
                                   withYOrigin:(CGFloat)yOrigin;

- (UIView *)viewForPreviousUsersWithYOrigin:(CGFloat)yOrigin;

- (void)stylingForUserBox:(UIView *)userBox
                withTitle:(NSString *)titleString
        forCheckedInUsers:(BOOL)isCurrentUserBox;


@end

@implementation VenueInfoViewController

@synthesize scrollView = _scrollView;
@synthesize venue = _venue;
@synthesize venuePhoto = _venuePhoto;
@synthesize bottomPhotoOverlayView = _bottomPhotoOverlayView;
@synthesize firstAidSection = _firstAidSection;
@synthesize userSection = _userSection;
@synthesize categoryCount = _categoryCount;
@synthesize currentUsers = _currentUsers;
@synthesize previousUsers = _previousUsers;
@synthesize usersShown = _usersShown;
@synthesize userObjectsForUsersOnScreen = _userObjectsForUsersOnScreen;
@synthesize scrollToUserThumbnail = _scrollToUserThumbnail;
@synthesize chatReloadTimer = _chatReloadTimer;
@synthesize venueChat = _venueChat;
@synthesize venueChatBox = _venueChatBox;
@synthesize venueChatBoxVerticalLine = _venueChatBoxVerticalLine;
@synthesize activeChatters = _activeChatters;
@synthesize activeChattersIcon = _activeChattersIcon;
@synthesize activeChattersIndicator = _activeChattersIndicator;
@synthesize activeChatText = _activeChatText;
@synthesize checkInButton = _checkInButton;
@synthesize hadNoChat = _hadNoChat;
@synthesize checkInIsVirtual = _checkInIsVirtual;
@synthesize hasPhone = _hasPhone;
@synthesize hasAddress = _hasAddress;
@synthesize phoneButton = _phoneButton;
@synthesize addressButton = _addressButton;

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

- (VenueChat *)venueChat
{
    if (!_venueChat) {
        _venueChat = [[VenueChat alloc] initWithVenueID:self.venue.venueID];
    }
    return _venueChat;
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
    
    
    // set the property on the tab bar controller for the venue we're looking at
    [CPAppDelegate tabBarController].currentVenueID = self.venue.foursquareID;
    
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
    
    [self repositionAddressAndPhone:NO];
    
    // put the texture in the bottom view
    self.firstAidSection.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-first-aid-kit"]];
    
    // border on venue chat box
    // color gets set in view will appear
    self.venueChatBox.layer.borderWidth = 1.0;
    
    // change the active chat labels to league gothic
    [CPUIHelper changeFontForLabel:self.activeChatters toLeagueGothicOfSize:18];
    [CPUIHelper changeFontForLabel:self.activeChatText toLeagueGothicOfSize:18];
    
    // setup a UIButton to hold the venue chat box
    UIButton *venueChatButton = [[UIButton alloc] initWithFrame:self.venueChatBox.frame];
    
    // targets for the venueChatButton
    [venueChatButton addTarget:self action:@selector(showVenueChat) forControlEvents:UIControlEventTouchUpInside];
    [venueChatButton addTarget:self action:@selector(highlightedVenueChatButton) forControlEvents:UIControlEventTouchDown];
    [venueChatButton addTarget:self action:@selector(normalVenueChatButton) forControlEvents:UIControlEventTouchUpOutside];
    
    // hide the activeChatters text and icon when we're loading chat history
    self.activeChatters.alpha = 0.0;
    self.activeChattersIcon.alpha = 0.0;
    
    // disable user interaction on the chat box so the button gets the touch events
    self.venueChatBox.userInteractionEnabled = NO;
    
    // add the button to the bottom section
    [self.firstAidSection addSubview:venueChatButton];
    
    // set hadNoChat to no, it may be changed when the chat gets loaded
    self.hadNoChat = NO;

    [self populateUserSection]; 
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([CPAppDelegate currentUser]) {
        [self reloadVenueChat];
        self.chatReloadTimer = [NSTimer scheduledTimerWithTimeInterval:VENUE_CHAT_RELOAD_INTERVAL target:self selector:@selector(reloadVenueChat) userInfo:nil repeats:YES];
    } else {
        [self hideVenueChatFromAnonymousUser];
    }
    
    // make sure the button borders are back to grey
    [self normalVenueChatButton];
    
    [self checkInAllowed];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.chatReloadTimer) {
        [self.chatReloadTimer invalidate];
        self.chatReloadTimer = nil;
    }    
    
    // stop a request to get venue chat if this view is dissapearing as that fudges up the next view controller
    [self.venueChat.chatQueue cancelAllOperations];

}

- (void)viewDidUnload
{
    [self setVenuePhoto:nil];
    [self setUserSection:nil];
    [self setActiveChatters:nil];
    [self setFirstAidSection:nil];
    [self setVenueChatBox:nil];
    [self setActiveChattersIcon:nil];
    [self setActiveChattersIndicator:nil];
    [self setActiveChatText:nil];
    [self setCheckInButton:nil];
    [self setVenueChatBoxVerticalLine:nil];
    [super viewDidUnload];
    [CPAppDelegate tabBarController].currentVenueID = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshVenueAfterCheckin" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userCheckinStateChange" object:nil];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)isCheckedInHere
{
    return [CPAppDelegate userCheckedIn] && [CPAppDelegate currentVenue].venueID == self.venue.venueID;
}

- (void)refreshVenueViewCheckinButton
{ 
    if (!self.checkInButton) {
        self.checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // add the clock hand and set the button to the right state
        [self.checkInButton refreshButtonStateWithBoolean:[self isCheckedInHere]];
    
        CGRect checkInButtonFrame = self.bottomPhotoOverlayView.frame;
        checkInButtonFrame.size = [CPUIHelper buttonCheckinImage].size;
        checkInButtonFrame.origin.x = ((self.bottomPhotoOverlayView.frame.size.width - checkInButtonFrame.size.width) / 2);
        checkInButtonFrame.origin.y -= 25;
        
        self.checkInButton.frame = checkInButtonFrame;
        
        [self.bottomPhotoOverlayView.superview addSubview:self.checkInButton];
        [self.checkInButton addTarget:self action:@selector(checkInPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.checkInButton refreshButtonStateWithBoolean:[self isCheckedInHere]];
    }
}

- (void)refreshVenueData:(NSNotification *)notification
{
    // we'll get a notification if this venue has been updated (by an API call)
    // so set our venue to that as information will be updated
    self.venue = notification.object;

    // repopulate user data with new info
    [self populateUserSection];    
}

- (void)hideVenueChatFromAnonymousUser
{
    // this is hard coded to 10 for now
    // not an actual representation of the number of active people chatting
    // just here to entice users who aren't logged in
    self.activeChatters.text = @"10";
    self.activeChatText.text = @"Please login to chat.";
    
    // stop the loading spinner
    [self stopActiveChattersLoadingIndicator];
}

- (void)stopActiveChattersLoadingIndicator
{
    if ([self.activeChattersIndicator isAnimating]) {
        
        [UIView animateWithDuration:0.5 animations:^{
            // stop the spinner
            [self.activeChattersIndicator stopAnimating];
            
            // show the number of active chatters and the number of active
            self.activeChatters.alpha = 1.0;
            self.activeChattersIcon.alpha = 1.0;
        }];
        
    }
}

- (void)reloadVenueChat
{    
    [self.venueChat getNewChatEntriesWithCompletion:^(BOOL authenticated, NSArray *newEntries){
        if (authenticated) {
            if (newEntries) {
                
                // there are new entries so it's time to update
                if (self.hadNoChat) {
                    // move the icon back over
                    CGRect moveRight = self.activeChattersIcon.frame;
                    moveRight.origin.x += 9;
                    self.activeChattersIcon.frame = moveRight;
                    
                    // unhide the number of active chatters
                    self.activeChatters.hidden = NO;
                }
                
                self.activeChatters.text = [NSString stringWithFormat:@"%d", self.venueChat.activeChattersDuringInterval];
                
                // display the new chat message
                [self slideAwayChatMessageAndDisplayNewChat:YES];
                
            } else if (self.venueChat.activeChattersDuringInterval > 0) {
                
                // we didn't get a new message but we need to make sure the latest is showing
                [self slideAwayChatMessageAndDisplayNewChat:NO];
                
            } else if (self.venueChat.activeChattersDuringInterval == 0) {
                [self showTapToChat];
            } 
            
            [self stopActiveChattersLoadingIndicator];
        } else {
            // user isn't actually logged in
            [self hideVenueChatFromAnonymousUser];
            // make sure nothing is lingering ... this user isn't logged in
            [CPAppDelegate logoutEverything];
        }   
     
        
    }];
}

- (void)slideAwayChatMessageAndDisplayNewChat:(BOOL)newEntry
{
    // reset the frame of the chat message
    CGRect originalFrame = self.activeChatText.frame;
    originalFrame.origin.x = CHAT_MESSAGE_ORIGIN_X;
    self.activeChatText.frame = originalFrame;
    
    VenueChatEntry *lastEntry = [self.venueChat.chatEntries lastObject];
    BOOL entryToShow = YES;
    
    if ([lastEntry isKindOfClass:[CheckinChatEntry class]]) {
        if (self.venueChat.chatEntries.count == 1) {
            // the only entry we have is a checkin message so don't show it
            entryToShow = NO;
        } else {
            // enumerate through the chat entries to make sure we have a message that isn't a checkin message to show
            for (VenueChatEntry *possibleLast in [self.venueChat.chatEntries reverseObjectEnumerator]) {
                if (![possibleLast isKindOfClass:[CheckinChatEntry class]] && ![possibleLast isKindOfClass:[NSString class]]) {
                    // indicate that we'll show an entry
                    entryToShow = YES;
                    // change the lastEntry variable to this entry
                    lastEntry = possibleLast;
                    // break from the for loop
                    break;
                } else {
                    entryToShow = NO;
                }
            }
        }
    } 
    
    if (entryToShow) {
        if (newEntry) {
            // we have a new entry so let's slide this old thing over and show it
            CGRect newFrame = originalFrame;
            newFrame.origin.x = newFrame.origin.x - [self.activeChatText sizeThatFits:self.activeChatText.frame.size].width - 10; 
            
            // animation to slide away the currently displayed chat
            [UIView animateWithDuration:1.5 delay:1.0 options:UIViewAnimationCurveEaseInOut animations:^{
                self.activeChatText.frame = newFrame;
            } completion:^(BOOL finished) {
                if (finished) {            
                    // hide it and move it into place
                    self.activeChatText.alpha = 0;
                    self.activeChatText.frame = originalFrame;
                    
                    // set the new text to the next entry
                    self.activeChatText.text = [NSString stringWithFormat:@"\"%@\"", lastEntry.text];
                    
                    // fade in the text
                    [UIView animateWithDuration:0.3 animations:^{
                        self.activeChatText.alpha = 1.0;
                    } completion:nil];
                }
            }];
        } else {
            // didn't get a newEntry but let's make sure the latest is showing
            self.activeChatText.text = [NSString stringWithFormat:@"\"%@\"", lastEntry.text];
        }
    } else {
        [self showTapToChat];
    }
}

- (void)showTapToChat
{
    // move the active chatters icon over if required
    if (!self.hadNoChat) {
        // center the icon
        CGRect newFrame = self.activeChattersIcon.frame;
        newFrame.origin.x -= 9;
        self.activeChattersIcon.frame = newFrame;
        
        // hide the number of active chatters
        self.activeChatters.hidden = YES;
        
        // set the hadNoChat boolean so we know we need to move things if we get chat
        self.hadNoChat = YES;
    }           
    
    // static message for no chat
    self.activeChatText.text = @"Tap here to chat.";
}

- (void)highlightedVenueChatButton
{
    // the button is currently highlighted so make the borders orange
    // border on venue chat box
    UIColor *orange = [UIColor colorWithRed:(181.0/255.0) green:(107.0/255.0) blue:(0/255.0) alpha:1.0];
    self.venueChatBox.layer.borderColor = [orange CGColor];
    self.venueChatBoxVerticalLine.backgroundColor = orange;
}

- (void)normalVenueChatButton
{
    // the button has gone back to normal so bring the borders back to the grey color
    // border on venue chat box
    UIColor *grey = [UIColor colorWithRed:(198.0/255.0) green:(198.0/255.0) blue:(198.0/255.0) alpha:1.0];
    self.venueChatBox.layer.borderColor = [grey CGColor];
    self.venueChatBoxVerticalLine.backgroundColor = grey;
}

- (void)showVenueChat
{
    if ([CPAppDelegate currentUser]) {
        [self performSegueWithIdentifier:@"ShowVenueChatFromVenue" sender:self];
    } else {
        // prompt the user to login
        [CPAppDelegate showLoginBanner];
        [self normalVenueChatButton];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // back button should say back and not the venue name for this transition
    UIBarButtonItem *backButton = [[ UIBarButtonItem alloc] init];
    backButton.title = @"Back";
    self.navigationItem.backBarButtonItem = backButton;
    
    // give the venue and venue chat to the VenueChatViewController
    [segue.destinationViewController setVenue:self.venue];
    
    // only pass the venue chat to the VenueChatViewController if it's ready
    if (self.venueChat.hasLoaded) {
        [segue.destinationViewController setVenueChat:self.venueChat];
    }
}

- (void)populateUserSection
{
    // clear out the current user section
    for (UIView *subview in [self.userSection subviews]) {
        [subview removeFromSuperview];
    }
    
    // this is where we add the users and the check in button to the bottom of the scroll view
    
    // TODO: If this venue wasn't loaded by the map it will appear as if it has no active users
    // Add the ability to make an API call to get that data
    NSMutableDictionary *activeUsers = self.venue.activeUsers;

    // init the data structures
    self.currentUsers = [NSMutableDictionary dictionary];
    self.categoryCount = [NSMutableDictionary dictionary];
    self.previousUsers = [[NSMutableArray alloc] init];
    self.usersShown =  [NSMutableSet set];
    
    for (NSString *userID in activeUsers) {
        User *user = [[CPAppDelegate settingsMenuController].mapTabController userFromActiveUsers:[userID integerValue]];
        
        // make sure we get a user here
        // otherwise we'll crash when trying to add nil to self.previousUsers
        if (user) {
            if ([[[activeUsers objectForKey:userID] objectForKey:@"checked_in"] boolValue]) {
                [self addUser:user toArrayForJobCategory:user.majorJobCategory];
                // if the major and minor job categories differ also add this person to the minor category
                if (![user.majorJobCategory isEqualToString:user.minorJobCategory] && ![user.minorJobCategory isEqualToString:@"other"]) {
                    [self addUser:user toArrayForJobCategory:user.minorJobCategory];
                }
            } else {
                // this is a non-checked in user
                // add them to the previous users dictionary
                [self.previousUsers addObject:user];
            }
        }
    }
    
    // setup a frame to keep spacing between elements
    CGRect newFrame = CGRectZero;
    newFrame.origin.y = 9;
    
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
    
    float viewForPreviousOrigin = newFrame.origin.y == 9 ? newFrame.origin.y : newFrame.origin.y + 15;
    // place previously checked in users on screen
    UIView *previousView = [self viewForPreviousUsersWithYOrigin:viewForPreviousOrigin];
    
    // show the previousView if it exists
    if (previousView) {
        [self.userSection addSubview:previousView];
        newFrame.origin.y = previousView.frame.origin.y + previousView.frame.size.height;
    }    
    
    // resize the user section frame
    CGRect newSectionFrame = self.userSection.frame;
    newSectionFrame.size.height = newFrame.origin.y + newFrame.size.height;
     
    if (newSectionFrame.size.height > self.userSection.frame.size.height) {
        self.userSection.frame = newSectionFrame;
    }
    
    // resize the first aid box
    newSectionFrame = self.firstAidSection.frame;
    newSectionFrame.size.height = self.venueChatBox.frame.size.height + self.userSection.frame.size.height;
    self.firstAidSection.frame = newSectionFrame;
    
    // set the scrollview content size
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.venuePhoto.frame.size.height + self.firstAidSection.frame.size.height); 
    
    // clear the SVProgressHUD if it's shown
    [SVProgressHUD dismiss];
    
    if (self.scrollToUserThumbnail) {
        // we need to find the userThumbnail and scroll to it
        UIButton *userButton = (UIButton *)[self.view viewWithTag:[CPAppDelegate currentUser].userID];
        UIScrollView *parentScroll = (UIScrollView *)userButton.superview;
        UIView *categoryView = parentScroll.superview;
        
        // scroll to the right category view
        CGPoint viewTop = [categoryView.superview convertPoint:categoryView.frame.origin toView:self.scrollView];
        
        if (self.scrollView.contentSize.height - viewTop.y < self.view.frame.size.height) {
            // we need to make sure we don't have white space under the scroll view after changing content offset
            viewTop.y -= self.view.frame.size.height - (self.scrollView.contentSize.height - viewTop.y);
        } 
        
        [self.scrollView setContentOffset:CGPointMake(0, viewTop.y) animated:YES];
        
        // scroll to the user thubmnail
        [parentScroll setContentOffset:CGPointMake(userButton.frame.origin.x - 10, 0) animated:YES];
        
        // completed scroll to user thumbnail, don't do it again
        self.scrollToUserThumbnail = NO;
    }    
}
                            
- (void)addUser:(User *)user
    toArrayForJobCategory:(NSString *)jobCategory
{
    //If the jobCategory has a null value then don't show anything
    if(jobCategory != Nil)
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

- (void)addUserToDictionaryOfUserObjectsFromUser:(User *)user
{
    [self.userObjectsForUsersOnScreen setObject:user forKey:[NSString stringWithFormat:@"%d", user.userID]];
}

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
    if(user.checkedIn)
    {
        [CPUIHelper manageVirtualBadgeForProfileImageView:userThumbnail
                                         checkInIsVirtual:user.checkInIsVirtual];
    }
    else {
        //Never show a virtual badge if they aren't checkin
        [CPUIHelper manageVirtualBadgeForProfileImageView:userThumbnail
                                         checkInIsVirtual:NO];
    }

    [CPUIHelper profileImageView:userThumbnail
             withProfileImageUrl:user.urlPhoto];
    // add a shadow to the imageview
    [CPUIHelper addShadowToView:userThumbnail color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:3 opacity:0.40];

    [thumbButton addSubview:userThumbnail];
    
    return thumbButton;
}

- (UIView *)categoryViewForCurrentUserCategory:(NSString *)category
                        withYOrigin:(CGFloat)yOrigin;
{

    UIView *categoryView = nil;
    
    if (self.currentUsers.count > 0) {
        categoryView = [[UIView alloc] initWithFrame:CGRectMake(10, yOrigin, self.view.frame.size.width - 20, 113)]; 
        
        [self stylingForUserBox:categoryView withTitle:category forCheckedInUsers:YES];
        
        CGFloat thumbnailDim = 71;
        
        UIScrollView *usersScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 29, categoryView.frame.size.width, thumbnailDim)];
        
        // add the scroll view to the category box
        [categoryView addSubview:usersScrollView];
        
        CGFloat xOffset = 10;
        for (User *user in [self.currentUsers objectForKey:category]) {
            
            UIButton *thumbButton = [self thumbnailButtonForUser:user withSquareDim:thumbnailDim andXOffset:xOffset andYOffset:0];
            
            // add the thumbnail to the category view
            [usersScrollView addSubview:thumbButton];
            
            // add to the xOffset for the next thumbnail
            xOffset += 10 + thumbButton.frame.size.width;
            
            // add this user to the usersShown set so we know we have them
            [self.usersShown addObject:[NSNumber numberWithInt:user.userID]];
            
            if (![self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", user.userID]]) {
                [self addUserToDictionaryOfUserObjectsFromUser:user];
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

    }
    
    // return the view (or nil if we didn't create it)
    return categoryView;    
}

- (UIView *)viewForPreviousUsersWithYOrigin:(CGFloat)yOrigin
{
    UIView *previousUsersView = nil;
    if (self.previousUsers.count > 0) {
        previousUsersView = [[UIView alloc] initWithFrame:CGRectMake(10, yOrigin, self.view.frame.size.width - 20, 113)];
        
        NSString *title = [self.previousUsers count] > 1 ? @"Have worked here..." : @"Has worked here...";
        [self stylingForUserBox:previousUsersView withTitle:title forCheckedInUsers:NO];
        
        CGRect newFrame = previousUsersView.frame;
        
        CGFloat yOffset = 29;
        
        UIView *lastLine;
        
        // sort the previous users by the number of checkins here
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
        
        for (User *previousUser in [sortedPreviousUsers reverseObjectEnumerator]) {
            // make sure we aren't already showing this user as checked in or as a previous user
            if (![self.usersShown containsObject:[NSNumber numberWithInt:previousUser.userID]]) {
                // setup the user thumbnail
                UIButton *userThumbnailButton = [self thumbnailButtonForUser:previousUser withSquareDim:71 andXOffset:10 andYOffset:yOffset];
                
                // add the thumbnail to the view
                [previousUsersView addSubview:userThumbnailButton];
                
                CGFloat maxLabelWidth = previousUsersView.frame.size.width - (userThumbnailButton.frame.size.width + userThumbnailButton.frame.origin.x) - 20;
                CGFloat leftOffset = userThumbnailButton.frame.origin.x + userThumbnailButton.frame.size.width + 10;
                
                // make the button clickable area extend over the user data as well
                CGRect buttonFrame = userThumbnailButton.frame;
                buttonFrame.size.width = userThumbnailButton.superview.frame.size.width - 20;
                userThumbnailButton.frame = buttonFrame;
                
                // label for the user name
                UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, yOffset + 10, maxLabelWidth, 20)];
                userName.text = [CPUIHelper profileNickname: previousUser.nickname];
                [CPUIHelper changeFontForLabel:userName toLeagueGothicOfSize:18];
                userName.backgroundColor = [UIColor clearColor];
                userName.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
                
                // add the username to the previousUsersView
                [previousUsersView addSubview:userName];
                
                CGFloat labelOffset = yOffset;
                
                UIColor *lightGray = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
                
                if ([previousUser.jobTitle length] > 0) {
                    // label for user headline
                    labelOffset += 27;
                    UILabel *userHeadline = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, labelOffset, maxLabelWidth, 20)];
                    userHeadline.text = previousUser.jobTitle;
                    
                    userHeadline.backgroundColor = [UIColor clearColor];
                    userHeadline.textColor = lightGray;
                    userHeadline.font = [UIFont systemFontOfSize:12];
                    
                    // add the label to the previousUsersView
                    [previousUsersView addSubview:userHeadline];
                } else {
                    labelOffset += 11;
                }
                
                UILabel *userCheckins = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, labelOffset + 16, maxLabelWidth, 20)];
                NSString *userID = [NSString stringWithFormat:@"%d", previousUser.userID];
                int checkinTime = [[[self.venue.activeUsers objectForKey:userID] objectForKey:@"checkin_time"] integerValue];
                userCheckins.text = [NSString stringWithFormat:@"%d hrs/week", checkinTime / 3600];
                
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
                [self.usersShown addObject:[NSNumber numberWithInt:previousUser.userID]];
                
                
                // put a line to seperate the users
                UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(userThumbnailButton.frame.origin.x, yOffset - 6, previousUsersView.frame.size.width - 20, 1)];
                seperator.backgroundColor = [UIColor colorWithRed:(198.0/255.0) green:(198.0/255.0) blue:(198.0/255.0) alpha:0.75];
                
                [previousUsersView addSubview:seperator];   
                
                // this is the new last line
                lastLine = seperator;
                
                [self addUserToDictionaryOfUserObjectsFromUser:previousUser];            
            }        
        }
        // remove the last line since we won't need it
        [lastLine removeFromSuperview];
        
        // grow the previousUsersView frame to accomodate all users
        previousUsersView.frame = newFrame;
    }
    
    // if there's at least on user to show then return a view otherwise be nil
    return previousUsersView;        
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
- (void)checkInAllowed
{
    self.checkInIsVirtual = NO;
    
    //Find the distance between the user and the venue in Meters
    CLLocation *venueLocation= [[CLLocation alloc] initWithLatitude:self.venue.coordinate.latitude longitude:self.venue.coordinate.longitude];
    double distanceFromUserMeters = [venueLocation distanceFromLocation:[[AppDelegate instance].settings lastKnownLocation]];
    //double venueDistance = self.venue.distanceFromUser;
    if(distanceFromUserMeters>300)
    {
        // User is more than 300m from venue so only a virtual checkin is possible.
        // If the user has a contact in the venue then they can checkin, otherwise it is not allowed
        //and the checkin button will not appear.
        if(self.venue.hasContactAtVenue)
        {
            [self checkInButtonSetup];
            self.checkInIsVirtual = YES;
        }

    }
    else
    {
        //If the user is within 300m of the venue they can checkin to that venue
        [self checkInButtonSetup];
    }
        

}



- (void)checkInButtonSetup
{
    // reposition the address and phone if required 
    // or just show them now that we have the button
    [self repositionAddressAndPhone:YES];
    
    //from viewwillappear
    // place the checkin button on screen and make sure it is consistent with the user states
    [self refreshVenueViewCheckinButton];
    
    //from viewDidLoad
    //Add observer to update checkIn button
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refreshVenueViewCheckinButton) 
                                                 name:@"userCheckinStateChange" 
                                               object:nil];
    
    
    
}

- (void)checkInPressed:(id)sender
{
    if (![CPAppDelegate currentUser]) {
        [CPAppDelegate showLoginBanner];
    } else {
        if ([CPAppDelegate userCheckedIn] && [CPAppDelegate currentVenue].venueID == self.venue.venueID){
            // user is checked in here so ask them if they want to be checked out
            [CPAppDelegate promptForCheckout];
        } else {
            // show them the check in screen
            CheckInDetailsViewController *checkinVC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckinDetailsViewController"];
            checkinVC.place = self.venue;
            
            // be the delgate of the check in view controller
            checkinVC.delegate = self;
            
            // Pass whether the checkin is virtual or non-virtual
            checkinVC.checkInIsVirtual = self.checkInIsVirtual;
            
            [self.navigationController pushViewController:checkinVC animated:YES];
        }
    }
}

- (void)dismissViewControllerAnimated {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)cancelCheckinModal
{
    [self.modalViewController dismissModalViewControllerAnimated:YES];
}

- (void)repositionAddressAndPhone:(BOOL)checkinButtonIsShown
{
    
    // we're here because we have no checkin button and as such the address and phone may need to be moved
    if (self.hasAddress || self.hasPhone) {
        
        // set the basic frame for the phone and address buttons
        CGRect phoneFrame = self.phoneButton.frame;
        phoneFrame.origin.x = 11 + round((self.bottomPhotoOverlayView.frame.size.width + 64) / 2);
        phoneFrame.origin.y = 3;
             
        
        CGRect addressFrame = self.addressButton.frame;
        addressFrame.origin.x = round((self.bottomPhotoOverlayView.frame.size.width - 64) / 2) - 5 - addressFrame.size.width;
        addressFrame.origin.y = 3;
        
    
        if (!self.hasAddress || !self.hasPhone) {
            // only need to make changes if one is missing
            if (!checkinButtonIsShown) {
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
            } else {
                // make sure the phone button is around
                self.phoneButton.hidden = NO;
                // make sure the address button is around
                self.addressButton.hidden = NO;
                
                // no need to touch the frame here ... it'll get reset
            }
        }
        
        self.phoneButton.frame = phoneFrame; 
        self.addressButton.frame = addressFrame;
    } else {
        if (checkinButtonIsShown) {
            // fade in the bottom bar
            self.bottomPhotoOverlayView.userInteractionEnabled = YES;
            
            [UIView animateWithDuration:0.5 animations:^{
                self.bottomPhotoOverlayView.alpha = 1.0;
            }];
        } else {
            self.bottomPhotoOverlayView.alpha = 0.0;
            self.bottomPhotoOverlayView.userInteractionEnabled = NO;
        }
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

- (IBAction)userImageButtonPressed:(id)sender
{
    if (![CPAppDelegate currentUser]) {
        [CPAppDelegate showLoginBanner];

    }   else {
        UserProfileViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];

        UIButton *thumbnailButton = (UIButton *)sender;

        // set the user object on that view controller
        // using the tag on the button to pull this user out of the NSMutableDictionary of user objects
        userVC.user = [self.userObjectsForUsersOnScreen objectForKey:[NSString stringWithFormat:@"%d", thumbnailButton.tag]];

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
