//
//  VenueUserCell.h
//  candpiosapp
//
//  Created by Andrew Hammond on 8/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUser.h"
#import "CPUserActionCell.h"

@interface VenueUserCell : CPUserActionCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (strong, nonatomic) CPUser *user;
@property (weak, nonatomic) IBOutlet UIView *visibleView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end
