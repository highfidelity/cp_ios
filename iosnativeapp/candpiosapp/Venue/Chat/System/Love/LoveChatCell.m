//
//  LoveChatCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveChatCell.h"
#import "LoveChatEntry.h"

@implementation LoveChatCell
@synthesize recipientThumbnail = _recipientThumbnail;
@synthesize plusOneButton = _plusOneButton;
@synthesize plusOneSpinner = _plusOneSpinner;
@synthesize loveCountBubble = _loveCountBubble;
@synthesize loveCountLabel = _loveCountLabel;
@synthesize loveCount = _loveCount;

+ (CGRect)chatEntryFrame
{
    return CGRectMake(111, 6, 125, 16);
}

+ (UIFont *)chatEntryFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
}

- (void)setLoveCount:(int)loveCount
{
    _loveCount = loveCount;
    
    // if there's no love then hide the bubble
    if (_loveCount == 0) {
        self.loveCountBubble.hidden = YES;
    } else {
        // otherwise make sure it's shown and set the label inside of it
        self.loveCountBubble.hidden = NO;
        self.loveCountLabel.text = [NSString stringWithFormat:@"%d", _loveCount];
    }
    
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // thumbnail button for sender is taken care of by VenueChatCell superclass
        
        // icon for love
        UIImageView *sentLoveIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"love-sent"]];
        
        // change the frame for the love icon
        CGRect loveIconFrame = sentLoveIcon.frame;
        loveIconFrame.origin.x = self.userThumbnail.frame.origin.x + self.userThumbnail.frame.size.width + 5;
        loveIconFrame.origin.y = self.userThumbnail.frame.origin.y + ((self.userThumbnail.frame.size.height / 2) - (loveIconFrame.size.height / 2));
        sentLoveIcon.frame = loveIconFrame;
        
        // add it to the cell
        [self addSubview:sentLoveIcon];
        
        // thumbnail button for lovee
        double rcpOriginY = sentLoveIcon.frame.origin.x + sentLoveIcon.frame.size.width + 3;
        self.recipientThumbnail = [[UIButton alloc] initWithFrame:CGRectMake(rcpOriginY, 6, 30, 30)];
        
        // background is default profile image
        [self.recipientThumbnail setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
        
        // add it to the cell
        [self addSubview:self.recipientThumbnail];
        
        // change some properties on chatEntry property (inherited from superclass VenueChatCell)
        self.chatEntry.font = [[self class] chatEntryFont];
        self.chatEntry.frame = [[self class] chatEntryFrame];
        
        // setup the plus 1 button
        UIImage *plusOneImage = [UIImage imageNamed:@"love-plus-one"];
        self.plusOneButton = [[UIButton alloc] initWithFrame:CGRectMake(251, 8, plusOneImage.size.width, plusOneImage.size.height)];
        [self.plusOneButton setBackgroundImage:plusOneImage forState:UIControlStateNormal];
        
        // add the +1 button to the cell
        [self addSubview:self.plusOneButton];
        
        // red color we'll use a couple of times below
        UIColor *redColor = [UIColor colorWithRed:(170/255.0) green:(30/255.0) blue:0 alpha:1.0];
        
        // setup the spinner to add to the plus one view
        self.plusOneSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        // set some properties on the spinner
        self.plusOneSpinner.hidesWhenStopped = YES;
        self.plusOneSpinner.color = redColor;
        
        // center the spinner in the plusOne view
        CGRect spinnerCenter = self.plusOneSpinner.frame;
        spinnerCenter.origin.x = self.plusOneButton.frame.origin.x + (self.plusOneButton.frame.size.width / 2) - (spinnerCenter.size.width / 2);
        spinnerCenter.origin.y = self.plusOneButton.frame.origin.y + (self.plusOneButton.frame.size.height / 2) - (spinnerCenter.size.height / 2);
        self.plusOneSpinner.frame = spinnerCenter;
        
        // add the spinner to the plusOne view
        [self addSubview:self.plusOneSpinner];   
        
        // setup the love bubble
        UIImage *stretchyBubble = [[UIImage imageNamed:@"love-plus-one-bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 7)];
        double bubbleX = self.plusOneButton.frame.origin.x + self.plusOneButton.frame.size.width + 3;
        self.loveCountBubble = [[UIImageView alloc] initWithFrame:CGRectMake(bubbleX, self.plusOneButton.frame.origin.y, 28, 24)];
        self.loveCountBubble.image = stretchyBubble;
        
        // make sure the bubble clips subviews for our slot machine animation
        self.loveCountBubble.clipsToBounds = YES;
        
        // add the number label to the bubble
        self.loveCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 0, 23, 23)];
        
        // set some properties on the label
        self.loveCountLabel.backgroundColor = [UIColor clearColor];
        self.loveCountLabel.font = [UIFont boldSystemFontOfSize:16];
        self.loveCountLabel.textColor = redColor;
        self.loveCountLabel.textAlignment = UITextAlignmentCenter;
        
        // add the label to the bubble
        [self.loveCountBubble addSubview:self.loveCountLabel];
        
        // add the love bubble to the cell
        [self addSubview:self.loveCountBubble];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)togglePlusOneButton:(BOOL)enabled
{
    // don't let the user click the +1 button
    self.plusOneButton.userInteractionEnabled = !enabled;
    // fade the +1 to 50%
    self.plusOneButton.alpha = enabled ? 1.0 : 0.5;
}

@end
