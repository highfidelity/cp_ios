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
#import "CPAnnotation.h"

@implementation OCAlgorithms

#pragma mark - bubbleClustering

// Bubble clustering with iteration
+ (NSArray*) bubbleClusteringWithAnnotations:(NSMutableArray *)annotationsToCluster andClusterRadius:(CLLocationDistance)radius grouped:(BOOL)grouped clustered:(BOOL)allowClustering {
    
    // memory
    [annotationsToCluster retain];
    
    // return array
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    NSMutableArray *removeAnnotations = [[NSMutableArray alloc] init];
    
    BOOL addAnnotationNow;

    if (allowClustering) {
        for (id <MKAnnotation> annotation in annotationsToCluster) {
            if ([annotation isKindOfClass:[OCAnnotation class]]) {
                [clusteredAnnotations addObject:annotation];
            }
        }
    }

    // Iterate through all previous clusters to remove any that no longer have an annotation close to them
    for (id <MKAnnotation> annotation in clusteredAnnotations) {
//        BOOL removeAnnotation = NO;
        
        if (clusteredAnnotations.count > 0) {
            for (OCAnnotation *clusterAnnotation in [(OCAnnotation *)annotation annotationsInCluster]) {
                if (!isLocationNearToOtherLocation([annotation coordinate], [clusterAnnotation coordinate], radius) && clusterAnnotation != annotation) {
                    [removeAnnotations addObject:annotation];
                }
            }            
        }
    }

    // Iterate through all clusters and remove any that are too close to another cluster
    for (id <MKAnnotation> annotation in clusteredAnnotations) {
        //        BOOL removeAnnotation = NO;

        for (OCAnnotation *clusterAnnotation in clusteredAnnotations) {
            // If the annotation is in range of the Cluster add it to it
            if (isLocationNearToOtherLocation([annotation coordinate], [clusterAnnotation coordinate], radius) && clusterAnnotation != annotation && allowClustering) {
                [removeAnnotations addObject:annotation];
                [removeAnnotations addObject:clusterAnnotation];
            }
        }
    }

    if (removeAnnotations.count > 0) {            
        [clusteredAnnotations removeObjectsInArray:removeAnnotations];
    }
    
    
	// Clustering
	for (id <MKAnnotation> annotation in annotationsToCluster) {
        if ([annotation isKindOfClass:[OCAnnotation class]]) {
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
            BOOL removeAnnotation = NO;
            
            for (OCAnnotation *clusterAnnotation in clusteredAnnotations) {                
                // If the annotation is in range of the Cluster add it to it
                if (isLocationNearToOtherLocation([annotation coordinate], [clusterAnnotation coordinate], radius)) {

                    // Check for duplicate annotations, and don't re-add to a cluster if it's already in it
                    if ([annotation isKindOfClass:[CPAnnotation class]]) {
                        if ([clusterAnnotation.annotationsInCluster containsObject:annotation]) {
//                        if ([clusterAnnotation.userIdsInCluster containsObject:[(CandPAnnotation *)annotation objectId]]) {
                            addAnnotationNow = NO;
                            isContaining = YES;
                        }
                        else {
                            addAnnotationNow = YES;
                        }
                    }
                    else if (!([clusterAnnotation.annotationsInCluster containsObject:annotation] && clusterAnnotation.annotationsInCluster.count == 1)) {
//                        addAnnotationNow = YES;
                    }
                    
                    if (addAnnotationNow) {                       
                        isContaining = YES;
                        [clusterAnnotation addAnnotation:annotation];

                        break;
                    }
				}
                else {
                    removeAnnotation = YES;
                    
                    // Remove the current annotation from the clusterAnnotation.annotationsInCluster array
                    [clusterAnnotation.annotationsInCluster removeObject:annotation];

//                    [clusterAnnotation.userIdsInCluster removeObject:[(CPAnnotation *)annotation objectId]];
                }
            }

            if (removeAnnotation) {
                [clusteredAnnotations removeObject:annotation];
//                [removeAnnotations addObject:annotation];
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

    for (OCAnnotation *clusterAnnotation in clusteredAnnotations) {        
        NSInteger usersCheckedIn = 0;
        NSMutableSet *checkedInVenues = [[NSMutableSet alloc] init];
        NSMutableSet *venues = [[NSMutableSet alloc] init];
        BOOL hasCheckedIn = NO;
        
        for (id <MKAnnotation> annotation in clusterAnnotation.annotationsInCluster) {
            if ([annotation isKindOfClass:[CPAnnotation class]]) {
                CPAnnotation *thisAnnotation = annotation;
                
                if (thisAnnotation.checkedIn) {
                    hasCheckedIn = YES;
                    usersCheckedIn++;
                }

                if (thisAnnotation.venueName) {
                    [venues addObject:thisAnnotation.venueName];

                    if (thisAnnotation.checkedIn) {
                        [checkedInVenues addObject:thisAnnotation.venueName];
                    }
                }
            }
        }

        if (((venues.count > 1 && !hasCheckedIn) || (checkedInVenues.count > 1 && hasCheckedIn)) && allowClustering) {
            clusterAnnotation.title = @"Zoom In To See Places";
        }
        else if (venues.count == 1 && !hasCheckedIn) {
            clusterAnnotation.title = [venues anyObject];
        }
        else if (checkedInVenues.count == 1 && hasCheckedIn) {
            clusterAnnotation.title = [checkedInVenues anyObject];
        }
        else {
            clusterAnnotation.title = @"A Place With No Name";
        }
        
        if (usersCheckedIn > 0) {
            clusterAnnotation.hasCheckins = YES;
            clusterAnnotation.subtitle = [NSString stringWithFormat:@"%d %@ here now", usersCheckedIn, (usersCheckedIn != 1) ? @"people" : @"person"];
        }
        else {
            clusterAnnotation.hasCheckins = NO;
            clusterAnnotation.subtitle = [NSString stringWithFormat:@"%d checkin%@ in the last week", clusterAnnotation.annotationsInCluster.count, (clusterAnnotation.annotationsInCluster.count != 1) ? @"s" : @""];
        }
    }
    
    // wipe all empty or single annotations
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