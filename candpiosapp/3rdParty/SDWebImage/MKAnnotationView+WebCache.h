//
//  MKAnnotationView+WebCache.h
//  customMapAnnotation
//
//  Created by Mohith K M on 9/26/11.
//  Copyright 2011 Mokriya  (www.mokriya.com). All rights reserved.
//

#import "SDWebImageCompat.h"
#import "SDWebImageManagerDelegate.h"
#import "MapKit/MapKit.h"

@interface MKAnnotationView (WebCache) <SDWebImageManagerDelegate>

- (void)setPin:(NSInteger)number hasCheckins:(BOOL)checkins hasVirtual:(BOOL)virtual isSolar:(BOOL)solar withLabel:(BOOL)withLabel;
- (void)setImage:(UIImage *)image fancy:(BOOL)fancyImage;
- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder fancy:(BOOL)fancyImage;
- (void)cancelCurrentImageLoad;

@end

