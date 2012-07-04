//
//  PostUpdateCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostBaseCell.h"

@interface PostUpdateCell : PostBaseCell

@property (nonatomic, assign) IBOutlet UILabel *timeLabel;
@property (nonatomic, assign) IBOutlet UILabel *dateLabel;

@end
