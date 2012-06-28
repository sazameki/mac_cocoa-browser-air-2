//
//  BADocumentNodeImpl.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"
#import "BADocSet.h"
#import "NSURL+RelativeAddress.h"
#import "BAAppDelegate.h"


@implementation BADocumentNodeImpl

@synthesize title = mTitle;
@synthesize url = mURL;
@synthesize iconImage = mIconImage;
@synthesize parentNode = mParentNode;
@synthesize contentHTMLSource = mContentHTMLSource;

- (id)init
{
    self = [super init];
    if (self) {
        mTags = [[NSMutableArray array] retain];
        mChildNodes = [[NSMutableArray array] retain];
        
        [[BAAppDelegate sharedInstance] incrementAddedNodeCount];
    }
    
    return self;
}

- (void)dealloc
{
    [mTitle release];
    [mURL release];
    [mIconImage release];
    [mTags release];
    [mChildNodes release];
    [mContentHTMLSource release];

    [super dealloc];
}

- (BADocSet *)docSet
{
    return (BADocSet *)[self ancestorNodeOfClass:[BADocSet class]];
}

- (void)addTags:(NSArray *)tags
{
    for (NSString *aTag in tags) {
        [mTags addObject:[NSString stringWithString:aTag]];
    }
}

- (BOOL)containsTag:(NSString *)tag
{
    NSLog(@"<find>\"%@\"", tag);
    for (NSString *aTag in mTags) {
        NSLog(@"  tag:\"%@\"", aTag);
    }
    NSLog(@"----");
    return NO;
}

- (BOOL)containsURL:(NSURL *)url
{
    NSURL *myURL = [mURL numataStandardizedURL];
    return [[url absoluteString] hasPrefix:[myURL absoluteString]];
}

- (id<BADocumentNode>)descendantNodeWithTag:(NSString *)tag
{
    if ([self containsTag:tag]) {
        return self;
    }
    for (id<BADocumentNode> aChildNode in mChildNodes) {
        id<BADocumentNode> node = [aChildNode descendantNodeWithTag:tag];
        if (node) {
            return node;
        }
    }
    return nil;
}

- (id<BADocumentNode>)descendantNodeWithURL:(NSURL *)url
{
    if ([self containsURL:url]) {
        return self;
    }
    for (id<BADocumentNode> aChildNode in mChildNodes) {
        id<BADocumentNode> node = [aChildNode descendantNodeWithURL:url];
        if (node) {
            return node;
        }
    }
    return nil;
}

- (id<BADocumentNode>)ancestorNodeOfClass:(Class)cls
{
    if ([self isMemberOfClass:cls]) {
        return self;
    }
    if (self.parentNode) {
        return [self.parentNode ancestorNodeOfClass:cls];
    }
    return nil;
}

- (NSInteger)childNodeCount
{
    return [mChildNodes count];
}

- (id<BADocumentNode>)childNodeAtIndex:(NSInteger)index
{
#ifdef DEBUG
    assert(index >= 0 && index < [mChildNodes count]);
#endif
    return [mChildNodes objectAtIndex:index];
}

- (void)addChildNode:(id<BADocumentNode>)aNode
{
    [mChildNodes addObject:aNode];
}

- (NSArray *)childNodes
{
    return mChildNodes;
}

- (NSInteger)indexOfChildNode:(id<BADocumentNode>)aChildNode
{
    return [mChildNodes indexOfObject:aChildNode];
}

- (NSInteger)indexAtParentNode
{
    if (!self.parentNode) {
        return -1;
    }
    return [self.parentNode indexOfChildNode:self];
}

- (NSString *)localizedTitle
{
    return mTitle;
}

@end

