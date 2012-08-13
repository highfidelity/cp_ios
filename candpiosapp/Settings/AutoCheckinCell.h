//
//  AutoCheckinCell.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPVenue.h"

@interface AutoCheckinCell : UITableViewCell

@property (strong, nonatomic) CPVenue *venue;
@property (weak, nonatomic) IBOutlet UILabel *venueName;
@property (weak, nonatomic) IBOutlet UILabel *venueAddress;
@property (weak, nonatomic) IBOutlet UISwitch *venueSwitch;


- (IBAction)venueSwitchChanged:(id)sender;

@end
