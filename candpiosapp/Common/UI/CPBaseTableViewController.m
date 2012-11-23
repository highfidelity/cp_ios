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
    self.tableView.allowsSelection = NO;
    
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // calling the animation directly is not respecting duration
    [self unhighlightCells:YES];
}

- (UIView *)tabBarButtonAvoidingFooterView
{
    return [[UIView alloc] initWithFrame:CGRectMake(0,
                                                    0,
                                                    self.tableView.frame.size.width,
                                                    [[CPAppDelegate tabBarController].thinBar actionButtonRadius])];
}

- (void)unhighlightCells:(BOOL)animated {
    NSTimeInterval duration = 0;
    if (animated) {
        duration = 0.1;
    }
    
    [UIView animateWithDuration:duration animations:^{
        for (CPUserActionCell *cell in self.tableView.visibleCells) {
            if ([cell respondsToSelector:@selector(highlight:)]) {
                [cell highlight:NO];
            }
        }
    } completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self unhighlightCells:YES];
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}


# pragma mark - CPUserActionCellDelegate

- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(CPUser*)user 
{
    [CPUserAction cell:cell sendLoveFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(CPUser*)user 
{
    [CPUserAction cell:cell sendMessageFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(CPUser*)user
{
    [CPUserAction cell:cell exchangeContactsFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(CPUser*)user 
{
    [CPUserAction cell:cell showProfileFromViewController:self];
}


@end
