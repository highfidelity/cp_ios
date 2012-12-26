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
#define kLabelWidth 38

#define kOnLabelText @"On"
#define kOffLabelText @"Off"

@interface CPSwitch()

@property(nonatomic, retain) UIView *clippingView;
@property(nonatomic, retain) UILabel *rightLabel;
@property(nonatomic, retain) UILabel *leftLabel;

@property(nonatomic) float initialValue;

@end

@implementation CPSwitch

@synthesize on;

-(void) awakeFromNib
{
	[super awakeFromNib];
	self.backgroundColor = [UIColor clearColor];
    
    UIImage *switchOnImage = [[UIImage imageNamed:@"switchOnBg"] resizableImageWithCapInsets:UIEdgeInsetsMake(12, 5, 12, 0)];
    UIImage *switchOffImage = [[UIImage imageNamed:@"switchOffBg"] resizableImageWithCapInsets:UIEdgeInsetsMake(12, 0, 12, 5)];
    
	[self setThumbImage:[UIImage imageNamed:@"switchThumb"] forState:UIControlStateNormal];
	[self setMinimumTrackImage:switchOnImage forState:UIControlStateNormal];
	[self setMaximumTrackImage:switchOffImage forState:UIControlStateNormal];
	
	self.minimumValue = 0.0;
	self.maximumValue = 1.0;
	self.continuous = NO;
	
	self.on = NO;
	self.value = self.minimumValue;
    
	self.clippingView = [[UIView alloc]
                         initWithFrame:CGRectMake(kControlDefaultPadding, 2, kControlWidth - kControlDefaultPadding * 2, kControlHeight - kControlDefaultPadding)];
	self.clippingView.clipsToBounds = YES;
	self.clippingView.userInteractionEnabled = NO;
	self.clippingView.backgroundColor = [UIColor clearColor];
	[self addSubview:self.clippingView];
	
	self.leftLabel = [[UILabel alloc] init];
	self.leftLabel.frame = CGRectMake(0, 0, kLabelWidth, kControlHeight - kControlDefaultPadding * 2);
	self.leftLabel.text = kOnLabelText;
	self.leftLabel.textAlignment = UITextAlignmentCenter;
	self.leftLabel.font = [UIFont boldSystemFontOfSize:kLabelFontSize];
	self.leftLabel.textColor = [UIColor whiteColor];
	self.leftLabel.backgroundColor = [UIColor clearColor];
	self.leftLabel.shadowColor = [UIColor grayColor];
	self.leftLabel.shadowOffset = CGSizeMake(0, -1);
	[self.clippingView addSubview:self.leftLabel];
	
	self.rightLabel = [[UILabel alloc] init];
	self.rightLabel.frame = CGRectMake(kControlWidth, 0, kLabelWidth, kControlHeight - kControlDefaultPadding * 2);
	self.rightLabel.text = kOffLabelText;
	self.rightLabel.textAlignment = UITextAlignmentCenter;
	self.rightLabel.font = [UIFont boldSystemFontOfSize:kLabelFontSize];
	self.rightLabel.textColor = [UIColor grayColor];
	self.rightLabel.backgroundColor = [UIColor clearColor];
	//self.rightLabel.shadowColor = [UIColor lightGrayColor];
	//self.rightLabel.shadowOffset = CGSizeMake(0, -1);
	[self.clippingView addSubview:self.rightLabel];
	
    // gesture recognizers
//    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    [self addGestureRecognizer:singleTap];
    
//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//    longPress.minimumPressDuration = 0.3;
//    [self addGestureRecognizer:longPress];
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
	
	NSInteger xPos = self.value * labelWidth - labelWidth - inset;
	self.leftLabel.frame = CGRectMake(xPos, 0, labelWidth, kControlHeight - kControlDefaultPadding);
	
	xPos = switchWidth + (self.value * labelWidth - labelWidth) - inset;
	self.rightLabel.frame = CGRectMake(xPos, 0, labelWidth, kControlHeight - kControlDefaultPadding);
}

- (void)setOn:(BOOL)turnOn animated:(BOOL)animated;
{
    on = turnOn;
    
	if (animated) {
		[UIView beginAnimations:@"CPSwitch" context:nil];
		[UIView setAnimationDuration:0.2];
	}
	
	if (on) {
		self.value = self.maximumValue;
	}
	else {
		self.value = self.minimumValue;
	}
	
	if (animated)
	{
		[UIView	commitAnimations];
	}
}

-(void)setOn:(BOOL)turnOn
{
	[self setOn:turnOn animated:NO];
}

-(BOOL) on
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
    float diff = fabsf(self.initialValue - self.value);
    if (diff < 0.02) {
        on = !on;
    } else {
        on = self.value > 0.5;
    }
    
	[super touchesEnded:touches withEvent:event];
    [self setOn:on animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
	
}

/** /
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setOn:!on animated:YES];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        BOOL newValue = self.value > 0.5;
        [self setOn:newValue animated:YES];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
/**/

@end
