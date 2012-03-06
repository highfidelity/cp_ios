//
//  DismissHUDAfterReloadData.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/5/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "DismissHUDAfterReloadData.h"
#import "SVProgressHUD.h"

@implementation DismissHUDAfterReloadData


- (void)reloadData
{
    // actually reload the data by calling super
    [super reloadData];
    // dismiss the SVProgressHUD
    [SVProgressHUD dismiss];
}


@end
