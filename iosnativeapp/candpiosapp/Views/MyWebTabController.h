//
//  MyWebTabController.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MyWebTabController : UIViewController< MKMapViewDelegate >
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
