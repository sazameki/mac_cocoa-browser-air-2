//
//  BAReferenceLibrary.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAReferenceLibrary.h"
#import "NSURL+RelativeAddress.h"
#import "BAAppDelegate.h"
#import "BADocumentNode.h"
#import "BADocSet.h"
#import "BADocFolder.h"
#import "BADocReference.h"
#import "BADocCategory.h"
#import "BAClassLevelNode.h"
#import "BAMethodLevelNode.h"


static BAReferenceLibrary *sInstance = nil;


@interface BAJumpPair : NSObject {
    NSString    *mPrefix;
    SEL         mSelector;
}

@property(readonly) NSString    *prefix;
@property(readonly) SEL         selector;

+ (BAJumpPair *)jumpPairWithPrefix:(NSString *)prefix selector:(SEL)selector;
- (id)initWithPrefix:(NSString *)prefix selector:(SEL)selector;

@end


@implementation BAJumpPair

@synthesize prefix = mPrefix;
@synthesize selector = mSelector;

+ (BAJumpPair *)jumpPairWithPrefix:(NSString *)prefix selector:(SEL)selector
{
    return [[[BAJumpPair alloc] initWithPrefix:prefix selector:selector] autorelease];
}

- (id)initWithPrefix:(NSString *)prefix selector:(SEL)selector
{
    self = [super init];
    if (self) {
        mPrefix = [prefix retain];
        mSelector = selector;
    }
    return self;
}

- (void)dealloc
{
    [mPrefix release];
    [super dealloc];
}

@end


@interface BAReferenceLibrary()

- (void)checkOnlineReferences;
- (void)checkOfflineReferences;
- (void)checkDocSetFilesAtURL:(NSURL *)url;
- (void)checkDocSetAtURL:(NSURL *)url;
- (void)checkAllPreCreatedDocSets;

@end


@implementation BAReferenceLibrary

+ (BAReferenceLibrary *)sharedInstance
{
    if (!sInstance) {
        sInstance = [[BAReferenceLibrary alloc] init];
    }
    return sInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        mIsCheckingEnvironment = NO;
        mPreCreatedDocSets = [[NSMutableArray array] retain];
        mDocSets = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc
{
    [mDocSets release];
    [mPreCreatedDocSets release];

    [super dealloc];
}

- (BOOL)isCheckingEnvironment
{
    return mIsCheckingEnvironment;
}

- (void)checkEnvironment
{
    mIsCheckingEnvironment = YES;
    [NSThread detachNewThreadSelector:@selector(checkEnvironmentProc:) toTarget:self withObject:nil];
}

- (void)checkEnvironmentProc:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSUserDefaultsController *defController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUserDefaults *defaults = [defController defaults];

    if ([defaults boolForKey:@"useOfflineDocSets"]) {
        [self checkOfflineReferences];
    }
    if ([defaults boolForKey:@"useOnlineDocSets"]) {
        [self checkOnlineReferences];
    }
    [[BAAppDelegate sharedInstance] setCheckTargetCount:[mPreCreatedDocSets count]];
    [self checkAllPreCreatedDocSets];
    
    mIsCheckingEnvironment = NO;
    [[BAAppDelegate sharedInstance] finishedCheckingEnvironment];

    [pool release];
}

- (void)checkOnlineReferences
{
    [self checkDocSetAtURL:[NSURL URLWithString:@"http://developer.apple.com/library/ios/"]];
    [self checkDocSetAtURL:[NSURL URLWithString:@"http://developer.apple.com/library/mac/"]];
}

- (void)checkOfflineReferences
{
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Library/Developer/Documentation/DocSets/"]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Library/Developer/Shared/Documentation/DocSets/"]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Developer/Documentation/DocSets/"]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets"]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets"]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:[@"~/Library/Developer/Shared/Documentation/DocSets" stringByExpandingTildeInPath]]];
    [self checkDocSetFilesAtURL:[NSURL fileURLWithPath:@"/Applications/Xcode.app/Contents/Developer/Documentation/DocSets"]];
}

