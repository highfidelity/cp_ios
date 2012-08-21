//
//  CPPlaceholderTextView.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/21/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

// credit where credit is due
// taken directly from code at http://stackoverflow.com/questions/1328638/placeholder-in-uitextview

#import <UIKit/UIKit.h>

@interface CPPlaceholderTextView : UITextView 

@property (strong, nonatomic) NSString *placeholder;
@property (strong, nonatomic) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end