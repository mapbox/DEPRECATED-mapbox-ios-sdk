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

@interface RMQuadTreeNode ()

- (id)initWithMapView:(RMMapView *)aMapView forParent:(RMQuadTreeNode *)aParentNode inBoundingBox:(RMProjectedRect)aBoundingBox;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox toMutableArray:(NSMutableArray *)someArray createClusterAnnotations:(BOOL)createClusterAnnotations withClusterSize:(RMProjectedSize)clusterSize findGravityCenter:(BOOL)findGravityCenter;

- (void)removeUpwardsAllCachedClusterAnnotations;

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
    @synchronized (annotations) {
        for (RMAnnotation *annotation in annotations)
        {
            annotation.quadTreeNode = nil;
        }
    }
    [annotations release]; annotations = nil;
    cachedClusterAnnotation.layer = nil; [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;

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

    @synchronized (annotations) {
        immutableAnnotations = [NSArray arrayWithArray:annotations];
    }

    return immutableAnnotations;
}

- (void)addAnnotationToChildNodes:(RMAnnotation *)annotation
{
    RMProjectedRect projectedRect = annotation.projectedBoundingBox;
    if (RMProjectedRectContainsProjectedRect(northWestBoundingBox, projectedRect)) {
        if (!northWest) northWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northWestBoundingBox];
        [northWest addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(northEastBoundingBox, projectedRect)) {
        if (!northEast) northEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:northEastBoundingBox];
        [northEast addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(southWestBoundingBox, projectedRect)) {
        if (!southWest) southWest = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southWestBoundingBox];
        [southWest addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(southEastBoundingBox, projectedRect)) {
        if (!southEast) southEast = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:self inBoundingBox:southEastBoundingBox];
        [southEast addAnnotation:annotation];

    } else {
        @synchronized (annotations) {
            [annotations addObject:annotation];
        }
        annotation.quadTreeNode = self;
        [self removeUpwardsAllCachedClusterAnnotations];
    }
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    if (nodeType == nodeTypeLeaf)
    {
        @synchronized (annotations) {
            [annotations addObject:annotation];
        }
        annotation.quadTreeNode = self;

        if ([annotations count] <= kMaxAnnotationsPerLeaf || boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0)) {
            [self removeUpwardsAllCachedClusterAnnotations];
            return;
        }

        nodeType = nodeTypeNode;

        // problem: all annotations that cross two quadrants will always be re-added here, which
        // might be a problem depending on kMaxAnnotationsPerLeaf

        NSArray *immutableAnnotations = nil;
        @synchronized (annotations) {
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
    if (!annotation.quadTreeNode) return;

    @synchronized (annotations) {
        [annotations removeObject:annotation];
    }

    [self removeUpwardsAllCachedClusterAnnotations];
    annotation.quadTreeNode = nil;
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
        if (RMProjectedRectContainsProjectedRect(nextParentNode.boundingBox, annotation.projectedBoundingBox)) {
            [nextParentNode addAnnotationToChildNodes:annotation];
            break;
        }
    }

    [annotation release];
}

- (NSUInteger)countEnclosedAnnotations
{
    NSUInteger count = [annotations count];
    count += [northWest countEnclosedAnnotations];
    count += [northEast countEnclosedAnnotations];
    count += [southWest countEnclosedAnnotations];
    count += [southEast countEnclosedAnnotations];

    return count;
}

