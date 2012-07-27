//
//  CPBaseTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPBaseTableViewController.h"
#import "CPUserActionCell.h"
#import "CPUserAction.h"
#import "UserLoveViewController.h"
#import "OneOnOneChatViewController.h"
#import "UserProfileViewController.h"

@interface CPBaseTableViewController ()
@property (nonatomic) BOOL showingHUD;

@end

@implementation CPBaseTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // alloc-init a UIActivityIndicatorView to put in the navigation item
    self.barSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.barSpinner.hidesWhenStopped = YES;
    
    // set the rightBarButtonItem to that UIActivityIndicatorView 
    [self placeSpinnerOnRightBarButtonItem];
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    // Exchange contacts if accepted
    if ([actionSheet title] == kRequestToAddToMyContactsActionSheetTitle) {
        if (buttonIndex != [actionSheet cancelButtonIndex]) {
            [CPapi sendContactRequestToUserId:actionSheet.tag];
        }
    }
}


@end
