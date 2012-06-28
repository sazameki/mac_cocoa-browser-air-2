//
//  BADocumentNode.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BADocSet;


@protocol BADocumentNode

@property(readwrite, retain)    NSImage     *iconImage;
@property(readwrite, copy)      NSString    *title;
@property(readwrite, retain)    NSURL       *url;
@property(readonly)             NSString    *localizedTitle;
@property(readonly)             BADocSet    *docSet;
@property(readwrite, assign)    id<BADocumentNode>  parentNode;
@property(readonly)             NSArray     *childNodes;
@property(readonly)             NSInteger   childNodeCount;
@property(readwrite, copy)      NSString    *contentHTMLSource;

- (void)addTags:(NSArray *)tags;
- (BOOL)containsTag:(NSString *)tag;
- (BOOL)containsURL:(NSURL *)url;
- (id<BADocumentNode>)descendantNodeWithTag:(NSString *)tag;
- (id<BADocumentNode>)descendantNodeWithURL:(NSURL *)url;
- (id<BADocumentNode>)ancestorNodeOfClass:(Class)cls;

- (id<BADocumentNode>)childNodeAtIndex:(NSInteger)index;

- (void)addChildNode:(id<BADocumentNode>)aNode;

- (NSInteger)indexOfChildNode:(id<BADocumentNode>)aChildNode;
- (NSInteger)indexAtParentNode;

@end

