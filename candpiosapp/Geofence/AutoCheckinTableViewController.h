//
//  AutoCheckinTableViewController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoCheckinTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *globalCheckinSwitch;
- (IBAction)globalCheckinChanged:(id)sender;

@end
