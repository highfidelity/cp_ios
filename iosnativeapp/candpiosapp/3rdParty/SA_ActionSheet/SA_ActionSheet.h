//
//  SA_ActionSheet.h
//  Crosswords iPad
//
//  Created by Ben Gottlieb on 12/29/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#if NS_BLOCKS_AVAILABLE
	typedef void (^actionViewButtonHit)(int buttonIndex);
#endif


@interface SA_ActionSheet : UIActionSheet <UIActionSheetDelegate> {

}


#if NS_BLOCKS_AVAILABLE
	@property (nonatomic, readwrite, assign) actionViewButtonHit actionButtonHit;

	- (void) showFromToolbar: (UIToolbar *) view buttonBlock: (actionViewButtonHit) block;
	- (void) showFromTabBar: (UITabBar *) view buttonBlock: (actionViewButtonHit) block;
	- (void) showFromBarButtonItem: (UIBarButtonItem *) item animated: (BOOL) animated buttonBlock: (actionViewButtonHit) block;
	- (void) showFromRect: (CGRect) rect inView: (UIView *) view animated: (BOOL) animated buttonBlock: (actionViewButtonHit) block;
	- (void) showInView: (UIView *) view buttonBlock: (actionViewButtonHit) block;
#endif

@end
