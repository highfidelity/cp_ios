//
//  CPSoundEffectsManager.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/29/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPSoundEffectsManager.h"

@implementation CPSoundEffectsManager

+ (void)playSoundWithSystemSoundID:(SystemSoundID)soundID
{  
    // play the sound effect
	AudioServicesPlaySystemSound(soundID);  
}

+ (void)disposeOfSoundWithSystemSoundID:(SystemSoundID)soundID
{
    // dispose of the sound effect
    AudioServicesDisposeSystemSoundID(soundID);
}

+ (SystemSoundID)systemSoundIDForSoundWithName:(NSString *)fileName type:(NSString *)fileExt
{
    // Generate an NSURL from the fileName and extension
    NSString* path = [[NSBundle mainBundle]
                      pathForResource:fileName ofType:fileExt];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    // var for systemSoundID
    SystemSoundID effectID;
    
    // create the system sound ID for this effect
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &effectID);
    
    return effectID;
}

+ (void)vibrateDevice
{
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
