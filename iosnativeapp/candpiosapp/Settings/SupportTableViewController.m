//
//  SupportTableViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SupportTableViewController.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "UserVoice.h"

#define kUserVoiceSupportSegueID @"UserVoiceSupportSegueID"

@interface SupportTableViewController ()

- (IBAction)gearPressed:(id)sender;

@end


@implementation SupportTableViewController

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UVConfig *config = [UVConfig configWithSite:kUserVoiceSite
                                         andKey:kUserVoiceKey
                                      andSecret:kUserVoiceSecret];
    if (0 == indexPath.row) {
        [UserVoice presentUserVoiceForumForParentViewController:self andConfig:config];
    }
}

#pragma mark - actions

- (IBAction)gearPressed:(id)sender {
    [self dismissPushModalViewControllerFromLeftSegue];
}

@end
