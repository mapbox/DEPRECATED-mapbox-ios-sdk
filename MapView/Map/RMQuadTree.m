//
//  RMQuadTree.m
//  MapView
//
//  Created by Thomas Rasch on 27.07.11.
//  Copyright 2011 Alpstein. All rights reserved.
//

#import "RMQuadTree.h"
#import "RMAnnotation.h"
#import "RMProjection.h"
#import "RMMapView.h"

#pragma mark -
#pragma mark RMQuadTreeNode implementation

#define kMinimumQuadTreeElementWidth 200.0 // projected meters
#define kMaxAnnotationsPerLeaf 4
#define kMinPixelDistanceForLeafClustering 100.0

@interface RMQuadTreeNode ()

- (id)initWithMapView:(RMMapView *)aMapView forParent:(RMQuadTreeNode *)aParentNode inBoundingBox:(RMProjectedRect)aBoundingBox;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox
                     toMutableArray:(NSMutableArray *)someArray
           createClusterAnnotations:(BOOL)createClusterAnnotations
           withProjectedClusterSize:(RMProjectedSize)clusterSize
      andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                  findGravityCenter:(BOOL)findGravityCenter;

- (void)removeUpwardsAllCachedClusterAnnotations;

- (void)precreateQuadTreeInBounds:(RMProjectedRect)quadTreeBounds withDepth:(NSUInteger)quadTreeDepth;

@end

@implementation RMQuadTreeNode

@synthesize nodeType;
@synthesize boundingBox, northWestBoundingBox, northEastBoundingBox, southWestBoundingBox, southEastBoundingBox;
@synthesize parentNode, northWest, northEast, southWest, southEast;

- (id)initWithMapView:(RMMapView *)aMapView forParent:(RMQuadTreeNode *)aParentNode inBoundingBox:(RMProjectedRect)aBoundingBox
{
    if (!(self = [super init]))
        return nil;

//    RMLog(@"New quadtree node at {(%.0f,%.0f),(%.0f,%.0f)}", aBoundingBox.origin.easting, aBoundingBox.origin.northing, aBoundingBox.size.width, aBoundingBox.size.height);

    mapView = aMapView;
    parentNode = [aParentNode retain];
    northWest = northEast = southWest = southEast = nil;
    annotations = [NSMutableArray new];
    boundingBox = aBoundingBox;
    cachedClusterAnnotation = nil;
    cachedClusterEnclosedAnnotations = nil;
    cachedEnclosedAnnotations = cachedUnclusteredAnnotations = nil;

    double halfWidth = boundingBox.size.width / 2.0, halfHeight = boundingBox.size.height / 2.0;
    northWestBoundingBox = RMProjectedRectMake(boundingBox.origin.x, boundingBox.origin.y + halfHeight, halfWidth, halfHeight);
    northEastBoundingBox = RMProjectedRectMake(boundingBox.origin.x + halfWidth, boundingBox.origin.y + halfHeight, halfWidth, halfHeight);
    southWestBoundingBox = RMProjectedRectMake(boundingBox.origin.x, boundingBox.origin.y, halfWidth, halfHeight);
    southEastBoundingBox = RMProjectedRectMake(boundingBox.origin.x + halfWidth, boundingBox.origin.y, halfWidth, halfHeight);

    nodeType = nodeTypeLeaf;

    return self;
}

