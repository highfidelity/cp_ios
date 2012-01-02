//
//  UserSubview.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserSubview.h"
#import "UIImageView+WebCache.h"

@interface UserSubview()
-(void)accessoryButtonTapped:(UIButton*)sender;
@end

@implementation UserSubview

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setup:(NSString*)imageUrl name:(NSString*)name buttonTapped:(void (^)(void))tapActionArg
{
	// make the image view
	const CGFloat kCalloutHeight = 88 - 8;
	const CGFloat kImageHeight = 60;
	UIImageView *leftCallout = [[UIImageView alloc]initWithFrame:CGRectMake(4, (kCalloutHeight - kImageHeight) / 2, kImageHeight, kImageHeight)];
	leftCallout.contentMode = UIViewContentModeScaleAspectFill;
	if(imageUrl)
	{
		[leftCallout setImageWithURL:[NSURL URLWithString:imageUrl]
					placeholderImage:[UIImage imageNamed:@"63-runner.png"]];
	}
	else
	{
		leftCallout.image = [UIImage imageNamed:@"63-runner.png"];			
	}
	[self addSubview:leftCallout];
	
	// add the text label
	UILabel *textLabel = [[UILabel alloc]initWithFrame:CGRectMake(kImageHeight+ 12, 0, 200, 30)];
	textLabel.text = name;
	textLabel.font = [UIFont boldSystemFontOfSize:18.0];
	textLabel.opaque = NO;
	textLabel.textColor = [UIColor whiteColor];
	textLabel.backgroundColor = [UIColor clearColor];
	[self addSubview:textLabel];
	
	// make the right callout
	UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	const CGFloat kButtonSize = 32;
	button.frame =CGRectMake(self.frame.size.width - kButtonSize, (self.frame.size.height - kButtonSize) / 2, kButtonSize, kButtonSize);
	[button addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview: button];

	tapAction = [tapActionArg copy];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


-(void)accessoryButtonTapped:(UIButton*)sender
{
	// figure out which element was tapped, and open the page
	//CandPAnnotation *tappedObj = [missions objectAtIndex:index];
	// 
	if(tapAction)
		tapAction();
}

@end
