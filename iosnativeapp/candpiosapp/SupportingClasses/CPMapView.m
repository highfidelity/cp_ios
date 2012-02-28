#import "CPMapView.h"
#import "OCAlgorithms.h"
#import "OCAnnotation.h"

@interface CPMapView (private)
- (void)initSetUp;
@end

@implementation CPMapView
@synthesize clusteringEnabled;
@synthesize annotationsToIgnore;
@synthesize clusterSize;
@synthesize clusterByGroupTag;
@synthesize minLongitudeDeltaToCluster;

- (id)init
{
    self = [super init];
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    
    return self;
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];    
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    return self;
}

- (void)initSetUp{
    allAnnotations = [[NSMutableSet alloc] init];
    annotationsToIgnore = [[NSMutableSet alloc] init];
    clusterSize = 0.04;
    minLongitudeDeltaToCluster = 0.1;
    clusteringEnabled = YES;
    clusterByGroupTag = YES;
    backgroundClusterQueue = dispatch_queue_create("com.OCMapView.clustering", NULL);  
}

// ======================================
#pragma mark MKMapView implementation

- (void)addAnnotation:(id < MKAnnotation >)annotation{
    if (![allAnnotations containsObject:annotation]) {
        [allAnnotations addObject:annotation];
//        [self doClustering];
    }
}

- (void)addAnnotations:(NSArray *)annotations{
    for (id<MKAnnotation> annotation in annotations) {
        [self addAnnotation:annotation];
    }
    
//    [allAnnotations addObjectsFromArray:annotations];
//    [self doClustering];
}

- (void)removeAnnotation:(id < MKAnnotation >)annotation{
    [allAnnotations removeObject:annotation];
//    [self doClustering];
}

- (void)removeAnnotations:(NSArray *)annotations{
    for (id<MKAnnotation> annotation in annotations) {
        [allAnnotations removeObject:annotation];
    }
//    [self doClustering];
}


// ======================================
#pragma mark - Properties
//
// Returns, like the original method,
// all annotations in the map unclustered.
- (NSArray *)annotations{
    return [allAnnotations allObjects];
}

//
// Returns all annotations which are actually displayed on the map. (clusters)
- (NSArray *)displayedAnnotations{
    return super.annotations;    
}

//
// enable or disable clustering
- (void)setClusteringEnabled:(BOOL)enabled{
    clusteringEnabled = enabled;
    [self doClustering];
}

// ======================================
#pragma mark - Clustering

- (void)doClustering{
    // Remove the annotation which should be ignored
//    NSMutableArray *bufferArray = [[NSMutableArray alloc] initWithArray:[allAnnotations allObjects]];
    NSMutableArray *bufferArray = [[NSMutableArray alloc] initWithArray:[allAnnotations allObjects]];    
   
//    [bufferArray removeObjectsInArray:[annotationsToIgnore allObjects]];
    NSMutableArray *annotationsToCluster = [[NSMutableArray alloc] initWithArray:[self filterAnnotationsForVisibleMap:bufferArray]];
    
    //calculate cluster radius
    CLLocationDistance clusterRadius = self.region.span.longitudeDelta * clusterSize;

    // Do clustering
    NSArray *clusteredAnnotations;
    clusteredAnnotations = [[NSArray alloc] initWithArray:[OCAlgorithms bubbleClusteringWithAnnotations:annotationsToCluster andClusterRadius:clusterRadius grouped:self.clusterByGroupTag]];

    // Clear map but leave Userlocation
    NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] initWithArray:self.displayedAnnotations];
    [annotationsToRemove removeObject:self.userLocation];
//    [annotationsToRemove removeObjectsInArray:clusteredAnnotations];
    
    // add clustered and ignored annotations to map
    [super addAnnotations: clusteredAnnotations];
//    [allAnnotations addObjectsFromArray:clusteredAnnotations];

    for (id <MKAnnotation> annotation in annotationsToRemove) {
        if ([annotation isKindOfClass:[OCAnnotation class]]) {
            [allAnnotations removeObject:annotation];
        }
    }
    
    // Make sure that allAnnotations has any new clusteredAnnotations
	for (id <MKAnnotation> annotation in clusteredAnnotations) {
        
        if (![allAnnotations containsObject:annotation]) {
            [allAnnotations addObject:annotation];
            [annotationsToRemove removeObject:annotation];
        }
        else {
            if ([annotation isKindOfClass:[OCAnnotation class]]) {
                [allAnnotations removeObject:annotation];
            }
        }
    }
    
//    [super addAnnotations: [annotationsToIgnore allObjects]];
    // fix for flickering
    [annotationsToRemove removeObjectsInArray: clusteredAnnotations];
    [super removeAnnotations:annotationsToRemove];
}

// ======================================
#pragma mark - Helpers

- (NSArray *)filterAnnotationsForVisibleMap:(NSArray *)annotationsToFilter{
    // return array
    NSMutableArray *filteredAnnotations = [[NSMutableArray alloc] initWithCapacity:[annotationsToFilter count]];
    
    // border calculation
    CLLocationDistance a = self.region.span.latitudeDelta/2.0;
    CLLocationDistance b = self.region.span.longitudeDelta /2.0;
    CLLocationDistance radius = sqrt(a*a + b*b);
    
    for (id<MKAnnotation> annotation in annotationsToFilter) {
        // if annotation is not inside the coordinates, kick it
        if (isLocationNearToOtherLocation(annotation.coordinate, self.centerCoordinate, radius)) {
            [filteredAnnotations addObject:annotation];
        }
    }
    
    return filteredAnnotations;
}

@end
