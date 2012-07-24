//
//  UserProfileLinkedInViewController.h
//  candpiosapp
//
//  Created by Bryan Galusha on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserProfileLinkedInViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, strong) NSString *linkedInProfileUrlAddress;
@property (nonatomic, weak) IBOutlet UIWebView *socialWebView;


@end
