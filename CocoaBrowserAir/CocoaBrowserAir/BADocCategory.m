//
//  BADocCategory.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocCategory.h"
#import "BADocReference.h"
#import "BAClassLevelNode.h"
#import "NSString+Tokenizer.h"


@implementation BADocCategory


//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self) {
        self.title = title;
    }
    
    return self;
}

- (void)dealloc
{
    [mFilteredClassLevelNodes release];
    
    [super dealloc];
}


//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSString *)localizedTitle
{
    NSString *localizedStr = NSLocalizedString([@"CategoryName " stringByAppendingString:self.title], nil);
    if (![localizedStr hasPrefix:@"CategoryName "]) {
        return localizedStr;
    }
    return self.title;
}

- (NSArray *)childNodes
{
    if (mFilteredClassLevelNodes) {
        return mFilteredClassLevelNodes;
    }
    return super.childNodes;
}

- (NSInteger)childNodeCount
{
    if (mFilteredClassLevelNodes) {
        return [mFilteredClassLevelNodes count];
    }
    return super.childNodeCount;
}

- (id<BADocumentNode>)childNodeAtIndex:(NSInteger)index
{
    if (mFilteredClassLevelNodes) {
        return [mFilteredClassLevelNodes objectAtIndex:index];
    }
    return [super childNodeAtIndex:index];
}

- (NSInteger)indexOfChildNode:(id<BADocumentNode>)aChildNode
{
    if (mFilteredClassLevelNodes) {
        return [mFilteredClassLevelNodes indexOfObject:aChildNode];
    }
    return [super indexOfChildNode:aChildNode];
}

- (void)sortClassLevelNodes
{
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [mChildNodes sortUsingDescriptors:[NSArray arrayWithObject:desc]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"category<title=%@>", self.title];
}

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className
{
    for (BAClassLevelNode *classLevelNode in self.childNodes) {
        if ([classLevelNode.title isEqualToString:className] && classLevelNode.classLevelNodeType == BAClassLevelNodeTypeClass) {
            return classLevelNode;
        }
    }
    return nil;
}

- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className
{
    for (BAClassLevelNode *classLevelNode in self.childNodes) {
        if ([classLevelNode.title isEqualToString:className] && classLevelNode.classLevelNodeType == BAClassLevelNodeTypeProtocol) {
            return classLevelNode;
        }
    }
    return nil;
}


//-------------------------------------------------------------------------
#pragma mark ==== フィルタリング処理 ====
//-------------------------------------------------------------------------

- (void)setSearchString:(NSString *)str
{
    [mFilteredClassLevelNodes release];
    mFilteredClassLevelNodes = nil;
    
    if (str && [str length] > 0) {
        str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@" "];
        str = [str stringByReplacingOccurrencesOfString:@"\'" withString:@" "];
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([str length] > 0) {
            NSEnumerator *words = [str tokenize:@" "];
            NSArray *filteredNodes = self.childNodes;
            for (NSString *aWord in words) {
                NSString *wildCard = [NSString stringWithFormat:@"*%@*", aWord];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title like[cd] %@", wildCard];
                filteredNodes = [filteredNodes filteredArrayUsingPredicate:predicate];
            }
            if (filteredNodes != self.childNodes) {
                mFilteredClassLevelNodes = [filteredNodes retain];
            }
        }
    }
}

- (void)clearSearchString
{
    [mFilteredClassLevelNodes release];
    mFilteredClassLevelNodes = nil;
}

@end

