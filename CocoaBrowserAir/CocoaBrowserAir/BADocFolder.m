//
//  BADocFolder.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocFolder.h"
#import "BADocSet.h"
#import "BADocReference.h"


@implementation BADocFolder

//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSString *)localizedTitle
{
    NSString *title = self.title;
    NSString *localizedStr = NSLocalizedString([@"Folder " stringByAppendingString:title], nil);
    if (![localizedStr hasPrefix:@"Folder "]) {
        return localizedStr;
    }
    return title;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"folder<title=%@>", mTitle];
}

- (void)addChildNode:(id<BADocumentNode>)aNode
{
    if ([aNode.title isEqualToString:@"Foundation"]) {
        [mChildNodes insertObject:aNode atIndex:0];
    } else {
        [mChildNodes addObject:aNode];
    }
}

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className
{
    for (BADocReference *aReference in self.childNodes) {
        BAClassLevelNode *classNode = [aReference findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className
{
    for (BADocReference *aReference in self.childNodes) {
        BAClassLevelNode *classNode = [aReference findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

- (void)sort
{
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [mChildNodes sortUsingDescriptors:[NSArray arrayWithObject:desc]];
}

@end

