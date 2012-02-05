//
//  ClusterAnnotation.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 05.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ClusterAnnotation.h"

@implementation ClusterAnnotation

@synthesize coordinate;

- (id) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        [self addSubview:label];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:11]; 
        label.textAlignment = UITextAlignmentCenter;
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(0,-1);
    }
    return self;
}

- (void) setClusterText:(NSString *)text
{
    label.text = text;
}

@end
