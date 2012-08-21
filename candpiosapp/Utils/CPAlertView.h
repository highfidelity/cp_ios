//
//  CPAlertView.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/23.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//
//  I created this for the following use case:
//   - a chat message comes in from a certain user
//   - we show an alert for that chat with "View" and "Ignore" buttons
//   - if the user clicks 'View', how does the UIAlertView delegate know
//     which userId the chat was from?
//   - This subclass lets us attatch some data to the UIAlertView so we
//     can figure this out
//  Stolen from http://stackoverflow.com/questions/1063315/how-to-safely-pass-a-context-object-in-an-uialertview-delegate

#import <Foundation/Foundation.h>

@interface CPAlertView : UIAlertView

@property (weak, nonatomic) UIViewController *rootView;
@property (strong, nonatomic) id context;

@end
