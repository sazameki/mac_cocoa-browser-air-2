//
//  BACategoryLevelNode.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAGroupLevelNode.h"
#import "BAClassLevelNode.h"
#import "BAMethodLevelNode.h"
#import "NSString+Tokenizer.h"


@implementation BAGroupLevelNode


//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (void)dealloc
{
    [mFilteredMethodLevelNodes release];

    [super dealloc];
}


//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSInteger)childNodeCount
{
    if (mFilteredMethodLevelNodes) {
        return [mFilteredMethodLevelNodes count];
    }
    return [super childNodeCount];
}

- (id<BADocumentNode>)childNodeAtIndex:(NSInteger)index
{
    if (mFilteredMethodLevelNodes) {
        return [mFilteredMethodLevelNodes objectAtIndex:index];
    }
    return [super childNodeAtIndex:index];
}

- (NSInteger)indexOfChildNode:(id<BADocumentNode>)aChildNode
{
    if (mFilteredMethodLevelNodes) {
        return [mFilteredMethodLevelNodes indexOfObject:aChildNode];
    }
    return [super indexOfChildNode:aChildNode];
}

- (NSString *)localizedTitle
{
    NSString *title = self.title;
    NSString *localizedStr = NSLocalizedString([@"GroupTitle " stringByAppendingString:title], nil);
    if (![localizedStr hasPrefix:@"GroupTitle "]) {
        return localizedStr;
    }
    return title;
}

- (BAMethodLevelNode *)findNodeForMethodWithName:(NSString *)methodName
{
    for (BAMethodLevelNode *methodLevelNode in self.childNodes) {
        if ([[methodLevelNode.title substringFromIndex:2] isEqualToString:methodName]) {
            return methodLevelNode;
        }
    }
    return nil;
}

- (BAMethodLevelNode *)findNodeForPropertyWithName:(NSString *)methodName
{
    for (BAMethodLevelNode *methodLevelNode in self.childNodes) {
        if ([methodLevelNode.title isEqualToString:methodName]) {
            return methodLevelNode;
        }
    }
    return nil;
}

- (BAMethodLevelNode *)findNodeForConstantWithName:(NSString *)methodName
{
    for (BAMethodLevelNode *methodLevelNode in self.childNodes) {
        if ([methodLevelNode.title isEqualToString:methodName]) {
            return methodLevelNode;
        }
    }
    return nil;
}


//-------------------------------------------------------------------------
#pragma mark ==== フィルタリング処理 ====
//-------------------------------------------------------------------------

- (void)setSearchString:(NSString *)str
{
    [mFilteredMethodLevelNodes release];
    mFilteredMethodLevelNodes = nil;
    
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
                mFilteredMethodLevelNodes = [filteredNodes retain];
            }
        }
    }
}

- (void)clearSearchString
{
    [mFilteredMethodLevelNodes release];
    mFilteredMethodLevelNodes = nil;
}

@end

