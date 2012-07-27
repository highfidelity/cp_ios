//
//  CPUserActionCell.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/7/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//
//  Merged from CPSwipeableTableViewCell.m
//  Created by Stephen Birarda on 5/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//
// --------------------------
// credit where credit is due
// --------------------------
// much of this code is taken from ZKRevealingTableViewCell
// found at https://github.com/alexzielenski/ZKRevealingTableViewCell

// some modfications have been made to have a swipe to the right be
// the quick action, while a left swipe reveals the view with all actions

#import "CPUserActionCell.h"
#import <objc/runtime.h>
#import "OneOnOneChatViewController.h"
#import "UserProfileViewController.h"

# define SWITCH_LEFT_MARGIN 15
# define QUICK_ACTION_MARGIN 70
# define QUICK_ACTION_LOCK 3 * (QUICK_ACTION_MARGIN + 10)
# define REDUCED_ACTION_LOCK 2 * (QUICK_ACTION_MARGIN + 10)
#define RIGHT_SWIPE_SWITCH_IMAGE_VIEW_TAG 4293
#define LEFT_SWIPE_SWITCH_IMAGE_VIEW_TAG 4294
#define FULL_PADDING 10.0

@interface CPUserActionCell()
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, readonly) CGFloat originalCenter;
@property CGFloat initialTouchPositionX;
@property CGFloat initialHorizontalCenter;
@property CPUserActionCellDirection lastDirection;
@property CPUserActionCellDirection currentDirection;

- (BOOL)shouldDragLeft;
- (BOOL)shouldDragRight;

@end

