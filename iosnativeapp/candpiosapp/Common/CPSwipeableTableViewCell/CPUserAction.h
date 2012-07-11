//
//  CPUserAction.h
//  candpiosapp
//
//  Created by Andrew Hammond on 7/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPUserActionCell.h"

@interface CPUserAction : NSObject
+ (void)cell:(CPUserActionCell*)cell sendLoveFromViewController:(UIViewController*)viewController;
+ (void)cell:(CPUserActionCell*)cell sendMessageFromViewController:(UIViewController*)viewController;
+ (void)cell:(CPUserActionCell*)cell exchangeContactsFromViewController:(UIViewController*)viewController;
+ (void)cell:(CPUserActionCell*)cell showProfileFromViewController:(UIViewController*)viewController;

@end
