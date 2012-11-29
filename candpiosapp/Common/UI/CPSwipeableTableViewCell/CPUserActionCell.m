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

#define SWITCH_LEFT_MARGIN 10
#define SWITCH_PADDING 20
#define QUICK_ACTION_MARGIN 56
#define QUICK_ACTION_LOCK 3 * (QUICK_ACTION_MARGIN + 10)
#define REDUCED_ACTION_LOCK 2 * (QUICK_ACTION_MARGIN + 10)
#define RIGHT_SWIPE_SWITCH_IMAGE_VIEW_TAG 4293
#define LEFT_SWIPE_SWITCH_IMAGE_VIEW_TAG 4294
#define FULL_PADDING 10.0

#define kMinimumPan      60.0
#define kBOUNCE_DISTANCE 20.0
#define HIGHLIGHT_DURATION 0.1

@interface CPUserActionCell()

@property (strong, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) CGFloat initialTouchPositionX;
@property (nonatomic) CGFloat initialHorizontalCenter;
@property (nonatomic) CPUserActionCellDirection lastDirection;
@property (nonatomic) CPUserActionCellDirection currentDirection;
@property (nonatomic, readonly) CGFloat panFullOpenWidth;
@property (nonatomic, readonly) CGAffineTransform buttonBumpStartingTransform;
@property (nonatomic, readonly) BOOL areActionButtonsVisible;

- (BOOL)shouldDragLeft;
- (BOOL)shouldDragRight;

@end

@implementation CPUserActionCell

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *)viewToHighlight {
    return self.contentView;
}

- (void)setInactiveColor:(UIColor *)inactiveColor {
    _inactiveColor = inactiveColor;
    self.viewToHighlight.backgroundColor = inactiveColor;
}

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
    self.hiddenView = [[UIButton alloc] initWithFrame:self.contentView.frame];
    self.hiddenView.backgroundColor = [UIColor blackColor];
    [self.hiddenView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
    // setup a CGRect that we'll manipulate to add some subviews
    CGRect changeFrame = self.hiddenView.frame;
    
    // add a line to the buttom of the view to maintain separation when revealing hidden view
    changeFrame.size.height = 1;
    changeFrame.origin.y = self.hiddenView.frame.size.height - 1;
    
    // alloc-init the bottom line and match the color with the line color from the user list table
    UIView *bottomLine = [[UIView alloc] initWithFrame:changeFrame];
    bottomLine.backgroundColor = [UIColor colorWithR:68 G:68 B:68 A:1];
    bottomLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    // add the bottom line to the hidden view
    [self.hiddenView addSubview:bottomLine];
    
    // make sure the hiddenView clips its subviews to its bounds
    self.hiddenView.clipsToBounds = YES;
    
    // default colors
    self.activeColor = [CPUIHelper CPTealColor];
    self.inactiveColor = [UIColor colorWithR:51 G:51 B:51 A:1];
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
    self.selectedBackgroundView.backgroundColor = self.activeColor;

    // Additional buttons for contact exchange and chat
    CGFloat originX = SWITCH_LEFT_MARGIN;
    self.sendLoveButton = [self addActionButtonWithImageNamed:@"quick-action-endorse"
                                                      originX:originX
                                                     selector:@selector(sendLoveAction)];
    
    originX += self.sendLoveButton.frame.size.width + SWITCH_LEFT_MARGIN;
    self.sendMessageButton = [self addActionButtonWithImageNamed:@"quick-action-chat"
                                                         originX:originX
                                                        selector:@selector(sendMessageAction)];
    
    originX += self.sendMessageButton.frame.size.width + SWITCH_LEFT_MARGIN;
    self.exchangeContactsButton = [self addActionButtonWithImageNamed:@"quick-action-exchange-cards"
                                                              originX:originX
                                                             selector:@selector(exchangeContactsAction)];

    // add subviews
    [self addSubview:self.hiddenView];
    [self addSubview:self.contentView];
    
    [self registerForNotification];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (self.areActionButtonsVisible) {
        if (hitView == self) {
            return nil;
        }
    }
    return hitView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    NSArray *actionButtons = [NSArray arrayWithObjects:
                              self.sendLoveButton,
                              self.sendMessageButton,
                              self.exchangeContactsButton,
                              nil];
    for (UIButton *button in actionButtons) {
        button.hidden = YES;
        button.alpha = 0;
        button.transform = CGAffineTransformIdentity;
    }
}

