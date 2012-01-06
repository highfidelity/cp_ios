//
//  MyWebTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyWebTabController : UIViewController< UIWebViewDelegate >
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, copy) NSString *urlToLoad;
@property (nonatomic, copy) NSMutableURLRequest *urlRequestToLoad;
@end