@implementation CPUserActionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // bounce by default
    self.shouldBounce = YES;
    
    // go both ways by default (haha)
    self.leftStyle = CPUserActionCellSwipeStyleNone;
    self.rightStyle = CPUserActionCellSwipeStyleQuickAction;
    
    // setup our pan gesture recognizer
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    self.panRecognizer.delegate = self;
    
    [self addGestureRecognizer:self.panRecognizer];
    
    // setup our tap gesture recognizer
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    self.tapRecognizer.delegate = self;
    self.tapRecognizer.cancelsTouchesInView = NO;
    
    [self addGestureRecognizer:self.tapRecognizer];
    
    // setup the background view
    self.hiddenView = [[UIView alloc] initWithFrame:self.contentView.frame];
    self.hiddenView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-dark"]];
    [self.hiddenView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
    // setup a CGRect that we'll manipulate to add some subviews
    CGRect changeFrame = self.hiddenView.frame;
    
    // make the UIImageView be as wide as the cell but only 15pts high
    changeFrame.size.height = 15;
    
    // setup the UIImage that is our gradient
    UIImage *embossedGradient = [[UIImage imageNamed:@"cell-shadow-harsh"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    // alloc-init a UIImageView for the top gradient
    UIImageView *topGradient = [[UIImageView alloc] initWithFrame:changeFrame];
    [topGradient setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];

    // give it the gradient image
    topGradient.image = embossedGradient;
    
    // change the frame of the bottom gradient so it's 15 pts high
    changeFrame.origin.y = self.hiddenView.frame.size.height - 15;
    
    // alloc-init a UIImageView for the bottom gradient
    UIImageView *bottomGradient = [[UIImageView alloc] initWithFrame:changeFrame];
    [bottomGradient setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    
    // give it the gradient image
    bottomGradient.image = embossedGradient;
    
    // rotate the bottom one so it's the other way
    bottomGradient.layer.transform = CATransform3DMakeRotation(M_PI, 1.0f, 0.0f, 0.0f);
    
    bottomGradient.frame = changeFrame;
    
    // add the top gradients to the hidden view
    [self.hiddenView addSubview:topGradient];
    [self.hiddenView addSubview:bottomGradient];
    
    // add a line to the buttom of the view to maintain separation when revealing hidden view
    
    changeFrame.size.height = 1;
    changeFrame.origin.y = self.hiddenView.frame.size.height - 1;
    
    // alloc-init the bottom line and match the color with the line color from the user list table
    UIView *bottomLine = [[UIView alloc] initWithFrame:changeFrame];
    bottomLine.backgroundColor = [UIColor colorWithR:68 G:68 B:68 A:1];
    
    // add the bottom line to the hidden view
    [self.hiddenView addSubview:bottomLine];
    
    // make sure the hiddenView clips its subviews to its bounds
    self.hiddenView.clipsToBounds = YES;
    
    // init the toggles to inactive
    self.toggleState = CPUserActionCellSwitchStateOff;
    
    // default colors
    self.activeColor = [CPUIHelper CPTealColor];
    self.inactiveColor = [UIColor colorWithR:51 G:51 B:51 A:1];
        
    // Additional buttons for contact exchange and chat
    CGFloat originX = SWITCH_LEFT_MARGIN;
    self.sendLoveButton = [self addToggleWithPrefix:@"send-love" originX:originX selector:@selector(sendLoveAction)];
    originX += self.sendLoveButton.frame.size.width + SWITCH_LEFT_MARGIN;
    self.sendMessageButton = [self addToggleWithPrefix:@"send-message" originX:originX selector:@selector(sendMessageAction)];
    originX += self.sendMessageButton.frame.size.width + SWITCH_LEFT_MARGIN;
    self.exchangeContactsButton = [self addToggleWithPrefix:@"exchange-contacts" originX:originX selector:@selector(exchangeContactsAction)];

    // add subviews
	[self addSubview:self.hiddenView];
	[self addSubview:self.contentView];    
}

static char BOOLRevealing;

- (BOOL)isRevealing
{
	return [(NSNumber *)objc_getAssociatedObject(self, &BOOLRevealing) boolValue];
}

- (void)setRevealing:(BOOL)revealing
{
	// Don't change the value if its already that value.
	// Reveal unless the delegate says no
	if (revealing == self.revealing || revealing)
		return;
	
	[self _setRevealing:revealing];
    	
	if (self.isRevealing)
		[self performActionInDirection:(self.isRevealing) ? self.currentDirection : self.lastDirection];
	else
		[self slideInContentViewFromDirection:(self.isRevealing) ? self.currentDirection : self.lastDirection offsetMultiplier:self.bounceMultiplier slideDelay:0];
}

- (void)_setRevealing:(BOOL)revealing
{
    [self willChangeValueForKey:@"isRevealing"];
	objc_setAssociatedObject(self, &BOOLRevealing, [NSNumber numberWithBool:revealing], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:@"isRevealing"];
}

#pragma mark - Handing Touch
- (void)tap:(UITapGestureRecognizer *)recognizer 
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.isRevealing) {
            // noop
        } else {
            // mimic row selection - highlight and push the child view
            UITableView *tableView = (UITableView*)self.superview;
            NSIndexPath *indexPath = [tableView indexPathForCell: self];
            [self setHighlighted:YES animated:YES];
            // for some reason selectRowAtIndexPath:indexPath was not invoking the delegate :( Notifications not sent by this.
            if ([tableView.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) { 
                indexPath = [[tableView delegate] tableView:tableView willSelectRowAtIndexPath:indexPath];
            }
            if (indexPath) {
                if ([tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                    [[tableView delegate] tableView:tableView didSelectRowAtIndexPath:indexPath];
                }
            }
            if ([self.delegate respondsToSelector:@selector(cell:didSelectRowWithUser:)]) {
                [self.delegate cell:self didSelectRowWithUser:self.user];
            }
        }
    }
}

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation           = [recognizer translationInView:self];
	CGPoint currentTouchPoint     = [recognizer locationInView:self];
	CGPoint velocity              = [recognizer velocityInView:self];
	
    CGFloat originalCenter        = self.originalCenter;
    CGFloat currentTouchPositionX = currentTouchPoint.x;
    CGFloat panAmount             = self.initialTouchPositionX - currentTouchPositionX;
    CGFloat newCenterPosition     = self.initialHorizontalCenter - panAmount;
    CGFloat centerX               = self.contentView.center.x;
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		
		// Set a baseline for the panning
		self.initialTouchPositionX = currentTouchPositionX;
		self.initialHorizontalCenter = self.contentView.center.x;
		
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		
		// If the pan amount is negative, then the last direction is left, and vice versa.
		if (newCenterPosition - centerX < 0)
			self.lastDirection = CPUserActionCellDirectionLeft;
		else
			self.lastDirection = CPUserActionCellDirectionRight;
        
		// Don't let you drag past a certain point depending on direction
		if ((newCenterPosition < originalCenter && ![self shouldDragLeft]) || (newCenterPosition > originalCenter && ![self shouldDragRight])) {
            newCenterPosition = originalCenter;
        }
        
        
        // if our style is full slide then don't go past the defined margin
        CGFloat fullLock = self.bounds.size.width - FULL_PADDING;
        if (newCenterPosition > originalCenter + fullLock && self.rightStyle == CPUserActionCellSwipeStyleFull) {
            newCenterPosition = originalCenter + fullLock;
        } else if (newCenterPosition < originalCenter - fullLock && self.leftStyle == CPUserActionCellSwipeStyleFull) {
            newCenterPosition = originalCenter - fullLock;
        }
        
        // if our style is quick action then don't go past the defined margin
        if (newCenterPosition > originalCenter + QUICK_ACTION_LOCK && self.rightStyle == CPUserActionCellSwipeStyleQuickAction) {
            newCenterPosition = originalCenter + QUICK_ACTION_LOCK;
        } else if (newCenterPosition < originalCenter - QUICK_ACTION_LOCK && self.leftStyle == CPUserActionCellSwipeStyleQuickAction) {
            newCenterPosition = originalCenter - QUICK_ACTION_LOCK;
        }

        // if our style is quick action then don't go past the defined margin
        if (newCenterPosition > originalCenter + REDUCED_ACTION_LOCK && self.rightStyle == CPUserActionCellSwipeStyleReducedAction) {
            newCenterPosition = originalCenter + REDUCED_ACTION_LOCK;
        } else if (newCenterPosition < originalCenter - REDUCED_ACTION_LOCK && self.leftStyle == CPUserActionCellSwipeStyleReducedAction) {
            newCenterPosition = originalCenter - REDUCED_ACTION_LOCK;
        }

		// Let's not go waaay out of bounds
		if (newCenterPosition > self.bounds.size.width + originalCenter)
			newCenterPosition = self.bounds.size.width + originalCenter;
		
		else if (newCenterPosition < -originalCenter)
			newCenterPosition = -originalCenter;
        
        // check if we need to switch the quick action image
        [self checkForQuickActionSwitchToggleForNewCenter:newCenterPosition];
		
		CGPoint center = self.contentView.center;
		center.x = newCenterPosition;
        
		self.contentView.layer.position = center;
		
	} else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        // call the action for the active button
        UIButton *activeButton = [self buttonForState:self.toggleState];
        [activeButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        
		// Swiping left, velocity is below 0.
		// Swiping right, it is above 0
		// If the velocity is above the width in points per second at any point in the pan, push it to the acceptable side
		// Otherwise, if we are 60 points in, push to the other side
		// If we are < 60 points in, bounce back
		
#define kMinimumVelocity self.contentView.frame.size.width
#define kMinimumPan      60.0
		
		CGFloat velocityX = velocity.x;
        BOOL push = NO;
        
        // the minimum pan is defined above but is different if it's a quick action
        CGFloat minPan = [self styleForDirectionIsQuickAction:self.lastDirection] ? QUICK_ACTION_MARGIN : kMinimumPan;
        
		push |= ((self.lastDirection == CPUserActionCellDirectionLeft && translation.x < -minPan) || (self.lastDirection == CPUserActionCellDirectionRight && translation.x > minPan));
        
        // only consider the velocity if this isn't for a quick action
        if (![self styleForDirectionIsQuickAction:self.lastDirection]) {
            push |= (velocityX < -kMinimumVelocity);
            push |= (velocityX > kMinimumVelocity);
            
            if (velocityX > 0 && self.lastDirection == CPUserActionCellDirectionLeft)
                push = NO;
            
            else if (velocityX < 0 && self.lastDirection == CPUserActionCellDirectionRight)
                push = NO;
        }
        
		push &= ((self.lastDirection == CPUserActionCellDirectionRight && self.shouldDragRight) || (self.lastDirection == CPUserActionCellDirectionLeft && self.shouldDragLeft));
        
		if (push && !self.isRevealing) {
			[self _setRevealing:YES];
			[self performActionInDirection:self.lastDirection];
            
			self.currentDirection = self.lastDirection;
			
		} else if (self.isRevealing && translation.x != 0) {
			CGFloat multiplier = self.bounceMultiplier;
			if (!self.isRevealing)
				multiplier *= -1.0;
            
			[self slideInContentViewFromDirection:self.currentDirection offsetMultiplier:multiplier slideDelay:0];
			[self _setRevealing:NO];
			
		} else if (translation.x != 0) {
			// Figure out which side we've dragged on.
			CPUserActionCellDirection finalDir = CPUserActionCellDirectionRight;
			if (translation.x < 0)
				finalDir = CPUserActionCellDirectionLeft;
            
			[self slideInContentViewFromDirection:finalDir offsetMultiplier:-1.0 * self.bounceMultiplier slideDelay:0];
			[self _setRevealing:NO];
		}
	}
}


