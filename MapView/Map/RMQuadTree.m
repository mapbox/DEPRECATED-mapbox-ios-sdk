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

#pragma mark -
#pragma mark RMQuadTreeElement implementation

#define kMinimumQuadTreeElementWidth 200.0 // projected meters
#define kMaxAnnotationsPerLeaf 8

@interface RMQuadTreeNode ()

- (id)initWithParent:(RMQuadTreeNode *)aParent forBoundingBox:(RMProjectedRect)aBoundingBox;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox toMutableArray:(NSMutableArray *)someArray;

@end

@implementation RMQuadTreeNode

- (id)initWithParent:(RMQuadTreeNode *)aParentNode forBoundingBox:(RMProjectedRect)aBoundingBox
{
    if (!(self = [super init]))
        return nil;

//    RMLog(@"New quadtree node at {(%.0f,%.0f),(%.0f,%.0f)}", aBoundingBox.origin.easting, aBoundingBox.origin.northing, aBoundingBox.size.width, aBoundingBox.size.height);

    parentNode = aParentNode;
    northWest = northEast = southWest = southEast = nil;
    annotations = [NSMutableArray new];
    boundingBox = aBoundingBox;

    double halfWidth = boundingBox.size.width / 2.0, halfHeight = boundingBox.size.height / 2.0;
    northWestBoundingBox = RMMakeProjectedRect(boundingBox.origin.easting, boundingBox.origin.northing + halfHeight, halfWidth, halfHeight);
    northEastBoundingBox = RMMakeProjectedRect(boundingBox.origin.easting + halfWidth, boundingBox.origin.northing + halfHeight, halfWidth, halfHeight);
    southWestBoundingBox = RMMakeProjectedRect(boundingBox.origin.easting, boundingBox.origin.northing, halfWidth, halfHeight);
    southEastBoundingBox = RMMakeProjectedRect(boundingBox.origin.easting + halfWidth, boundingBox.origin.northing, halfWidth, halfHeight);

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

    [northWest release]; northWest = nil;
    [northEast release]; northEast = nil;
    [southWest release]; southWest = nil;
    [southEast release]; southEast = nil;
    parentNode = nil;

    [super dealloc];
}

- (RMProjectedRect)boundingBox
{
    return boundingBox;
}

- (RMQuadTreeNode *)parentNode
{
    return parentNode;
}

- (void)addAnnotationToChildNodes:(RMAnnotation *)annotation
{
    RMProjectedRect projectedRect = annotation.projectedBoundingBox;
    if (RMProjectedRectContainsProjectedRect(northWestBoundingBox, projectedRect)) {
        if (!northWest) northWest = [[RMQuadTreeNode alloc] initWithParent:self forBoundingBox:northWestBoundingBox];
        [northWest addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(northEastBoundingBox, projectedRect)) {
        if (!northEast) northEast = [[RMQuadTreeNode alloc] initWithParent:self forBoundingBox:northEastBoundingBox];
        [northEast addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(southWestBoundingBox, projectedRect)) {
        if (!southWest) southWest = [[RMQuadTreeNode alloc] initWithParent:self forBoundingBox:southWestBoundingBox];
        [southWest addAnnotation:annotation];

    } else if (RMProjectedRectContainsProjectedRect(southEastBoundingBox, projectedRect)) {
        if (!southEast) southEast = [[RMQuadTreeNode alloc] initWithParent:self forBoundingBox:southEastBoundingBox];
        [southEast addAnnotation:annotation];

    } else {
        [annotations addObject:annotation];
        annotation.quadTreeNode = self;
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

        if ([annotations count] <= kMaxAnnotationsPerLeaf || boundingBox.size.width < (kMinimumQuadTreeElementWidth * 2.0))
            return;

        nodeType = nodeTypeNode;

        @synchronized (annotations) {
            for (RMAnnotation *annotationToMove in annotations)
            {
                [self addAnnotationToChildNodes:annotationToMove];
            }
            [annotations removeAllObjects];
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

    annotation.quadTreeNode = nil;
}

- (void)annotationDidChangeBoundingBox:(RMAnnotation *)annotation
{
    if (RMProjectedRectContainsProjectedRect(boundingBox, annotation.projectedBoundingBox))
        return;

    [self removeAnnotation:annotation];

    RMQuadTreeNode *nextParentNode = self;
    while ((nextParentNode = [nextParentNode parentNode]))
    {
        if (RMProjectedRectContainsProjectedRect(nextParentNode.boundingBox, annotation.projectedBoundingBox)) {
            [nextParentNode addAnnotationToChildNodes:annotation];
            break;
        }
    }
}

- (void)addAnnotationsInBoundingBox:(RMProjectedRect)aBoundingBox toMutableArray:(NSMutableArray *)someArray
{
    if (nodeType == nodeTypeLeaf) {
        @synchronized (annotations) {
            [someArray addObjectsFromArray:annotations];
        }
        return;
    }

    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, northWestBoundingBox))
        [northWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, northEastBoundingBox))
        [northEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, southWestBoundingBox))
        [southWest addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray];
    if (RMProjectedRectInterectsProjectedRect(aBoundingBox, southEastBoundingBox))
        [southEast addAnnotationsInBoundingBox:aBoundingBox toMutableArray:someArray];

    @synchronized (annotations) {
        for (RMAnnotation *annotation in annotations)
        {
            if (RMProjectedRectInterectsProjectedRect(aBoundingBox, annotation.projectedBoundingBox))
                [someArray addObject:annotation];
        }
    }
}

@end

#pragma mark -
#pragma mark RMQuadTree implementation

@implementation RMQuadTree

- (id)init
{
    if (!(self = [super init]))
        return nil;

    rootNode = [[RMQuadTreeNode alloc] initWithParent:nil forBoundingBox:[[RMProjection googleProjection] planetBounds]];

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
    rootNode = [[RMQuadTreeNode alloc] initWithParent:nil forBoundingBox:[[RMProjection googleProjection] planetBounds]];
}

#pragma mark -

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
{
    NSMutableArray *annotations = [NSMutableArray array];
    [rootNode addAnnotationsInBoundingBox:boundingBox toMutableArray:annotations];
    return annotations;
}

@end
