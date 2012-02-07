//
//  OneOnOneChatViewController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/02.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OneOnOneChatViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *chatDisplay;
@property (weak, nonatomic) IBOutlet UITextField *chatEntry;
@property (strong) UITextField *activeField;

-(IBAction)sendChat:(UITextField *)sender forEvent:(UIEvent *)event;

@end
