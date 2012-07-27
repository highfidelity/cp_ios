//
//  VenueCell.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 21.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VenueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *venuePicture;
@property (weak, nonatomic) IBOutlet UILabel *venueName;
@property (weak, nonatomic) IBOutlet UILabel *venueAddress;
@property (weak, nonatomic) IBOutlet UILabel *venueDistance;
@property (weak, nonatomic) IBOutlet UILabel *venueCheckins;

@end