- (void)checkDocSetFilesAtURL:(NSURL *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtURL:url
                                       includingPropertiesForKeys:nil
                                                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                     errorHandler:^(NSURL *url, NSError *error) { return NO; }];
    
    NSURL *aFileURL;
    while ((aFileURL = (NSURL *)[dirEnum nextObject])) {
        NSString *extension = [aFileURL pathExtension];
        if ([extension caseInsensitiveCompare:@"docset"] == NSOrderedSame) {
            [self checkDocSetAtURL:aFileURL];
        }
    }
}

- (void)checkDocSetAtURL:(NSURL *)url
{
    BADocSet *docSet = [[BADocSet alloc] initWithBaseURL:url];
    [mPreCreatedDocSets addObject:docSet];
}

- (void)checkAllPreCreatedDocSets
{
    for (BADocSet *docSet in mPreCreatedDocSets) {
#ifdef DEBUG
        NSLog(@"  Try DocSet at %@", docSet.url);
#endif
        if ([docSet tryToLoad]) {
            BOOL hasSameDocSet = NO;
            for (BADocSet *aDocSet in mDocSets) {
                if ([aDocSet.title isEqualToString:docSet.title]) {
                    hasSameDocSet = YES;
                    break;
                }
            }
            if (!hasSameDocSet) {
                [mDocSets addObject:docSet];
            }
        }
        [[BAAppDelegate sharedInstance] incrementCheckedTargetCount];
    }
    [mPreCreatedDocSets release];
    mPreCreatedDocSets = nil;
    
    [mDocSets sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *title1 = ((BADocSet *)obj1).title;
        NSString *title2 = ((BADocSet *)obj2).title;
        if ([title1 hasPrefix:@"iOS"] && [title2 hasPrefix:@"Mac"]) {
            return NSOrderedAscending;
        } else if ([title1 hasPrefix:@"Mac"] && [title2 hasPrefix:@"iOS"]) {
            return NSOrderedDescending;
        } else {
            return [title2 localizedCaseInsensitiveCompare:title1];
        }
    }];
}

- (NSInteger)docSetCount
{
    return [mDocSets count];
}

- (BADocSet *)docSetAtIndex:(NSInteger)index
{
    return [mDocSets objectAtIndex:index];
}


//-------------------------------------------------------------------------
#pragma mark ==== リンクの処理 ====
//-------------------------------------------------------------------------

- (NSArray *)nodesToNode:(id<BADocumentNode>)node
{
    if (!node) {
        return nil;
    }
    NSMutableArray *ret = [NSMutableArray array];
    while (node) {
        [ret insertObject:node atIndex:0];
        node = [node parentNode];
    }
    return ret;
}