- (BOOL)shouldDragLeft
{
	return (self.leftStyle == CPUserActionCellSwipeStyleFull || 
            self.leftStyle == CPUserActionCellSwipeStyleQuickAction ||
            self.leftStyle == CPUserActionCellSwipeStyleReducedAction);
}

- (BOOL)shouldDragRight
{
    return (self.rightStyle == CPUserActionCellSwipeStyleFull || 
            self.rightStyle == CPUserActionCellSwipeStyleQuickAction ||
            self.rightStyle == CPUserActionCellSwipeStyleReducedAction);
}

- (BOOL)styleForDirectionIsQuickAction:(CPUserActionCellDirection)direction 
{
    return ((direction == CPUserActionCellDirectionLeft && (self.leftStyle == CPUserActionCellSwipeStyleQuickAction || self.leftStyle == CPUserActionCellSwipeStyleReducedAction)) ||
            (direction == CPUserActionCellDirectionRight && (self.rightStyle == CPUserActionCellSwipeStyleQuickAction || self.rightStyle == CPUserActionCellSwipeStyleReducedAction)));
}

- (CGFloat)originalCenter
{
    return ceil(self.bounds.size.width / 2);
}

- (CGFloat)bounceMultiplier
{
	return self.shouldBounce ? MIN(ABS(self.originalCenter - self.contentView.center.x) / kMinimumPan, 1.0) : 0.0;
}