- (void)highlight:(BOOL)highlight {
    // mimic row selection - highlight and push the child view
    [UIView animateWithDuration:HIGHLIGHT_DURATION animations:^{
        if (highlight) {
            self.viewToHighlight.backgroundColor = self.activeColor;

            if ([self.superview isKindOfClass:[UITableView class]]) {
                UITableView *tableView = (UITableView *)self.superview;
                for (CPUserActionCell *cell in tableView.visibleCells) {
                    if (cell != self) {
                        if ([cell respondsToSelector:@selector(highlight:)]) {
                            [cell highlight:NO];
                        } else {
                            [cell setSelected:NO animated:YES];
                        }
                    }
                }
            }
        } else {
            self.viewToHighlight.backgroundColor = self.inactiveColor;
        }

        [self additionalHighlightAnimations:highlight];
    }];
}

- (void)additionalHighlightAnimations:(BOOL)highlight
{
    // to be overridden in subclasses
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)evt {
    if (!self.areActionButtonsVisible) {
        [self highlight:YES];
    }
}

#pragma mark - Handing Touch
- (void)tap:(UITapGestureRecognizer *)recognizer
{
    // handle taps
    if (!self.areActionButtonsVisible) {
        // mimic row selection - highlight and push the child view
        [self highlight:YES];
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            // return immediately.. next view must be initialized on main thread
            [self performSelectorOnMainThread:@selector(handleTap) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)handleTap {
    UITableView *tableView = (UITableView*)self.superview;

    if (![tableView isKindOfClass:[UITableView class]]) {
        return;
    }

    NSIndexPath *indexPath = [tableView indexPathForCell: self];
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

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
	CGPoint currentTouchPoint     = [recognizer locationInView:self];
	CGPoint velocity              = [recognizer velocityInView:self];
	
    CGFloat originalCenter        = self.originalCenter;
    CGFloat currentTouchPositionX = currentTouchPoint.x;
    CGFloat panAmount             = self.initialTouchPositionX - currentTouchPositionX;
    CGFloat newCenterPosition     = self.initialHorizontalCenter - panAmount;
    CGFloat centerX               = self.contentView.center.x;
	
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // Set a baseline for the panning
            self.initialTouchPositionX = currentTouchPositionX;
            self.initialHorizontalCenter = self.contentView.center.x;
            
            [[self class] cancelOpenSlideActionButtonsNotification:self];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            // If the pan amount is negative, then the last direction is left, and vice versa.
            if (newCenterPosition - centerX < 0) {
                self.lastDirection = CPUserActionCellDirectionLeft;
            } else {
                self.lastDirection = CPUserActionCellDirectionRight;
            }
            
            // Don't let you drag past a certain point depending on direction
            if ((newCenterPosition < originalCenter && ![self shouldDragLeft]) ||
                (newCenterPosition > originalCenter && ![self shouldDragRight])) {
                newCenterPosition = originalCenter;
            }
            
            switch (self.rightStyle) {
                case CPUserActionCellSwipeStyleQuickAction:
                    newCenterPosition = MIN(originalCenter + QUICK_ACTION_LOCK, newCenterPosition);
                    break;
                case CPUserActionCellSwipeStyleReducedAction:
                    newCenterPosition = MIN(originalCenter + REDUCED_ACTION_LOCK, newCenterPosition);
                    break;
                default:
                    break;
            }
            
            switch (self.leftStyle) {
                case CPUserActionCellSwipeStyleQuickAction:
                    newCenterPosition = MAX(originalCenter - QUICK_ACTION_LOCK, newCenterPosition);
                    break;
                case CPUserActionCellSwipeStyleReducedAction:
                    newCenterPosition = MAX(originalCenter - REDUCED_ACTION_LOCK, newCenterPosition);
                    break;
                default:
                    break;
            }
            
            // Let's not go waaay out of bounds
            if (newCenterPosition > self.bounds.size.width + originalCenter) {
                newCenterPosition = self.bounds.size.width + originalCenter;
            } else if (newCenterPosition < -originalCenter) {
                newCenterPosition = -originalCenter;
            }
            
            [self animateSlideButtonsWithNewCenter:newCenterPosition
                                             delay:0
                                          duration:0
                                          animated:YES];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            
            NSTimeInterval fullOpenAnimationDuration = 0.2;
            CGFloat openAmount = newCenterPosition - self.originalCenter;
            CGFloat thresholdAmount = self.panFullOpenWidth / 2;
            CGFloat velocityDuration = fullOpenAnimationDuration / 2.;
            CGFloat velocityShift = velocity.x * velocityDuration;
            
            CGFloat openAmountWithVelocity = openAmount + velocityShift;
            if (openAmountWithVelocity >= thresholdAmount) {
                newCenterPosition = originalCenter + self.panFullOpenWidth;
                
                if (openAmountWithVelocity > self.panFullOpenWidth) {
                    fullOpenAnimationDuration /= 2 * velocityShift / (self.panFullOpenWidth - openAmount);
                }
            } else {
                newCenterPosition = originalCenter;
                
                if (openAmountWithVelocity < 0) {
                    fullOpenAnimationDuration /= 2 * velocityShift / -panAmount;
                }
            }
            
            [self animateSlideButtonsWithNewCenter:newCenterPosition
                                             delay:0
                                          duration:fullOpenAnimationDuration
                                          animated:YES];
            break;
        }
        default:
            break;
	}
}

