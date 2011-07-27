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

@interface RMQuadTreeNode : NSObject
{
    RMProjectedRect boundingBox, northWestBoundingBox, northEastBoundingBox, southWestBoundingBox, southEastBoundingBox;
    NSMutableArray *annotations;
    RMQuadTreeNode *parentNode, *northWest, *northEast, *southWest, *southEast;
    RMQuadTreeNodeType nodeType;
}

@property (nonatomic, readonly) RMProjectedRect boundingBox;
@property (nonatomic, readonly) RMQuadTreeNode *parentNode;

@end

@interface RMQuadTree : NSObject
{
    RMQuadTreeNode *rootNode;
}

- (void)addAnnotation:(RMAnnotation *)annotation;
- (void)removeAnnotation:(RMAnnotation *)annotation;

- (void)removeAllObjects;

#pragma mark -

- (NSArray *)annotationsInProjectedRect:(RMProjectedRect)boundingBox;

@end
