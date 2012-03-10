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
@synthesize fullHeight = _fullHeight;

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
    return;
    
#if DEBUG
    NSLog(@" %s", selected ? "true" : "false");
#endif
    
    if ([self fullHeight] > 0) {
        if (selected) {
            [CPUIHelper rotateImage:[self stateImage]
                           duration:0.1
                              curve:UIViewAnimationCurveEaseIn
                            degrees:180];
            
            CGRect f2 = self.frame;
            f2.size.height += 20;
            self.frame = f2;
        } 
        else {
            [CPUIHelper rotateImage:[self stateImage]
                           duration:0.1
                              curve:UIViewAnimationCurveEaseIn
                            degrees:0];
            
            CGRect f2 = self.frame;
            f2.size.height -= 20;
            self.frame = f2;
        }

    }
    
    
}


@end