- (void)animateSlideButtonsWithNewCenter:(CGFloat)newCenter delay:(NSTimeInterval)delay duration:(NSTimeInterval)duration animated:(BOOL)animated {
    [self animateButtonsBumpForNewCenter:newCenter withDelay:delay duration:duration animated:animated];
    
    CGPoint center = self.contentView.center;
    center.x = newCenter;
    
    void (^animations)(void) = ^{
        self.contentView.layer.position = center;
    };
    
    if (0 == duration) {
        animations();
    } else {
        [UIView animateWithDuration:duration
                              delay:delay
                            options:kNilOptions
                         animations:animations
                         completion:nil];
    }
}

- (CGFloat)panFullOpenWidth {
    switch (self.rightStyle) {
        case CPUserActionCellSwipeStyleQuickAction:
            return QUICK_ACTION_LOCK;
        case CPUserActionCellSwipeStyleReducedAction:
            return REDUCED_ACTION_LOCK;
        default:
            return 0;
    }
}

- (BOOL)areActionButtonsVisible {
    return self.contentView.center.x != self.originalCenter;
}

- (CGAffineTransform)buttonBumpStartingTransform {
    return CGAffineTransformMakeScale(0.01, 0.01);
}

- (BOOL)shouldDragLeft
{
    return self.leftStyle != CPUserActionCellSwipeStyleNone;
}

- (BOOL)shouldDragRight
{
    return self.rightStyle != CPUserActionCellSwipeStyleNone;
}

- (CGFloat)originalCenter
{
    return ceil(self.bounds.size.width / 2);
}

- (CGFloat)bounceMultiplier
{
	return self.shouldBounce ? MIN(ABS(self.originalCenter - self.contentView.center.x) / kMinimumPan, 1.0) : 0.0;
}

#pragma mark - Methods for quick action

- (void)animateButtonsBumpForNewCenter:(CGFloat)newCenterX withDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration animated:(BOOL)animated {
    CGFloat oldLeftX = self.contentView.center.x - self.originalCenter;
    CGFloat newLeftX = newCenterX - self.originalCenter;
    
    NSArray *actionButtons = [NSArray arrayWithObjects:
                              self.sendLoveButton,
                              self.sendMessageButton,
                              self.exchangeContactsButton,
                              nil];
    
    for (UIButton *button in actionButtons) {
        CGFloat buttonX = button.center.x + 20;
        NSTimeInterval buttonDelay = delay + duration * abs(buttonX - oldLeftX) / abs(newLeftX - oldLeftX);
        
        if (oldLeftX < buttonX && newLeftX >= buttonX) {
            [self bumpButtonIn:button withDelay:buttonDelay animated:animated];
        } else if (oldLeftX >= buttonX && newLeftX < buttonX) {
            [self bumpButtonOut:button withDelay:buttonDelay animated:animated];
        }
    }
}