- (BAClassLevelNode *)nodeForClassWithName:(NSString *)className urlStr:(NSString *)urlStr startNode:(id<BADocumentNode>)startNode
{
    ///// 1. 同じカテゴリ内で調べる。
    NSObject<BADocumentNode> *aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocCategory class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocCategory *)aNode findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 2. 同じリファレンス（フレームワーク）内で調べる。
    aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocReference class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocReference *)aNode findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 3. 同じフォルダ内で調べる。
    aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocFolder class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocFolder *)aNode findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 4. 同じドキュメントセット内で調べる。
    BADocSet *docSet = [startNode docSet];
    if (docSet) {
        BAClassLevelNode *classNode = [docSet findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    return nil;
}

- (BAClassLevelNode *)nodeForProtocolWithName:(NSString *)className urlStr:(NSString *)urlStr startNode:(id<BADocumentNode>)startNode
{
    ///// 1. 同じカテゴリ内で調べる。
    NSObject<BADocumentNode> *aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocCategory class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocCategory *)aNode findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 2. 同じリファレンス（フレームワーク）内で調べる。
    aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocReference class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocReference *)aNode findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 3. 同じフォルダ内で調べる。
    aNode = (NSObject<BADocumentNode> *)startNode;
    while (aNode) {
        if ([aNode isKindOfClass:[BADocFolder class]]) {
            break;
        }
        aNode = (NSObject<BADocumentNode> *)aNode.parentNode;
    }
    if (aNode) {
        BAClassLevelNode *classNode = [(BADocFolder *)aNode findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    ///// 4. 同じドキュメントセット内で調べる。
    BADocSet *docSet = [startNode docSet];
    if (docSet) {
        BAClassLevelNode *classNode = [docSet findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    
    return nil;
}

- (NSString *)lastComponentOfParameter:(NSString *)parameter
{
    NSRange separatorRange = [parameter rangeOfString:@"/" options:NSBackwardsSearch];
    if (separatorRange.location == NSNotFound) {
        return nil;
    }
    return [parameter substringFromIndex:separatorRange.location+1];
}

- (void)getComponentsFromParameter:(NSString *)parameter lastComponent:(NSString **)last prevComponent:(NSString **)prev
{
    *last = nil;
    *prev = nil;

    NSRange lastSeparatorRange = [parameter rangeOfString:@"/" options:NSBackwardsSearch];
    if (lastSeparatorRange.location == NSNotFound) {
        return;
    }
    NSRange prevSeparatorRange = [parameter rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, lastSeparatorRange.location)];
    if (prevSeparatorRange.location == NSNotFound) {
        return;
    }
    
    *last = [parameter substringFromIndex:lastSeparatorRange.location+1];
    *prev = [parameter substringWithRange:NSMakeRange(prevSeparatorRange.location+1, lastSeparatorRange.location-prevSeparatorRange.location-1)];
}

// #/apple_ref/occ/cl/
- (NSArray *)nodesToClassURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *className = [self lastComponentOfParameter:parameter];
    return [self nodesToNode:[self nodeForClassWithName:className urlStr:baseURLStr startNode:startNode]];
}

// #/apple_ref/occ/intf/
- (NSArray *)nodesToProtocolURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *protocolName = [self lastComponentOfParameter:parameter];
    return [self nodesToNode:[self nodeForProtocolWithName:protocolName urlStr:baseURLStr startNode:startNode]];
}

