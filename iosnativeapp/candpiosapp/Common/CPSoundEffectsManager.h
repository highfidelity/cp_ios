//
//  CPSoundEffectsManager.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

// original credit goes to http://blog.danilocampos.com/2009/12/14/an-objective-c-wrapper-for-audioservicesplaysystemsound/

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CPSoundEffectsManager : NSObject

+ (void)playSoundWithSystemSoundID:(SystemSoundID)soundID;
+ (void)disposeOfSoundWithSystemSoundID:(SystemSoundID)soundID;
+ (SystemSoundID)systemSoundIDForSoundWithName:(NSString *)fileName type:(NSString *)fileExt;
+ (void)vibrateDevice;

@end