#pragma mark - Sliding
#define kBOUNCE_DISTANCE 20.0

- (void)slideInContentViewFromDirection:(CPUserActionCellDirection)direction offsetMultiplier:(CGFloat)multiplier slideDelay:(CGFloat)slideDelay
{    
    CGFloat bounceDistance;
    
    if ([self styleForDirectionIsQuickAction:direction]) {
        // this was from a quick action and we're forcing a hide
        // so make sure we set revealing to NO
        [self _setRevealing:NO];
    }
	
	if (self.contentView.center.x == self.originalCenter)
		return;
	
	switch (direction) {
		case CPUserActionCellDirectionRight:
			bounceDistance = kBOUNCE_DISTANCE * multiplier;
			break;
		case CPUserActionCellDirectionLeft:
			bounceDistance = -kBOUNCE_DISTANCE * multiplier;
			break;
		default:
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unhandled gesture direction" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:direction] forKey:@"direction"]];
			break;
	}
	
	[UIView animateWithDuration:0.1
						  delay:slideDelay
						options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction 
					 animations:^{ self.contentView.center = CGPointMake(self.originalCenter, self.contentView.center.y); } 
					 completion:^(BOOL f) {
                         
						 [UIView animateWithDuration:0.1 delay:0 
											 options:UIViewAnimationCurveLinear
										  animations:^{ self.contentView.frame = CGRectOffset(self.contentView.frame, bounceDistance, 0); } 
										  completion:^(BOOL f) {                     
											  
                                              [UIView animateWithDuration:0.1 delay:0 
                                                                  options:UIViewAnimationCurveLinear
                                                               animations:^{ self.contentView.frame = CGRectOffset(self.contentView.frame, -bounceDistance, 0); } 
                                                               completion:NULL];
										  }
						  ]; 
					 }];
}

