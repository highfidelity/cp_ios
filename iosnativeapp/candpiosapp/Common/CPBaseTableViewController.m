//
//  CPBaseTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPBaseTableViewController.h"
#import "CPUserActionCell.h"
#import "UserLoveViewController.h"
#import "OneOnOneChatViewController.h"
#import "UserProfileViewController.h"

@interface CPBaseTableViewController ()
@property (nonatomic, assign) BOOL showingHUD;

@end

@implementation CPBaseTableViewController
@synthesize delegate = _delegate;
@synthesize barSpinner = _barSpinner;
@synthesize showingHUD = _showingHUD;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // alloc-init a UIActivityIndicatorView to put in the navigation item
    self.barSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.barSpinner.hidesWhenStopped = YES;
    
    // set the rightBarButtonItem to that UIActivityIndicatorView 
    [self placeSpinnerOnRightBarButtonItem];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // place the settings button on the navigation item if required
    // or remove it if the user isn't logged in
    [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // dismiss our HUD if we were showing one
    if (self.showingHUD) {
        [SVProgressHUD dismiss];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)placeSpinnerOnRightBarButtonItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.barSpinner]; 
}

- (void)showCorrectLoadingSpinnerForCount:(int)count
{
    // show a progress hud if we don't have anybody
    // or show the spinner in the navigation item
    if (count > 0) {
        [self.barSpinner startAnimating];
    } else {
        self.showingHUD = YES;
        [SVProgressHUD showWithStatus:@"Loading..."];
    }
}

- (void)stopAppropriateLoadingSpinner
{
    // dismiss the SVProgressHUD and reload our data
    // or stop the navigationItem spinner
    if (self.showingHUD) {
        [SVProgressHUD dismiss];
        self.showingHUD = NO;
    } else {
        [self.barSpinner stopAnimating];
    }
}

# pragma mark - CPUserActionCellDelegate

- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(User*)user 
{
    // only show the love modal if this user is logged in
    if ([CPUserDefaultsHandler currentUser]) {
        // only show the love modal if this isn't the user themselves
        if (user.userID != [CPUserDefaultsHandler currentUser].userID) {
            UserLoveViewController *loveModal = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"SendLoveModal"];
            loveModal.user = user;
            
            [self presentModalViewController:loveModal animated:YES];
        }
    }    
}
- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(User*)user 
{
    // handle chat
    if (user.userID == [CPUserDefaultsHandler currentUser].userID) {
        // cheeky response for self-talk
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Self-Chat" 
                                                            message:@"It's quicker to chat with yourself in person." 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    // get a user object with resume data.. which includes its contact settings
    [user loadUserResumeData:^(NSError *error) {
        if (!error) {
            if (user.contactsOnlyChat && !user.isContact) {
                NSString *errorMessage = [NSString stringWithFormat:@"You can not chat with %@ until the two of you have exchanged contact information", user.nickname];
                [SVProgressHUD showErrorWithStatus:errorMessage
                                          duration:kDefaultDimissDelay];
            } else {
                // push the UserProfileViewController onto the navigation controller stack
                OneOnOneChatViewController *chatViewController = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"OneOnOneChatView"];
                chatViewController.user = user; 
                [self.navigationController pushViewController:chatViewController animated:YES];
            }
        } else {
            // error checking for load of user
            NSLog(@"Error in user load during chat request.");
        }
    }];
}

- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(User*)user
{
    // Offer to exchange contacts
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:kRequestToAddToMyContactsActionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Send"
                                  otherButtonTitles: nil
                                  ];
    actionSheet.tag = user.userID;
    [actionSheet showInView:self.view];    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    // Exchange contacts if accepted
    if ([actionSheet title] == kRequestToAddToMyContactsActionSheetTitle) {
        if (buttonIndex != [actionSheet cancelButtonIndex]) {
            [CPapi sendContactRequestToUserId:actionSheet.tag];
        }
    }
}

- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(User*)user 
{
    if (![CPUserDefaultsHandler currentUser]) {
        [CPAppDelegate showLoginBanner];
        cell.selected = NO;
    } else { 
        UserProfileViewController *userVC = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        // set the user object on the UserProfileVC to the user we just created
        userVC.user = user;
        
        // push the UserProfileViewController onto the navigation controller stack
        [self.navigationController pushViewController:userVC animated:YES];
    }
    
}



@end