- (void)dealloc
{
    mapView = nil;

    @synchronized (cachedClusterAnnotation)
    {
        [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
        [cachedClusterEnclosedAnnotations release]; cachedClusterEnclosedAnnotations = nil;
    }

    @synchronized (annotations)
    {
        for (RMAnnotation *annotation in annotations)
        {
            annotation.quadTreeNode = nil;
        }
    }

    [annotations release]; annotations = nil;
    [cachedEnclosedAnnotations release]; cachedEnclosedAnnotations = nil;
    [cachedUnclusteredAnnotations release]; cachedUnclusteredAnnotations = nil;

    [northWest release]; northWest = nil;
    [northEast release]; northEast = nil;
    [southWest release]; southWest = nil;
    [southEast release]; southEast = nil;
    [parentNode release]; parentNode = nil;

    [super dealloc];
}

- (NSArray *)annotations
{
    NSArray *immutableAnnotations = nil;

    @synchronized (annotations)
    {
        immutableAnnotations = [NSArray arrayWithArray:annotations];
    }

    return immutableAnnotations;
}

- (void)addAnnotationToChildNodes:(RMAnnotation *)annotation
{
    RMProjectedRect projectedRect = annotation.projectedBoundingBox;

    if (RMProjectedRectContainsProjectedRect(northWestBoundingBox, projectedRect))
    {
        if (!northWest)
            northWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northWestBoundingBox];

        [northWest addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(northEastBoundingBox, projectedRect))
    {
        if (!northEast)
            northEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northEastBoundingBox];

        [northEast addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(southWestBoundingBox, projectedRect))
    {
        if (!southWest)
            southWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southWestBoundingBox];

        [southWest addAnnotation:annotation];
    }
    else if (RMProjectedRectContainsProjectedRect(southEastBoundingBox, projectedRect))
    {
        if (!southEast)
            southEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southEastBoundingBox];

        [southEast addAnnotation:annotation];
    }
    else
    {
        @synchronized (annotations)
        {
            [annotations addObject:annotation];
        }

        annotation.quadTreeNode = self;
        [self removeUpwardsAllCachedClusterAnnotations];
    }
}

- (void)precreateQuadTreeInBounds:(RMProjectedRect)quadTreeBounds withDepth:(NSUInteger)quadTreeDepth
{
    if (quadTreeDepth == 0 || boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0))
        return;

//    RMLog(@"node in {%.0f,%.0f},{%.0f,%.0f} depth %d", boundingBox.origin.x, boundingBox.origin.y, boundingBox.size.width, boundingBox.size.height, quadTreeDepth);

    @synchronized (cachedClusterAnnotation)
    {
        [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
        [cachedClusterEnclosedAnnotations release]; cachedClusterEnclosedAnnotations = nil;
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, northWestBoundingBox))
    {
        if (!northWest)
            northWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northWestBoundingBox];

        [northWest precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, northEastBoundingBox))
    {
        if (!northEast)
            northEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northEastBoundingBox];

        [northEast precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, southWestBoundingBox))
    {
        if (!southWest)
            southWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southWestBoundingBox];

        [southWest precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (RMProjectedRectIntersectsProjectedRect(quadTreeBounds, southEastBoundingBox))
    {
        if (!southEast)
            southEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southEastBoundingBox];

        [southEast precreateQuadTreeInBounds:quadTreeBounds withDepth:quadTreeDepth-1];
    }

    if (nodeType == nodeTypeLeaf && [annotations count])
    {
        NSArray *immutableAnnotations = nil;

        @synchronized (annotations)
        {
            immutableAnnotations = [NSArray arrayWithArray:annotations];
            [annotations removeAllObjects];
        }

        for (RMAnnotation *annotationToMove in immutableAnnotations)
        {
            [self addAnnotationToChildNodes:annotationToMove];
        }
    }

    nodeType = nodeTypeNode;
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    if (nodeType == nodeTypeLeaf)
    {
        @synchronized (annotations)
        {
            [annotations addObject:annotation];
        }

        annotation.quadTreeNode = self;

        if ([annotations count] <= kMaxAnnotationsPerLeaf || boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0))
        {
            [self removeUpwardsAllCachedClusterAnnotations];
            return;
        }

        nodeType = nodeTypeNode;

        // problem: all annotations that cross two quadrants will always be re-added here, which
        // might be a problem depending on kMaxAnnotationsPerLeaf

        NSArray *immutableAnnotations = nil;

        @synchronized (annotations)
        {
            immutableAnnotations = [NSArray arrayWithArray:annotations];
            [annotations removeAllObjects];
        }

        for (RMAnnotation *annotationToMove in immutableAnnotations)
        {
            [self addAnnotationToChildNodes:annotationToMove];
        }

        return;
    }

    [self addAnnotationToChildNodes:annotation];
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    if (!annotation.quadTreeNode)
        return;

    annotation.quadTreeNode = nil;

    @synchronized (annotations)
    {
        [annotations removeObject:annotation];
    }

    [self removeUpwardsAllCachedClusterAnnotations];
}

