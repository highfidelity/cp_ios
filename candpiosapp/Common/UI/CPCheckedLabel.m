//
//  CPCheckedLabel.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 12/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPCheckedLabel.h"

@interface CPCheckedLabel ()

@property (strong, nonatomic) NSArray *group;

@end

@implementation CPCheckedLabel

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImage *checkImg = [UIImage imageNamed:@"check-mark"];
    int topOffset = (self.frame.size.height - 15) / 2;
    if (topOffset < 0) {
        topOffset = 0;
    }
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, topOffset, 15, 15)];
    imgView.image = checkImg;
    [self addSubview:imgView];
    
    [self setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:singleTap];
    
    [self setLayout];
}

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {0, 16, 0, 0};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}


- (void)setChecked:(BOOL)checked
{
    if (_checked == checked) {
        return;
    }
    
    _checked = checked;
    [self setLayout];
    
    if (self.group && checked) {
        for (id item in self.group) {
            if ([item isKindOfClass:[CPCheckedLabel class]]) {
                if (![item isEqual:self] && ((CPCheckedLabel *)item).checked) {
                    ((CPCheckedLabel *)item).checked = NO;
                }
            }
        }
    }
}

+(void)setGroup:(NSArray *)group
{
    for (id item in group) {
        if ([item isKindOfClass:[CPCheckedLabel class]]) {
            ((CPCheckedLabel *)item).group = group;
        }
    }
}

#pragma - mark Private
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    if (!self.group || !_checked) {
        [self setChecked:!_checked];
    }
}

- (void)setLayout
{
    [[self.subviews objectAtIndex:0] setHidden:!self.checked];
    self.textColor = self.checked ? [UIColor whiteColor] : [UIColor lightGrayColor];
}

@end
