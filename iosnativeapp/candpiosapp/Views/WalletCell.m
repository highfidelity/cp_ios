//
//  WalletCell.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 05.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "WalletCell.h"

@implementation WalletCell
@synthesize profileImage = _profileImage;
@synthesize dateLabel = _dateLabel;
@synthesize stateImage = _stateImage;
@synthesize amountLabel = _amountLabel;
@synthesize descriptionLabel = _descriptionLabel;
@synthesize nicknameLabel = _nicknameLabel;
@synthesize extraHeight = _extraHeight;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if ([self extraHeight] > 0) {
        int imgDegrees = 0;
        float descHeight = WalletCell.DESCRIPTION_HEIGHT;
        
        if (selected) {
            imgDegrees = 180;
            descHeight += [self extraHeight];
        }
        
        [CPUIHelper rotateImage:[self stateImage]
                       duration:0.1
                          curve:UIViewAnimationCurveEaseIn
                        degrees:imgDegrees];
        
        CGRect f2 = [[self descriptionLabel] frame];
        f2.size.height = descHeight;
        
        [[self descriptionLabel] setFrame:f2];
    }
    
    
}

+ (float)CELL_HEIGHT {
    return 50.0;
}

+ (float)DESCRIPTION_HEIGHT {
    return 18;
}
@end
