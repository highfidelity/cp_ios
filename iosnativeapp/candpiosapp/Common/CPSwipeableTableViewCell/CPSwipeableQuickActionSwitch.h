//
//  CPSwipeableQuickActionSwitch.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPSoundEffectsManager.h"

@interface CPSwipeableQuickActionSwitch : NSObject

@property (nonatomic, strong) UIImage *onImage;
@property (nonatomic, strong) UIImage *offImage;
@property (nonatomic, assign) SystemSoundID onSoundID;
@property (nonatomic, assign) SystemSoundID offSoundID;

- (id)initWithAssetPrefix:(NSString *)prefix;

@end
