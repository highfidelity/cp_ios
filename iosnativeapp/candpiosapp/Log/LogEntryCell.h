//
//  LogEntryCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogEntryCell : UITableViewCell

@property (nonatomic, assign) IBOutlet UIImageView *typeImageView;
@property (nonatomic, assign) IBOutlet UILabel *entryLabel;
@property (nonatomic, assign) IBOutlet UILabel *timeLabel;
@property (nonatomic, assign) IBOutlet UILabel *dateLabel;

@end
