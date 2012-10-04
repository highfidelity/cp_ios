//
//  CheckInListCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/27/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckInListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *venueName;
@property (weak, nonatomic) IBOutlet UILabel *venueAddress;
@property (weak, nonatomic) IBOutlet UILabel *distanceString;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingSpinner;

@end