- (void)bumpButtonIn:(UIButton *)button withDelay:(NSTimeInterval)delay animated:(BOOL)animated {
    if (button.hidden) {
        button.alpha = 0;
        button.transform = self.buttonBumpStartingTransform;
        button.hidden = NO;
    }
    
    void (^animations)(void) = ^{
        button.alpha = 1;
        button.transform = CGAffineTransformIdentity;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:delay
                            options:kNilOptions
                         animations:animations
                         completion:nil];
    } else {
        animations();
    }
}

- (void)bumpButtonOut:(UIButton *)button withDelay:(NSTimeInterval)delay animated:(BOOL)animated {
    void (^animations)(void) = ^{
        button.transform = self.buttonBumpStartingTransform;
        button.alpha = 0;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:delay
                            options:kNilOptions
                         animations:animations
                         completion:nil];
    } else {
        animations();
    }
}

-(UIButton*)addActionButtonWithImageNamed:(NSString*)imageName originX:(CGFloat)originX selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *image = [UIImage imageNamed:imageName];
    [button setImage:image forState:UIControlStateNormal];
    
    UIImageView *quickActionImageView = [[UIImageView alloc] initWithImage:image];
    // move the secretImageView to the right spot
    CGRect switchFrame = quickActionImageView.frame;
    switchFrame.size.height += SWITCH_PADDING;
    switchFrame.size.width += SWITCH_PADDING;
    switchFrame.origin.x = originX;
    switchFrame.origin.y = (self.contentView.frame.size.height / 2) - (switchFrame.size.height / 2);
    button.frame = switchFrame;
    
    [button addTarget:self 
               action:@selector(switchSound:) 
     forControlEvents:UIControlEventTouchUpInside];
    
    [button addTarget:self 
               action:selector 
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin ];
    
    button.hidden = YES;
    [self.hiddenView addSubview:button];
    
    return button;
}

- (void)switchSound:(id)sender {
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

#define UNHIGHLIGHT_DELAY 0.75

- (void)highlightButton:(UIButton *)button completion:(void (^)())completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        button.highlighted = YES;
        if (completion) {
            completion();
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, UNHIGHLIGHT_DELAY * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            button.highlighted = NO;
        });
    });
}

- (void)sendLoveAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectSendLoveToUser:)]) {
        [self highlightButton:self.sendLoveButton completion:^{
            [self.delegate cell:self didSelectSendLoveToUser:self.user];
        }];
    }
}

- (void)sendMessageAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectSendMessageToUser:)]) {
        [self highlightButton:self.sendMessageButton completion:^{
            [self.delegate cell:self didSelectSendMessageToUser:self.user];
        }];
    }
}

- (void)exchangeContactsAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectExchangeContactsWithUser:)]) {
        [self highlightButton:self.exchangeContactsButton completion:^{
            [self.delegate cell:self didSelectExchangeContactsWithUser:self.user];
        }];
    }
}

- (void)selectRowAction {
    if ([self.delegate respondsToSelector:@selector(cell:didSelectRowWithUser:)]) {
        [self.delegate cell:self didSelectRowWithUser:self.user];
    }
}

#pragma mark - notifications

- (void)registerForNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cancelOpenSlideActionButtons:)
                                                 name:kCancelOpenSlideActionButtonsNotification
                                               object:nil];
}

- (void)cancelOpenSlideActionButtons:(NSNotification *)notification {
    if (notification.object != self) {
        [self animateSlideButtonsWithNewCenter:self.originalCenter delay:0 duration:0.2 animated:YES];
    }
}

+ (void)cancelOpenSlideActionButtonsNotification:(CPUserActionCell *)cell {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCancelOpenSlideActionButtonsNotification
                                                        object:cell];
}

@end