// #/apple_ref/occ/clm/
- (NSArray *)nodesToClassMethodURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *methodName, *className;
    [self getComponentsFromParameter:parameter lastComponent:&methodName prevComponent:&className];

    BAClassLevelNode *classNode = [self nodeForClassWithName:className urlStr:baseURLStr startNode:startNode];
    if (classNode) {
        if (!classNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [classNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *methodNode = [classNode findNodeForClassMethodWithName:methodName];
        return [self nodesToNode:methodNode];
    }
    return nil;
}

// #/apple_ref/occ/intfcm/
- (NSArray *)nodesToProtocolClassMethodURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *methodName, *protocolName;
    [self getComponentsFromParameter:parameter lastComponent:&methodName prevComponent:&protocolName];

    BAClassLevelNode *protocolNode = [self nodeForProtocolWithName:protocolName urlStr:baseURLStr startNode:startNode];
    if (protocolNode) {
        if (!protocolNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [protocolNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *methodNode = [protocolNode findNodeForClassMethodWithName:methodName];
        return [self nodesToNode:methodNode];
    }
    return nil;
}

// #/apple_ref/occ/instm/
- (NSArray *)nodesToInstanceMethodURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *methodName, *className;
    [self getComponentsFromParameter:parameter lastComponent:&methodName prevComponent:&className];
    
    BAClassLevelNode *classNode = [self nodeForClassWithName:className urlStr:baseURLStr startNode:startNode];
    if (classNode) {
        if (!classNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [classNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *methodNode = [classNode findNodeForInstanceMethodWithName:methodName];
        return [self nodesToNode:methodNode];
    }
    return nil;
}

// #/apple_ref/occ/intfm/
- (NSArray *)nodesToProtocolMethodURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *methodName, *protocolName;
    [self getComponentsFromParameter:parameter lastComponent:&methodName prevComponent:&protocolName];
    
    BAClassLevelNode *protocolNode = [self nodeForProtocolWithName:protocolName urlStr:baseURLStr startNode:startNode];
    if (protocolNode) {
        if (!protocolNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [protocolNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *methodNode = [protocolNode findNodeForInstanceMethodWithName:methodName];
        return [self nodesToNode:methodNode];
    }
    return nil;
}

// #/apple_ref/occ/instp/
- (NSArray *)nodesToInstancePropertyURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *propertyName, *className;
    [self getComponentsFromParameter:parameter lastComponent:&propertyName prevComponent:&className];

    BAClassLevelNode *classNode = [self nodeForClassWithName:className urlStr:baseURLStr startNode:startNode];
    if (classNode) {
        if (!classNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [classNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *propertyNode = [classNode findNodeForPropertyWithName:propertyName];
        return [self nodesToNode:propertyNode];
    }
    return nil;
}

// #/apple_ref/occ/intfp/
- (NSArray *)nodesToProtocolPropertyURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *propertyName, *protocolName;
    [self getComponentsFromParameter:parameter lastComponent:&propertyName prevComponent:&protocolName];

    BAClassLevelNode *protocolNode = [self nodeForProtocolWithName:protocolName urlStr:baseURLStr startNode:startNode];
    if (protocolNode) {
        if (!protocolNode.hasLoaded) {
            [[BAAppDelegate sharedInstance] startLoadingContent];
            [protocolNode loadContent];
            [[BAAppDelegate sharedInstance] finishLoadingContent];
        }
        BAMethodLevelNode *propertyNode = [protocolNode findNodeForPropertyWithName:propertyName];
        return [self nodesToNode:propertyNode];
    }
    return nil;
}

// #/apple_ref/c/func/
- (NSArray *)nodesToFunctionURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Function: %@", parameter);
#endif
    return nil;
}

// #/apple_ref/c/data/
- (NSArray *)nodesToGlobalVariableURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *constantName = [self lastComponentOfParameter:parameter];

    NSObject<BADocumentNode> *node = (NSObject<BADocumentNode> *)startNode;
    while (node) {
        if ([node isKindOfClass:[BAClassLevelNode class]]) {
            break;
        }
        node = (NSObject<BADocumentNode> *)node.parentNode;
    }
    
    if (node) {
        BAMethodLevelNode *methodLevelNode = [(BAClassLevelNode *)node findNodeForConstantWithName:constantName];
        return [self nodesToNode:methodLevelNode];
    }
    return nil;
}

// #/apple_ref/c/macro/
- (NSArray *)nodesToMacroURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Macro: %@", parameter);
#endif
    return nil;
}

// #/apple_ref/c/econst/
- (NSArray *)nodesToEnumURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Enum: %@", parameter);
#endif
    return nil;
}

// 定数グループ (#/apple_ref/c/constant_group/)
- (NSArray *)nodesToConstantGroupURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Constant Group: %@", parameter);
#endif
    return nil;
}

// 構造体 / 定数 (#/apple_ref/c/tdef/)
- (NSArray *)nodesToStructureOrConstantURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Structure/Constant: %@", parameter);
#endif
    return nil;
}

// クラス / 構造体 / 定数 (#/apple_ref/c/tdef/)
- (NSArray *)nodesToClassOrStructureOrConstantURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
    NSString *targetName = [self lastComponentOfParameter:parameter];

    // 1. クラスの取得を試してみる
    BAClassLevelNode *classNode = [self nodeForClassWithName:targetName urlStr:baseURLStr startNode:startNode];
    if (classNode) {
        return [self nodesToNode:classNode];
    }

    // 2. 構造体の取得を試してみる

    // 3. 定数の取得を試してみる

    NSLog(@"Class/Structure/Constant: %@", parameter);
    return nil;
}

// #/apple_ref/doc/uid/DTS
- (NSArray *)nodesToSampleCodeURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Sample Code: %@", parameter);
#endif
    return nil;
}

// #/apple_ref/doc/uid/TP
- (NSArray *)nodesToConstantsOrDocumentURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Constants / Document: %@", parameter);
#endif
    return nil;
}

