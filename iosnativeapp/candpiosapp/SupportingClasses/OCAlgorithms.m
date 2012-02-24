//
//  OCAlgorythms.m
//  openClusterMapView
//
//  Created by Botond Kis on 15.07.11.
//

#import "OCAlgorithms.h"
#import "OCAnnotation.h"
#import "OCDistance.h"
#import "OCGrouping.h"
#import <math.h>
#import "CandPAnnotation.h"

@implementation OCAlgorithms

#pragma mark - bubbleClustering

// Bubble clustering with iteration
+ (NSArray*) bubbleClusteringWithAnnotations:(NSArray *)annotationsToCluster andClusterRadius:(CLLocationDistance)radius grouped:(BOOL)grouped {
    
    // memory
    [annotationsToCluster retain];
    
    // return array
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    
	// Clustering
	for (id <MKAnnotation> annotation in annotationsToCluster) {
        if ([annotation isKindOfClass:[OCAnnotation class]]) {
            NSLog(@"clustered, skip!");
            continue;
        }
		// flag for cluster
		BOOL isContaining = NO;

		// If it's the first one, add it as new cluster annotation
		if([clusteredAnnotations count] == 0){
            OCAnnotation *newCluster = [[OCAnnotation alloc] initWithAnnotation:annotation];
            [clusteredAnnotations addObject:newCluster];
            
            // check group
            if (grouped && [annotation respondsToSelector:@selector(groupTag)]) {
                newCluster.groupTag = ((id <OCGrouping>)annotation).groupTag;
            }
            
            [newCluster release];
		}
		else {
            for (OCAnnotation *clusterAnnotation in clusteredAnnotations) {
                // If the annotation is in range of the Cluster add it to it
                if (isLocationNearToOtherLocation([annotation coordinate], [clusterAnnotation coordinate], radius) && !([clusterAnnotation.annotationsInCluster containsObject:annotation] && clusterAnnotation.annotationsInCluster.count == 1)) {

                    clusterAnnotation.title = [NSString stringWithFormat:@"%d people checked in", clusterAnnotation.annotationsInCluster.count + 1];
                    clusterAnnotation.subtitle = @"";

//                    NSLog(@"** %@ near to %@", annotation.title, clusterAnnotation.title);
                    
					isContaining = YES;
					[clusterAnnotation addAnnotation:annotation];
					break;
				}
            }
            
            // If the annotation is not in a Cluster make it to a new one
			if (!isContaining){
				OCAnnotation *newCluster = [[OCAnnotation alloc] initWithAnnotation:annotation];
				[clusteredAnnotations addObject:newCluster];
                
                // check group
                if (grouped && [annotation respondsToSelector:@selector(groupTag)]) {
                    newCluster.groupTag = ((id <OCGrouping>)annotation).groupTag;
                }
                
                [newCluster release];
			}
		}
	}
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    // whipe all empty or single annotations
    for (OCAnnotation *anAnnotation in clusteredAnnotations) {
        if ([anAnnotation.annotationsInCluster count] <= 1) {
            [returnArray addObject:[anAnnotation.annotationsInCluster lastObject]];
        }
        else{
            [returnArray addObject:anAnnotation];
        }
    }
    
    // memory
    [annotationsToCluster release];
    [clusteredAnnotations release];
    
    return [returnArray autorelease];
}

@end