- (void)slideOutContentViewToNewCenterX:(CGFloat)centerX;
{
    [UIView animateWithDuration:0.2 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseOut 
					 animations:^{ self.contentView.center = CGPointMake(centerX, self.contentView.center.y); } 
					 completion:NULL];
}

- (void)performActionInDirection:(CPUserActionCellDirection)direction;
{
    if ([self styleForDirectionIsQuickAction:direction]) {
        // make sure the delegate will handle the call
        // and then tell it to perform the quick action
        
        // flick the switch back
        // use the CPUserActionCellDirection to decide which index to pass to pull the right UIImageView
        [self changeStateOfQuickActionSwitchForDirection:direction active:0];
        
        // slide the content view back in
        // by setting revealing to NO using the delegate's method
        [self slideInContentViewFromDirection:direction offsetMultiplier:[self bounceMultiplier] slideDelay:0.15];
    } else {
        // calculate the new center depending on the direction of the swipe
        CGFloat x = direction == CPUserActionCellDirectionLeft ? -self.originalCenter +  FULL_PADDING: self.contentView.frame.size.width + self.originalCenter - FULL_PADDING; 
        [self slideOutContentViewToNewCenterX:x];
    }
}

#pragma mark - Methods for quick action

- (void)checkForQuickActionSwitchToggleForNewCenter:(CGFloat)centerX {  
    // currently the app only uses quick action on right swipe
    // code will need to be refactored if we need to add that functionality on the right side
    if (self.rightStyle == CPUserActionCellSwipeStyleQuickAction || self.rightStyle == CPUserActionCellSwipeStyleReducedAction) {
        // get the position of the left edge of the cell
        CGFloat leftEdge = centerX - (self.contentView.frame.size.width / 2);
        
        // use updateImageIndex to see if we need to update the imageView's image
        int newState = 0;
        
        CGFloat sendLoveButtonMiddle = SWITCH_LEFT_MARGIN + self.sendLoveButton.frame.size.width / 2;
        CGFloat sendMessageButtonStart = 2*SWITCH_LEFT_MARGIN + self.sendLoveButton.frame.size.width;
        CGFloat sendMessageButtonMiddle = sendMessageButtonStart + self.sendMessageButton.frame.size.width / 2;
        CGFloat exchangeContactsButtonStart = 3*SWITCH_LEFT_MARGIN + self.sendLoveButton.frame.size.width + self.sendMessageButton.frame.size.width;
        CGFloat exchangeContactsButtonMiddle = exchangeContactsButtonStart + self.exchangeContactsButton.frame.size.width / 2;
        // check if we need to toggle the switch
        if (leftEdge >= sendLoveButtonMiddle &&
            leftEdge <= sendMessageButtonStart) {
            newState = 1;
        } else if (leftEdge >= sendMessageButtonMiddle && 
                   leftEdge <= exchangeContactsButtonStart) {
            newState = 2;
        } else if (leftEdge >= exchangeContactsButtonMiddle) { 
            newState = 3;
        } 
        
        // on state change, update the button and play the sound effect
        [self changeStateOfQuickActionSwitchForDirection:CPUserActionCellDirectionRight active:newState];
    }
}

