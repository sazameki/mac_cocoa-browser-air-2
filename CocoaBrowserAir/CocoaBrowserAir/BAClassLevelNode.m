//
//  BAClassLevelNode.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAClassLevelNode.h"
#import "BADocCategory.h"
#import "BAGroupLevelNode.h"
#import "BAMethodLevelNode.h"


@implementation BAClassLevelNode

@synthesize hasLoaded = mHasLoaded;
@synthesize classLevelNodeType = mClassLevelNodeType;


//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (id)init
{
    self = [super init];
    if (self) {
        mHasLoaded = NO;
    }
    
    return self;
}


//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (void)setTitle:(NSString *)title
{
    if ([title hasSuffix:@" Class Reference"]) {
        title = [title substringToIndex:[title length]-[@" Class Reference" length]];
        mIconImage = [[NSImage imageNamed:@"class-icon.png"] retain];
    }
    else if ([title hasSuffix:@" Class"]) {
        title = [title substringToIndex:[title length]-[@" Class" length]];
        mIconImage = [[NSImage imageNamed:@"class-icon.png"] retain];
    }
    else if ([title hasSuffix:@" Class Objective-C Reference"]) {
        title = [title substringToIndex:[title length]-[@" Class Objective-C Reference" length]];
        mIconImage = [[NSImage imageNamed:@"class-icon.png"] retain];
    }
    else if ([title hasSuffix:@" Protocol Reference"]) {
        title = [title substringToIndex:[title length]-[@" Protocol Reference" length]];
        mIconImage = [[NSImage imageNamed:@"protocol-icon.png"] retain];
    }
    else if ([title hasSuffix:@" Service Reference"]) {
        title = [title substringToIndex:[title length]-[@" Service Reference" length]];
    }
    else if ([title hasSuffix:@" Reference"]) {
        title = [title substringToIndex:[title length]-[@" Reference" length]];
    }
    
    if ([title hasSuffix:@" Additions"]) {
        mIconImage = [[NSImage imageNamed:@"class-icon.png"] retain];
    }

    super.title = title;
}

- (void)loadContent
{
    if (self.hasLoaded) {
        NSLog(@"Already loaded: %@", self.title);
        return;
    }

    BAClassHTMLParser *parser = [[BAClassHTMLParser alloc] initWithClassLevelNode:self];
    [parser parse];
    [parser release];
    
    mHasLoaded = YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"class-level<title=%@>", self.title];
}

- (BAMethodLevelNode *)findNodeForInstanceMethodWithName:(NSString *)methodName
{
    for (BAGroupLevelNode *groupLevelNode in self.childNodes) {
        if ([groupLevelNode.title hasPrefix:@"Instance Method"]) {
            return [groupLevelNode findNodeForMethodWithName:methodName];
        }
    }
    return nil;
}

- (BAMethodLevelNode *)findNodeForClassMethodWithName:(NSString *)methodName
{
    for (BAGroupLevelNode *groupLevelNode in self.childNodes) {
        if ([groupLevelNode.title hasPrefix:@"Class Method"]) {
            return [groupLevelNode findNodeForMethodWithName:methodName];
        }
    }
    return nil;
}

- (BAMethodLevelNode *)findNodeForPropertyWithName:(NSString *)methodName
{
    for (BAGroupLevelNode *groupLevelNode in self.childNodes) {
        if ([groupLevelNode.title hasPrefix:@"Propert"]) {
            return [groupLevelNode findNodeForPropertyWithName:methodName];
        }
    }
    return nil;
}

- (BAMethodLevelNode *)findNodeForConstantWithName:(NSString *)methodName
{
    for (BAGroupLevelNode *groupLevelNode in self.childNodes) {
        if ([groupLevelNode.title hasPrefix:@"Const"]) {
            return [groupLevelNode findNodeForConstantWithName:methodName];
        }
    }
    return nil;
}

@end

