//
//  RMQuadTree.h
//  MapView
//
//  Created by Thomas Rasch on 27.07.11.
//  Copyright 2011 Alpstein. All rights reserved.
//

#import "RMFoundation.h"

@class RMAnnotation, RMMapView;

typedef enum {
    nodeTypeLeaf,
    nodeTypeNode
} RMQuadTreeNodeType;

#define kRMClusterAnnotationTypeName @"RMClusterAnnotation"

#pragma mark -
#pragma mark RMQuadTree nodes

@interface RMQuadTreeNode : NSObject
{
    RMProjectedRect boundingBox, northWestBoundingBox, northEastBoundingBox, southWestBoundingBox, southEastBoundingBox;
    NSMutableArray *annotations;
    RMQuadTreeNode *parentNode, *northWest, *northEast, *southWest, *southEast;
    RMQuadTreeNodeType nodeType;
    RMMapView *mapView;

    RMAnnotation *cachedClusterAnnotation;
    NSArray *cachedClusterEnclosedAnnotations;
    NSMutableArray *cachedEnclosedAnnotations, *cachedUnclusteredAnnotations;
}

@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) RMQuadTreeNodeType nodeType;

@property (nonatomic, readonly) RMProjectedRect boundingBox;
@property (nonatomic, readonly) RMProjectedRect northWestBoundingBox;
@property (nonatomic, readonly) RMProjectedRect northEastBoundingBox;
@property (nonatomic, readonly) RMProjectedRect southWestBoundingBox;
@property (nonatomic, readonly) RMProjectedRect southEastBoundingBox;

@property (nonatomic, readonly) RMQuadTreeNode *parentNode;
@property (nonatomic, readonly) RMQuadTreeNode *northWest;
@property (nonatomic, readonly) RMQuadTreeNode *northEast;
@property (nonatomic, readonly) RMQuadTreeNode *southWest;
@property (nonatomic, readonly) RMQuadTreeNode *southEast;

@property (nonatomic, readonly) RMAnnotation *clusterAnnotation;
@property (nonatomic, readonly) NSArray *clusteredAnnotations;

// Operations on this node and all subnodes
@property (nonatomic, readonly) NSArray *enclosedAnnotations;
@property (nonatomic, readonly) NSArray *unclusteredAnnotations;

@end

#pragma mark -
#pragma mark RMQuadTree

@interface RMQuadTree : NSObject
{
    RMQuadTreeNode *rootNode;
    RMMapView *mapView;
}

- (id)initWithMapView:(RMMapView *)aMapView;

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)removeAllObjects;

// Returns all annotations that are either inside of or intersect with boundingBox
- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox;
- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox
               createClusterAnnotations:(BOOL)createClusterAnnotations
               withProjectedClusterSize:(RMProjectedSize)clusterSize
          andProjectedClusterMarkerSize:(RMProjectedSize)clusterMarkerSize
                      findGravityCenter:(BOOL)findGravityCenter;

@end