- (void)annotationDidChangeBoundingBox:(RMAnnotation *)annotation
{
    if (RMProjectedRectContainsProjectedRect(boundingBox, annotation.projectedBoundingBox))
        return;

    [annotation retain];

    [self removeAnnotation:annotation];

    RMQuadTreeNode *nextParentNode = self;

    while ((nextParentNode = [nextParentNode parentNode]))
    {
        if (RMProjectedRectContainsProjectedRect(nextParentNode.boundingBox, annotation.projectedBoundingBox))
        {
            [nextParentNode addAnnotationToChildNodes:annotation];
            break;
        }
    }

    [annotation release];
}

- (NSArray *)enclosedAnnotations
{
    if (!cachedEnclosedAnnotations)
    {
        cachedEnclosedAnnotations = [[NSMutableArray alloc] initWithArray:self.annotations];
        if (northWest) [cachedEnclosedAnnotations addObjectsFromArray:northWest.enclosedAnnotations];
        if (northEast) [cachedEnclosedAnnotations addObjectsFromArray:northEast.enclosedAnnotations];
        if (southWest) [cachedEnclosedAnnotations addObjectsFromArray:southWest.enclosedAnnotations];
        if (southEast) [cachedEnclosedAnnotations addObjectsFromArray:southEast.enclosedAnnotations];
    }

    return cachedEnclosedAnnotations;
}

- (NSArray *)unclusteredAnnotations
{
    if (!cachedUnclusteredAnnotations)
    {
        cachedUnclusteredAnnotations = [NSMutableArray new];

        @synchronized (annotations)
        {
            for (RMAnnotation *annotation in annotations)
            {
                if (!annotation.clusteringEnabled)
                    [cachedUnclusteredAnnotations addObject:annotation];
            }
        }

        if (northWest) [cachedUnclusteredAnnotations addObjectsFromArray:[northWest unclusteredAnnotations]];
        if (northEast) [cachedUnclusteredAnnotations addObjectsFromArray:[northEast unclusteredAnnotations]];
        if (southWest) [cachedUnclusteredAnnotations addObjectsFromArray:[southWest unclusteredAnnotations]];
        if (southEast) [cachedUnclusteredAnnotations addObjectsFromArray:[southEast unclusteredAnnotations]];
    }

    return cachedUnclusteredAnnotations;
}

- (NSArray *)enclosedWithoutUnclusteredAnnotations
{
    NSArray *unclusteredAnnotations = self.unclusteredAnnotations;
    if (!unclusteredAnnotations || [unclusteredAnnotations count] == 0)
        return self.enclosedAnnotations;

    NSMutableArray *enclosedAnnotations = [NSMutableArray arrayWithArray:self.enclosedAnnotations];
    [enclosedAnnotations removeObjectsInArray:unclusteredAnnotations];

    return enclosedAnnotations;
}

- (RMAnnotation *)clusterAnnotation
{
    return cachedClusterAnnotation;
}

