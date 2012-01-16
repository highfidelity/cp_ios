//
//  WebViewController.h
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController <UIWebViewDelegate> {

	IBOutlet UINavigationItem *navItem;
	IBOutlet	UILabel		*modalTitle;
	IBOutlet UIWebView *webView;
	NSString *urlAddress;
	NSString *venueName;
	UIActivityIndicatorView *activityIndicator;
}

@property (retain, nonatomic) UINavigationItem *navItem;
@property (retain, nonatomic) UILabel *modalTitle;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *urlAddress;
@property (nonatomic, retain) NSString *venueName;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

-(IBAction)goBack:(id)sender;
//-(IBAction)buttonPressed:(id)sender;

@end
