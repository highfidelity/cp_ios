//
//  LinkedAccountsTableViewController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/03/20.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LinkedAccountsTableViewController.h"

@interface LinkedAccountsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *postToLinkedInSwitch;
@property (nonatomic) BOOL postToLinkedIn;

@end

@implementation LinkedAccountsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SVProgressHUD show];
    
    [CPapi getLinkedInPostStatus:^(NSDictionary *json, NSError *error) {
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        if (!error && !respError) {
            [self setPostToLinkedIn:[[[json objectForKey:@"payload"] objectForKey:@"post_to_linkedin"] boolValue]];
            [[self postToLinkedInSwitch] setOn:[self postToLinkedIn]];
            [SVProgressHUD dismiss];
        } else {
            [[CPAppDelegate settingsMenuViewController] slideAwayChildViewController];
            NSString *message = [json objectForKey:@"payload"];
            if (!message) {
                message = @"Oops. Something went wrong.";    
            }
            [SVProgressHUD dismissWithError:message 
                                 afterDelay:kDefaultDismissDelay];
        }
    }];

    self.tableView.separatorColor = [UIColor colorWithRed:(68/255.0) green:(68/255.0) blue:(68/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(IBAction)gearPressed:(id)sender {
    if ([self postToLinkedIn] != [[self postToLinkedInSwitch] isOn]) {
        [CPapi saveLinkedInPostStatus:[[self postToLinkedInSwitch] isOn]];
    }
    
    [[CPAppDelegate settingsMenuViewController] slideAwayChildViewController];
}

@end