- (NSArray *)enclosedAnnotations
{
    NSMutableArray *enclosedAnnotations = [NSMutableArray arrayWithArray:self.annotations];
    if (northWest) [enclosedAnnotations addObjectsFromArray:northWest.enclosedAnnotations];
    if (northEast) [enclosedAnnotations addObjectsFromArray:northEast.enclosedAnnotations];
    if (southWest) [enclosedAnnotations addObjectsFromArray:southWest.enclosedAnnotations];
    if (southEast) [enclosedAnnotations addObjectsFromArray:southEast.enclosedAnnotations];

    return enclosedAnnotations;
}

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox toMutableArray:(NSMutableArray *)someArray createClusterAnnotations:(BOOL)createClusterAnnotations withClusterSize:(RMProjectedSize)clusterSize findGravityCenter:(BOOL)findGravityCenter
{
    if (createClusterAnnotations)
    {
        double halfWidth = boundingBox.size.width / 2.0;

        if (boundingBox.size.width >= clusterSize.width && halfWidth < clusterSize.width)
        {
            if (!cachedClusterAnnotation)
            {
                NSArray *enclosedAnnotations = self.enclosedAnnotations;
                NSUInteger enclosedAnnotationsCount = [enclosedAnnotations count];
                if (enclosedAnnotationsCount < 2) {
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

                    double halfClusterWidth = clusterSize.width / 2.0, halfClusterHeight = clusterSize.height / 2.0;
                    if (averageX - halfClusterWidth < boundingBox.origin.x) averageX = boundingBox.origin.x + halfClusterWidth;
                    if (averageX + halfClusterWidth > boundingBox.origin.x + boundingBox.size.width) averageX = boundingBox.origin.x + boundingBox.size.width - halfClusterWidth;
                    if (averageY - halfClusterHeight < boundingBox.origin.y) averageY = boundingBox.origin.y + halfClusterHeight;
                    if (averageY + halfClusterHeight > boundingBox.origin.y + boundingBox.size.height) averageY = boundingBox.origin.y + boundingBox.size.height - halfClusterHeight;

                    // TODO: anchorPoint
                    clusterMarkerPosition = RMProjectedPointMake(averageX, averageY);

                } else
                {
                    clusterMarkerPosition = RMProjectedPointMake(boundingBox.origin.x + halfWidth, boundingBox.origin.y + (boundingBox.size.height / 2.0));
                }

                cachedClusterAnnotation = [[RMAnnotation alloc] initWithMapView:mapView coordinate:[[mapView projection] projectedPointToCoordinate:clusterMarkerPosition] andTitle:[NSString stringWithFormat:@"%d", enclosedAnnotationsCount]];
                cachedClusterAnnotation.annotationType = kRMClusterAnnotationTypeName;
                cachedClusterAnnotation.userInfo = self;
            }

            [someArray addObject:cachedClusterAnnotation];
            return;
        }

        // TODO: leaf clustering (necessary?)
        if (nodeType == nodeTypeLeaf) {
            @synchronized (annotations) {
                [someArray addObjectsFromArray:annotations];
            }
            return;
        }

    } else {
        if (nodeType == nodeTypeLeaf) {
            @synchronized (annotations) {
                [someArray addObjectsFromArray:annotations];
            }
            return;
        }
    }

    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, northWestBoundingBox))
        [northWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withClusterSize:clusterSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, northEastBoundingBox))
        [northEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withClusterSize:clusterSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, southWestBoundingBox))
        [southWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withClusterSize:clusterSize findGravityCenter:findGravityCenter];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, southEastBoundingBox))
        [southEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray createClusterAnnotations:createClusterAnnotations withClusterSize:clusterSize findGravityCenter:findGravityCenter];

    @synchronized (annotations) {
        for (RMAnnotation *annotation in annotations)
        {
            if (RMProjectedRectInterectsProjectedRect(aBoundingBox, annotation.projectedBoundingBox))
                [someArray addObject:annotation];
        }
    }
}

- (void)removeUpwardsAllCachedClusterAnnotations
{
    if (parentNode) [parentNode removeUpwardsAllCachedClusterAnnotations];
    cachedClusterAnnotation.layer = nil; [cachedClusterAnnotation release]; cachedClusterAnnotation = nil;
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

- (void)addAnnotation:(RMAnnotation *)annotation
{
    [rootNode addAnnotation:annotation];
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    [annotation.quadTreeNode removeAnnotation:annotation];
}

- (void)removeAllObjects
{
    [rootNode release];
    rootNode = [[RMQuadTreeNode alloc] initWithMapView:mapView forParent:nil inBoundingBox:[[RMProjection googleProjection] planetBounds]];
}

#pragma mark -

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
{
    return [self annotationsInProjectedRect:boundingBox createClusterAnnotations:NO withClusterSize:RMProjectedSizeMake(0.0, 0.0) findGravityCenter:NO];
}

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox createClusterAnnotations:(BOOL)createClusterAnnotations withClusterSize:(RMProjectedSize)clusterSize findGravityCenter:(BOOL)findGravityCenter
{
    NSMutableArray *annotations = [NSMutableArray array];
    [rootNode addAnnotationsInBoundingBox:boundingBox toMutableArray:annotations createClusterAnnotations:createClusterAnnotations withClusterSize:clusterSize findGravityCenter:findGravityCenter];
    return annotations;
}

@end