- (NSArray *)clusteredAnnotations
{
    NSArray *clusteredAnnotations = nil;

    @synchronized (cachedClusterAnnotation)
    {
        clusteredAnnotations = [NSArray arrayWithArray:cachedClusterEnclosedAnnotations];
    }

    return clusteredAnnotations;
}

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox
                     toMutableArray:(NSMutableArray *)someArray
           createClusterAnnotations:(BOOL)createClusterAnnotations
           withProjectedClusterSize:(RMProjectedSize)clusterSize
      andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                  findGravityCenter:(BOOL)findGravityCenter
{
    if (createClusterAnnotations)
    {
        double halfWidth     = boundingBox.size.width / 2.0;
        BOOL forceClustering = (boundingBox.size.width >= clusterSize.width && halfWidth < clusterSize.width);

        NSArray *enclosedAnnotations = nil;

        // Leaf clustering
        if (forceClustering == NO && nodeType == nodeTypeLeaf && [annotations count] > 1)
        {
            NSMutableArray *annotationsToCheck = [NSMutableArray arrayWithArray:[self enclosedWithoutUnclusteredAnnotations]];

            for (NSInteger i=[annotationsToCheck count]-1; i>0; --i)
            {
                BOOL mustBeClustered = NO;
                RMAnnotation *currentAnnotation = [annotationsToCheck objectAtIndex:i];

                for (NSInteger j=i-1; j>=0; --j)
                {
                    RMAnnotation *secondAnnotation = [annotationsToCheck objectAtIndex:j];

                    // This is of course not very accurate but is good enough for this use case
                    double distance = RMEuclideanDistanceBetweenProjectedPoints(currentAnnotation.projectedLocation, secondAnnotation.projectedLocation) / mapView.metersPerPixel;
                    if (distance < kMinPixelDistanceForLeafClustering)
                    {
                        mustBeClustered = YES;
                        break;
                    }
                }

                if (!mustBeClustered)
                {
                    [someArray addObject:currentAnnotation];
                    [annotationsToCheck removeObjectAtIndex:i];
                }
            }

            forceClustering = ([annotationsToCheck count] > 0);

            if (forceClustering)
            {
                @synchronized (cachedClusterAnnotation)
                {
                    [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
                    [cachedClusterEnclosedAnnotations release]; cachedClusterEnclosedAnnotations = nil;
                }

                enclosedAnnotations = [NSArray arrayWithArray:annotationsToCheck];
            }
        }

        if (forceClustering)
        {
            if (!enclosedAnnotations)
                enclosedAnnotations = [self enclosedWithoutUnclusteredAnnotations];

            @synchronized (cachedClusterAnnotation)
            {
                if (cachedClusterAnnotation && [enclosedAnnotations count] != [cachedClusterEnclosedAnnotations count])
                {
                    [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
                    [cachedClusterEnclosedAnnotations release]; cachedClusterEnclosedAnnotations = nil;
                }
            }

            if (!cachedClusterAnnotation)
            {
                NSUInteger enclosedAnnotationsCount = [enclosedAnnotations count];

                if (enclosedAnnotationsCount < 2)
                {
                    [someArray addObjectsFromArray:enclosedAnnotations];
                    return;
                }

                RMProjectedPoint clusterMarkerPosition;

                if (findGravityCenter)
                {
                    double averageX = 0.0, averageY = 0.0;

                    for (RMAnnotation *annotation in enclosedAnnotations)
                    {
                        averageX += annotation.projectedLocation.x;
                        averageY += annotation.projectedLocation.y;
                    }

                    averageX /= (double)enclosedAnnotationsCount;
                    averageY /= (double) enclosedAnnotationsCount;

                    double halfClusterMarkerWidth = clusterMarkerSize.width / 2.0,
                           halfClusterMarkerHeight = clusterMarkerSize.height / 2.0;

                    if (averageX - halfClusterMarkerWidth < boundingBox.origin.x)
                        averageX = boundingBox.origin.x + halfClusterMarkerWidth;
                    if (averageX + halfClusterMarkerWidth > boundingBox.origin.x + boundingBox.size.width)
                        averageX = boundingBox.origin.x + boundingBox.size.width - halfClusterMarkerWidth;
                    if (averageY - halfClusterMarkerHeight < boundingBox.origin.y)
                        averageY = boundingBox.origin.y + halfClusterMarkerHeight;
                    if (averageY + halfClusterMarkerHeight > boundingBox.origin.y + boundingBox.size.height)
                        averageY = boundingBox.origin.y + boundingBox.size.height - halfClusterMarkerHeight;

                    // TODO: anchorPoint
                    clusterMarkerPosition = RMProjectedPointMake(averageX, averageY);
                }
                else
                {
                    clusterMarkerPosition = RMProjectedPointMake(boundingBox.origin.x + halfWidth, boundingBox.origin.y + (boundingBox.size.height / 2.0));
                }

                CLLocationCoordinate2D clusterMarkerCoordinate = [[mapView projection] projectedPointToCoordinate:clusterMarkerPosition];

                cachedClusterAnnotation = [[RMAnnotation alloc] initWithMapView:mapView
                                                                     coordinate:clusterMarkerCoordinate
                                                                       andTitle:[NSString stringWithFormat:@"%d", enclosedAnnotationsCount]];
                cachedClusterAnnotation.annotationType = kRMClusterAnnotationTypeName;
                cachedClusterAnnotation.userInfo = self;

                cachedClusterEnclosedAnnotations = [[NSArray alloc] initWithArray:enclosedAnnotations];
            }

            [someArray addObject:cachedClusterAnnotation];
            [someArray addObjectsFromArray:[self unclusteredAnnotations]];

            return;
        }

        if (nodeType == nodeTypeLeaf)
        {
            @synchronized (annotations)
            {
                [someArray addObjectsFromArray:annotations];
            }

            return;
        }
    }
    else
    {
        if (nodeType == nodeTypeLeaf)
        {
            @synchronized (annotations)
            {
                [someArray addObjectsFromArray:annotations];
            }

            return;
        }
    }

    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, northWestBoundingBox))
        [northWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, northEastBoundingBox))
        [northEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, southWestBoundingBox))
        [southWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, southEastBoundingBox))
        [southEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];

    @synchronized (annotations)
    {
        for (RMAnnotation *annotation in annotations)
        {
            if (RMProjectedRectIntersectsProjectedRect(aBoundingBox, annotation.projectedBoundingBox))
                [someArray addObject:annotation];
        }
    }
}

