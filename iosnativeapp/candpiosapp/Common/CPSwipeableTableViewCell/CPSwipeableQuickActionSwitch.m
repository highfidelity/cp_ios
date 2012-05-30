//
//  CPSwipeableQuickActionSwitch.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSwipeableQuickActionSwitch.h"

@implementation CPSwipeableQuickActionSwitch

@synthesize onImage = _onImage;
@synthesize offImage = _offImage;
@synthesize onSoundID = _onSoundID;
@synthesize offSoundID = _offSoundID;

- (id)initWithAssetPrefix:(NSString *)prefix
{
    
    if (self = [super init]) {
        
        // set our properties for on and off image states and
        // systemSoundIDs for on and off sounds
        self.onImage = [UIImage imageNamed:[prefix stringByAppendingString:@"-on"]];
        self.offImage = [UIImage imageNamed:[prefix stringByAppendingString:@"-off"]];
        self.onSoundID = [CPSoundEffectsManager systemSoundIDForSoundWithName:[prefix stringByAppendingString:@"-sound-on"] type:@"wav"];
        self.offSoundID = [CPSoundEffectsManager systemSoundIDForSoundWithName:[prefix stringByAppendingString:@"-sound-off"] type:@"wav"];
    }
    
    return self;
}

- (void)dealloc
{
    [CPSoundEffectsManager disposeOfSoundWithSystemSoundID:self.onSoundID];
    [CPSoundEffectsManager disposeOfSoundWithSystemSoundID:self.offSoundID];
}

@end
