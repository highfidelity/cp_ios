//
//  CPSwitch.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 12/25/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSwitch.h"

#define kControlWidth 75
#define kControlHeight 24
#define kLabelFontSize 14
#define kControlDefaultPadding 4

#define kOnLabelText @"On"
#define kOffLabelText @"Off"

@interface CPSwitch()

@property(nonatomic, retain) UIView *clippingView;
@property(nonatomic, retain) UILabel *rightLabel;
@property(nonatomic, retain) UILabel *leftLabel;

@property(nonatomic) float initialValue;

@end

@implementation CPSwitch

-(void) awakeFromNib
{
	[super awakeFromNib];
	self.backgroundColor = [UIColor clearColor];
    
    UIImage *switchOnImage = [[UIImage imageNamed:@"switchOnBg"]
                              resizableImageWithCapInsets:UIEdgeInsetsMake(kControlHeight / 2, 5, kControlHeight / 2, 0)];
    UIImage *switchOffImage = [[UIImage imageNamed:@"switchOffBg"]
                               resizableImageWithCapInsets:UIEdgeInsetsMake(kControlHeight / 2, 0, kControlHeight / 2, 5)];
    
	[self setThumbImage:[UIImage imageNamed:@"switchThumb"] forState:UIControlStateNormal];
	[self setMinimumTrackImage:switchOnImage forState:UIControlStateNormal];
	[self setMaximumTrackImage:switchOffImage forState:UIControlStateNormal];
	
	self.minimumValue = 0.0;
	self.maximumValue = 1.0;
	self.continuous = NO;
	
	self.on = NO;
	self.value = self.minimumValue;
    
	self.clippingView = [[UIView alloc]
                         initWithFrame:CGRectMake(kControlDefaultPadding, 1, kControlWidth - kControlDefaultPadding * 2, kControlHeight - kControlDefaultPadding)];
	self.clippingView.clipsToBounds = YES;
	self.clippingView.userInteractionEnabled = NO;
	self.clippingView.backgroundColor = [UIColor clearColor];
	[self addSubview:self.clippingView];
	
	self.leftLabel = [[UILabel alloc] init];
	self.leftLabel.text = kOnLabelText;
	self.leftLabel.textAlignment = NSTextAlignmentCenter;
	self.leftLabel.font = [UIFont boldSystemFontOfSize:kLabelFontSize];
	self.leftLabel.textColor = [UIColor whiteColor];
	self.leftLabel.backgroundColor = [UIColor clearColor];
	self.leftLabel.shadowColor = [UIColor grayColor];
	self.leftLabel.shadowOffset = CGSizeMake(0, -1);
	[self.clippingView addSubview:self.leftLabel];
	
	self.rightLabel = [[UILabel alloc] init];
	self.rightLabel.text = kOffLabelText;
	self.rightLabel.textAlignment = NSTextAlignmentCenter;
	self.rightLabel.font = [UIFont boldSystemFontOfSize:kLabelFontSize];
	self.rightLabel.textColor = [UIColor whiteColor];
	self.rightLabel.backgroundColor = [UIColor clearColor];
	[self.clippingView addSubview:self.rightLabel];
}


-(void)layoutSubviews
{
	[super layoutSubviews];

	// move the labels to the front
	[self.clippingView removeFromSuperview];
	[self addSubview:self.clippingView];
	
	CGFloat thumbWidth = self.currentThumbImage.size.width;
	CGFloat switchWidth = self.bounds.size.width;
	CGFloat labelWidth = switchWidth - thumbWidth;
	CGFloat inset = self.clippingView.frame.origin.x;
	
	NSInteger xPos = (NSInteger) (self.value * labelWidth - labelWidth - inset + 2);
	self.leftLabel.frame = CGRectMake(xPos, 0, labelWidth, kControlHeight - kControlDefaultPadding);
	
	xPos = (NSInteger) (switchWidth + (self.value * labelWidth - labelWidth) - inset - 2);
	self.rightLabel.frame = CGRectMake(xPos, 0, labelWidth, kControlHeight - kControlDefaultPadding);
}

- (void)setOn:(BOOL)turnOn animated:(BOOL)animated;
{
	if (animated) {
		[UIView beginAnimations:@"CPSwitch" context:nil];
		[UIView setAnimationDuration:0.2];
	}
	
	if (turnOn) {
		self.value = self.maximumValue;
	}
	else {
		self.value = self.minimumValue;
	}
	
	if (animated) {
		[UIView	commitAnimations];
	}
}

-(void)setOn:(BOOL)turnOn
{
	[self setOn:turnOn animated:NO];
}

-(BOOL)on
{
    return self.value > (self.maximumValue - self.minimumValue) / 2;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[super touchesBegan:touches withEvent:event];
    self.initialValue = self.value;
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    BOOL val = self.value > 0.5;
    float diff = fabsf(self.initialValue - self.value);
    if (diff < 0.02) {
        val = !self.value > 0.5;
    }
    
	[super touchesEnded:touches withEvent:event];
    [self setOn:val animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
	
}

@end
