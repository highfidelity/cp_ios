//
//  VenueChatViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 4/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VenueChat.h"

@interface VenueChatViewController : UIViewController

@property (nonatomic, strong) CPVenue *venue;
@property (nonatomic, strong) VenueChat *venueChat;

@end
