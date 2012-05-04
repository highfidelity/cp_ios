//
//  CheckInListCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/27/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckInListCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *venueName;
@property (nonatomic, weak) IBOutlet UILabel *venueAddress;
@property (nonatomic, weak) IBOutlet UILabel *distanceString;

@end