-(UIButton*) addToggleWithPrefix:(NSString*)prefix originX:(CGFloat)originX selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *onImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-on", prefix]];
    UIImage *offImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-off", prefix]];
    
    [button setImage:offImage forState:UIControlStateNormal];
    [button setImage:onImage forState:UIControlStateHighlighted];
    [button setImage:onImage forState:UIControlStateSelected];
    
    UIImageView *quickActionImageView = [[UIImageView alloc] initWithImage:offImage];
    // move the secretImageView to the right spot
    CGRect switchFrame = quickActionImageView.frame;
    switchFrame.origin.x = originX;
    switchFrame.origin.y = (self.contentView.frame.size.height / 2) - (switchFrame.size.height / 2);
    button.frame = switchFrame;
    [button addTarget:self 
               action:@selector(switchSound:) 
     forControlEvents:UIControlEventTouchDown | UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    [button addTarget:self 
               action:selector 
     forControlEvents:UIControlEventTouchUpInside];
    [button setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin ];
    [self.hiddenView addSubview:button];
    return button;
}

- (UIButton*) buttonForState:(CPUserActionCellSwitchState)state {
    if (state == CPUserActionCellSwitchStateSendLoveOn) { 
        return self.sendLoveButton; 
    } else if (state == CPUserActionCellSwitchStateSendMessageOn) { 
        return self.sendMessageButton; 
    } else if (state == CPUserActionCellSwitchStateExchangeContactsOn) { 
        return self.exchangeContactsButton; 
    } else { 
        return nil; 
    }
}

- (void)changeStateOfQuickActionSwitchForDirection:(CPUserActionCellDirection)direction active:(CPUserActionCellSwitchState)active
{
    // toggle the switch as appropriate while sliding
    if (active == self.toggleState) { return; } // already in the right state
    UIButton *oldButton = [self buttonForState:self.toggleState];
    if (oldButton) { 
        // deactivate the old toggle
        oldButton.highlighted = NO;
        [oldButton sendActionsForControlEvents:UIControlEventTouchUpOutside];
    }
    UIButton *newButton = [self buttonForState:active];
    if (newButton) {
        // activate the new toggle
        newButton.highlighted = YES;
        [newButton sendActionsForControlEvents:UIControlEventTouchDown];
    }
    self.toggleState = active;
}

- (void)toggleCellActiveState:(BOOL)active
{
    if (active) {
        self.contentView.backgroundColor = self.activeColor;
    } else {
        self.contentView.backgroundColor = self.inactiveColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self toggleCellActiveState:highlighted];
}

- (void) switchSound:(id)sender {    
    UIButton *button = (UIButton*)sender;
    NSString *prefix = @"";
    if (button == self.sendLoveButton) {
        prefix = @"send-love";
    } else if (button == self.sendMessageButton) {
        prefix = @"send-message";
    } else if (button == self.exchangeContactsButton) {
        prefix = @"exchange-contacts";
    }
   
    if (button.isHighlighted) { 
        [CPSoundEffectsManager playSoundWithSystemSoundID:
         [CPSoundEffectsManager systemSoundIDForSoundWithName:[prefix stringByAppendingString:@"-on"] type:@"aif"]];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // make sure this is the pan gesture
    if (gestureRecognizer == self.panRecognizer) {
        
        // how far as the cell moved with relation to the table view?
		UIScrollView *superview = (UIScrollView *)self.superview;
		CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:superview];
		
		// make sure it's scrolling horizontally
		return ((fabs(translation.x) / fabs(translation.y) > 1) ? YES : NO && (superview.contentOffset.y == 0.0 && superview.contentOffset.x == 0.0));
	} else if ([gestureRecognizer class] == [UITapGestureRecognizer class]) {
        // allow any tap handling to occur via the tap gesture recognizer
        return YES;
    }
	return NO;
}

#pragma mark - CPUserActionCellDelegate Invocations

- (void) sendLoveAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectSendLoveToUser:)]) {
        [self.delegate cell:self didSelectSendLoveToUser:self.user];
    }
}

- (void)sendMessageAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectSendMessageToUser:)]) {
        [self.delegate cell:self didSelectSendMessageToUser:self.user];
    }
}

- (void)exchangeContactsAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectExchangeContactsWithUser:)]) {
        [self.delegate cell:self didSelectExchangeContactsWithUser:self.user];
    }
}

- (void)selectRowAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectRowWithUser:)]) {
        [self.delegate cell:self didSelectRowWithUser:self.user];
    }
}

@end
