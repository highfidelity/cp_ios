//
//  VenueUserCell.h
//  candpiosapp
//
//  Created by Andrew Hammond on 8/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface VenueUserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet UIView *visibleView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end
