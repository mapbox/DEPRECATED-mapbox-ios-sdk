//
//  RMQuadTree.h
//  MapView
//
//  Created by Thomas Rasch on 27.07.11.
//  Copyright 2011 Alpstein. All rights reserved.
//

#import "RMFoundation.h"

@class RMAnnotation;

typedef enum {
    nodeTypeLeaf,
    nodeTypeNode
} RMQuadTreeNodeType;

#pragma mark -
#pragma mark RMQuadTree nodes

@interface RMQuadTreeNode : NSObject
{
    RMProjectedRect boundingBox, northWestBoundingBox, northEastBoundingBox, southWestBoundingBox, southEastBoundingBox;
    NSMutableArray *annotations;
    RMQuadTreeNode *parentNode, *northWest, *northEast, *southWest, *southEast;
    RMQuadTreeNodeType nodeType;
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

@end

#pragma mark -
#pragma mark RMQuadTree

@interface RMQuadTree : NSObject
{
    RMQuadTreeNode *rootNode;
}

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)removeAllObjects;

// Returns all annotations that are either inside of or intersect with boundingBox
- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox;

@end
