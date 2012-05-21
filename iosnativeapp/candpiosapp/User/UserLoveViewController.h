//
//  UserLoveViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/21/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPPlaceholderTextView.h"

@interface UserLoveViewController : UIViewController
@property (weak, nonatomic) id delegate;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet CPPlaceholderTextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) User *user;


@end
