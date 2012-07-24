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

@property (nonatomic, readonly) UILabel *versionLabel;

- (IBAction)gearPressed:(id)sender;

@end


@implementation SupportTableViewController

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor colorWithRed:(68/255.0) green:(68/255.0) blue:(68/255.0) alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.tableFooterView = self.versionLabel;
}

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

#pragma mark - properties

- (UILabel *)versionLabel {
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.textAlignment = UITextAlignmentCenter;
    versionLabel.textColor = RGBA(226, 227, 220, 1);
    versionLabel.backgroundColor = RGBA(0, 0, 0, 0);
    versionLabel.opaque = NO;
    
    versionLabel.text = [NSString stringWithFormat:@"version %@",
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [versionLabel sizeToFit];
    
    return versionLabel;
}

@end
