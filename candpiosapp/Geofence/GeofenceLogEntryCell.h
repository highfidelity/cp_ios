//
//  GeofenceLogEntryCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 12/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeofenceLogEntryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *entryDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end
