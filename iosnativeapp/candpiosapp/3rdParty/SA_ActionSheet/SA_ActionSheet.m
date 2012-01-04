//
//  SA_ActionSheet.m
//  Crosswords iPad
//
//  Created by Ben Gottlieb on 12/29/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "SA_ActionSheet.h"

@implementation SA_ActionSheet

- (void) dealloc {
	#if NS_BLOCKS_AVAILABLE
		if (self.actionButtonHit) Block_release(self.actionButtonHit);
	#endif
	[super dealloc];
}	

#if NS_BLOCKS_AVAILABLE
- (void) showFromToolbar: (UIToolbar *) view buttonBlock: (actionViewButtonHit) block {
	self.actionButtonHit = Block_copy(block);
	self.delegate = self;
	[super showFromToolbar: view];
}

- (void) showFromTabBar: (UITabBar *) view buttonBlock: (actionViewButtonHit) block {
	self.actionButtonHit = Block_copy(block);
	self.delegate = self;
	[super showFromTabBar: view];
}

- (void) showFromBarButtonItem: (UIBarButtonItem *) item animated: (BOOL) animated buttonBlock: (actionViewButtonHit) block {
	self.actionButtonHit = Block_copy(block);
	self.delegate = self;
	[super showFromBarButtonItem: item animated: animated];
}

- (void) showFromRect: (CGRect) rect inView: (UIView *) view animated: (BOOL) animated buttonBlock: (actionViewButtonHit) block {
	self.actionButtonHit = Block_copy(block);
	self.delegate = self;
	[super showFromRect: rect inView: view animated: animated];
}
- (void) showInView: (UIView *) view buttonBlock: (actionViewButtonHit) block {
	self.actionButtonHit = Block_copy(block);
	self.delegate = self;
	[super showInView: view];
}

@synthesize actionButtonHit;

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (self.actionButtonHit) self.actionButtonHit(buttonIndex);
}
#endif

@end
