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

@property (nonatomic, weak) IBOutlet UILabel *venueName;
@property (nonatomic, weak) IBOutlet UILabel *venueAddress;
@property (nonatomic, weak) IBOutlet UISwitch *venueSwitch;
@property (nonatomic, strong) CPVenue *venue;

- (IBAction)venueSwitchChanged:(id)sender;

@end
