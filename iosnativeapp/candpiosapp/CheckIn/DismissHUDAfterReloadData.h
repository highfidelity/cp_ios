//
//  DismissHUDAfterReloadData.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/5/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// This class was created simply to overrride the reloadData method for a UITableView.
// This was required specifically in order to hide the HUD we're using AFTER the table reloads it's data
// Because otherwise we had a gap in between the time the data was loaded and the HUD dissapeared, 
// making it look like there was an error.
// This implementation came about because of this answer on Stack Overflow
// http://stackoverflow.com/questions/1483581/get-notified-when-uitableview-has-finished-asking-for-data

@interface DismissHUDAfterReloadData : UITableView

- (void)reloadData;

@end