- (void)removeUpwardsAllCachedClusterAnnotations
{
    if (parentNode)
        [parentNode removeUpwardsAllCachedClusterAnnotations];

    @synchronized (cachedClusterAnnotation)
    {
        [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
        [cachedClusterEnclosedAnnotations release]; cachedClusterEnclosedAnnotations = nil;
    }

    [cachedEnclosedAnnotations release]; cachedEnclosedAnnotations = nil;
    [cachedUnclusteredAnnotations release]; cachedUnclusteredAnnotations = nil;
}

@end

#pragma mark -
#pragma mark RMQuadTree implementation

@implementation RMQuadTree

- (id)initWithMapView:(RMMapView *)aMapView
{
    if (!(self = [super init]))
        return nil;

    mapView = aMapView;
    rootNode = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:nil inBoundingBox:[[RMProjection googleProjection] planetBounds]];

    return self;
}

- (void)dealloc
{
    mapView = nil;
    [rootNode release]; rootNode = nil;
    [super dealloc];
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    @synchronized (self)
    {
        [rootNode addAnnotation:annotation];
    }
}

- (void)addAnnotations:(NSArray *)annotations
{
//    RMLog(@"Prepare tree");
//    [rootNode precreateQuadTreeInBounds:[[RMProjection googleProjection] planetBounds] withDepth:5];

    @synchronized (self)
    {
        for (RMAnnotation *annotation in annotations)
        {
            [rootNode addAnnotation:annotation];
        }
    }
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    @synchronized (self)
    {
        [annotation.quadTreeNode removeAnnotation:annotation];
    }
}

- (void)removeAllObjects
{
    @synchronized (self)
    {
        [rootNode release];
        rootNode = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:nil inBoundingBox:[[RMProjection googleProjection] planetBounds]];
    }
}

#pragma mark -

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
{
    return [self annotationsInProjectedRect:boundingBox createClusterAnnotations:NO withProjectedClusterSize:RMProjectedSizeMake(0.0, 0.0) andProjectedClusterMarkerSize:RMProjectedSizeMake(0.0, 0.0) findGravityCenter:NO];
}

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox createClusterAnnotations:(BOOL)createClusterAnnotations withProjectedClusterSize:(RMProjectedSize)clusterSize andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize findGravityCenter:(BOOL)findGravityCenter
{
    NSMutableArray *annotations = [NSMutableArray array];

    @synchronized (self)
    {
        [rootNode addAnnotationsInBoundingBox:boundingBox toMutableArray:annotations createClusterAnnotations:createClusterAnnotations withProjectedClusterSize:clusterSize andProjectedClusterMarkerSize:clusterMarkerSize findGravityCenter:findGravityCenter];
    }

    return annotations;
}

@end