// #/apple_ref/doc/uid/
- (NSArray *)nodesToStructureOrDocumentURLStr:(NSString *)baseURLStr parameter:(NSString *)parameter startNode:(id<BADocumentNode>)startNode
{
#ifdef DEBUG
    NSLog(@"Constants / Document: %@", parameter);
#endif
    return nil;
}

- (NSArray *)nodesToURL:(NSURL *)url startNode:(id<BADocumentNode>)startNode
{
    NSString *urlStr = [url absoluteString];
    NSRange sharpRange = [urlStr rangeOfString:@"#" options:NSBackwardsSearch];
    
    NSMutableArray *jumpPairs = [NSMutableArray array];
    
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/cl/"      selector:@selector(nodesToClassURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/intf/"    selector:@selector(nodesToProtocolURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/clm/"     selector:@selector(nodesToClassMethodURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/intfcm/"  selector:@selector(nodesToProtocolClassMethodURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/instm/"   selector:@selector(nodesToInstanceMethodURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/intfm/"   selector:@selector(nodesToProtocolMethodURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/instp/"   selector:@selector(nodesToInstancePropertyURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/occ/intfp/"   selector:@selector(nodesToProtocolPropertyURLStr:parameter:startNode:)]];
    
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/func/"      selector:@selector(nodesToFunctionURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/data/"      selector:@selector(nodesToGlobalVariableURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/macro/"     selector:@selector(nodesToMacroURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/econst/"    selector:@selector(nodesToEnumURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/constant_group/"    selector:@selector(nodesToConstantGroupURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/c/tdef/"      selector:@selector(nodesToStructureOrConstantURLStr:parameter:startNode:)]];
    
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/doc/c_ref/"   selector:@selector(nodesToClassOrStructureOrConstantURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/doc/uid/DTS"  selector:@selector(nodesToSampleCodeURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/doc/uid/TP"   selector:@selector(nodesToConstantsOrDocumentURLStr:parameter:startNode:)]];
    [jumpPairs addObject:[BAJumpPair jumpPairWithPrefix:@"#/apple_ref/doc/uid/"     selector:@selector(nodesToStructureOrDocumentURLStr:parameter:startNode:)]];
    
    // URLに「#」が含まれていなければ、同じURLをもつ先に単純にジャンプする
    if (sharpRange.location == NSNotFound) {
        id<BADocumentNode> leafNode = [[startNode docSet] descendantNodeWithURL:url];
        if (!leafNode) {
            return nil;
        }
        NSMutableArray *ret = [NSMutableArray array];
        while (leafNode) {
            [ret insertObject:leafNode atIndex:0];
            leafNode = [leafNode parentNode];
        }
        return ret;
    }
    // URLに「#」が含まれていれば内容を解釈して、条件からジャンプ先を見つける
    else {
        NSString *baseURLStr = [urlStr substringToIndex:sharpRange.location];
        NSString *parameter = [urlStr substringFromIndex:sharpRange.location];
        
        // TODO: 「http:/」が含まれている場合、外部へのジャンプ。
        if ([parameter rangeOfString:@"http:/"].location != NSNotFound) {
            NSLog(@"Outside: %@", parameter);
        } else {
            for (BAJumpPair *aPair in jumpPairs) {
                if ([parameter hasPrefix:aPair.prefix]) {
                    NSMethodSignature *signature = [self methodSignatureForSelector:aPair.selector];
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                    [invocation setTarget:self];
                    [invocation setSelector:aPair.selector];
                    [invocation setArgument:&baseURLStr atIndex:2];
                    [invocation setArgument:&parameter atIndex:3];
                    [invocation setArgument:&startNode atIndex:4];
                    [invocation invoke];
                    NSArray *ret = nil;
                    [invocation getReturnValue:&ret];
                    return ret;
                }
            }
        }
        
        NSBeep();
        NSLog(@"parameter: [%@]", parameter);
        
        return nil;
    }
}

@end

