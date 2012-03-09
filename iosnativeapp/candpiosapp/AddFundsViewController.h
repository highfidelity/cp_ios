//
//  AddFundsViewController.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 02.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddFundsViewController : UIViewController <UIWebViewDelegate> {
	IBOutlet UIWebView *webView;
	NSString *urlAddress;
	UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *urlAddress;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

-(IBAction)goBack:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end