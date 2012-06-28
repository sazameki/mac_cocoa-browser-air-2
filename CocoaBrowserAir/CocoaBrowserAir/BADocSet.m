//
//  BADocSet.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocSet.h"
#import "SZJsonParser.h"
#import "NSURL+RelativeAddress.h"
#import "BADocFolder.h"
#import "BADocReference.h"


@interface BADocSet ()

- (NSURL *)findDocumentsFolderURLForBaseURL:(NSURL *)baseURL;

@end


@implementation BADocSet

//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self) {
        self.url = baseURL;
    }
    return self;
}


//-------------------------------------------------------------------------
#pragma mark ==== ドキュメントセット読み込みのヘルパメソッド ====
//-------------------------------------------------------------------------

- (BOOL)tryToLoad
{
    // 基本のパスの取得
    NSURL *documentsFolderURL = [self findDocumentsFolderURLForBaseURL:self.url];
    NSURL *navigationFolderURL = [documentsFolderURL URLByAppendingPathComponent:@"navigation"];
    
    // ドキュメント情報の取得
    NSURL *bookInfoURL = [navigationFolderURL URLByAppendingPathComponent:@"book.json"];        
    SZJsonParser *bookInfoParser = [[SZJsonParser alloc] initWithContentsOfURL:bookInfoURL encoding:NSUTF8StringEncoding];
    NSDictionary *bookInfo = [bookInfoParser parse];
    [bookInfoParser release];
    if (!bookInfo) {
#ifdef DEBUG
        NSLog(@"Cannot read book.json: %@", bookInfoURL);
#endif
        return NO;
    }
#ifdef DEBUG
    NSLog(@"Reading book.json OK");
#endif
    
    // ドキュメント名の取得
    NSString *extension = [self.url pathExtension];
    if (extension && [extension caseInsensitiveCompare:@"docset"] == NSOrderedSame) {
        NSString *title = [[self.url lastPathComponent] stringByDeletingPathExtension];
        if ([title hasPrefix:@"com.apple.adc.documentation.AppleSnowLeopard"]) {
            title = @"Mac OS X 10.6";
            mIconImage = [[NSImage imageNamed:@"macosx.png"] retain];
        } else if ([title hasPrefix:@"com.apple.adc.documentation.AppleLion"]) {
            title = @"Mac OS X 10.7";
            mIconImage = [[NSImage imageNamed:@"macosx.png"] retain];
        } else if ([title hasPrefix:@"com.apple.adc.documentation.AppleiOS"]) {
            NSString *iOSVersion = [[title substringFromIndex:[@"com.apple.adc.documentation.AppleiOS" length]] stringByDeletingPathExtension];
            iOSVersion = [iOSVersion stringByReplacingOccurrencesOfString:@"_" withString:@"."];
            title = [@"iOS " stringByAppendingString:iOSVersion];
            mIconImage = [[NSImage imageNamed:@"ios.png"] retain];
        } else {
            // Otherwise do nothing
        }
        mTitle = [title copy];
    } else {
        NSString *title = [bookInfo objectForKey:@"title"];
        if ([title hasPrefix:@"Mac OS X"]) {
            title = @"Mac OS X (Online)";
            mIconImage = [[NSImage imageNamed:@"macosx.png"] retain];
        } else if ([title hasPrefix:@"iOS"]) {
            title = @"iOS (Online)";
            mIconImage = [[NSImage imageNamed:@"ios.png"] retain];
        } else {
            title = [bookInfo objectForKey:@"title"];
        }
        mTitle = [title copy];
    }
    
    // ライブラリ情報の取得
    NSURL *libraryInfoURL = [navigationFolderURL URLByAppendingPathComponent:@"library.json"];
    SZJsonParser *libraryInfoParser = [[SZJsonParser alloc] initWithContentsOfURL:libraryInfoURL encoding:NSUTF8StringEncoding];
    NSDictionary *libraryInfo = [libraryInfoParser parse];
    [libraryInfoParser release];
    if (!libraryInfo) {
        return NO;
    }
    
    // ライブラリ情報の確認
    NSDictionary *columns = [libraryInfo objectForKey:@"columns"];
    if (!columns) {
        return NO;
    }
    int nameColumnIndex = [[columns objectForKey:@"name"] intValue];
    int urlColumnIndex = [[columns objectForKey:@"url"] intValue];
    
    // 各リファレンスの追加
    NSURL *mainRefsURL = [[NSBundle mainBundle] URLForResource:@"MainReferences" withExtension:@"plist"];
    NSArray *mainRefs = [NSArray arrayWithContentsOfURL:mainRefsURL];
    
    NSURL *baseRefsURL = [[NSBundle mainBundle] URLForResource:@"BaseReferences" withExtension:@"plist"];
    NSArray *baseRefs = [NSArray arrayWithContentsOfURL:baseRefsURL];
    
    BADocFolder *baseFolder = [[BADocFolder new] autorelease];
    baseFolder.title = @"Base";
    [baseFolder setParentNode:self];
    
    BADocFolder *mainFolder = [[BADocFolder new] autorelease];
    mainFolder.title = @"Main";
    [mainFolder setParentNode:self];
    
    BADocFolder *othersFolder = [[BADocFolder new] autorelease];
    othersFolder.title = @"Others";
    [othersFolder setParentNode:self];
    
    NSArray *documents = [libraryInfo objectForKey:@"documents"];
    for (NSArray *aDoc in documents) {
        NSUInteger itemCount = [aDoc count];
        if (nameColumnIndex >= itemCount || urlColumnIndex >= itemCount) {
            continue;
        }
        NSString *name = [aDoc objectAtIndex:nameColumnIndex];
        if (![name hasSuffix:@" Reference Collection"] && ![name hasSuffix:@" Framework Reference"]) {
            continue;
        }
        NSRange objcRange = [name rangeOfString:@" Objective-C" options:NSBackwardsSearch];
        if (objcRange.location != NSNotFound) {
            name = [name substringToIndex:objcRange.location];
        }

        NSString *urlStr = [aDoc objectAtIndex:urlColumnIndex];
        if (!urlStr || [urlStr length] == 0) {
            continue;
        }
        urlStr = [urlStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *pathPart = urlStr;
        
        NSRange sharpRange = [urlStr rangeOfString:@"#"];
        if (sharpRange.location != NSNotFound) {
            pathPart = [urlStr substringToIndex:sharpRange.location];
        }
        
        NSURL *url = [[navigationFolderURL URLByAppendingPathComponent:pathPart] standardizedURL];
        if ([[url pathExtension] caseInsensitiveCompare:@"html"] == NSOrderedSame) {
            url = [url URLByDeletingLastPathComponent];
        }
        
        BADocReference *aReference = [[BADocReference alloc] initWithContentsOfURL:url];
        if (aReference) {
            if (aReference.childNodeCount > 0) {
                if ([baseRefs containsObject:aReference.title]) {
                    [aReference setParentNode:baseFolder];
                    [baseFolder addChildNode:aReference];
                } else if ([mainRefs containsObject:aReference.title]) {
                    [aReference setParentNode:mainFolder];
                    [mainFolder addChildNode:aReference];
                } else {
                    [aReference setParentNode:othersFolder];
                    [othersFolder addChildNode:aReference];
                }
            } else {
#ifdef DEBUG
                NSLog(@"  Skipping Reference %@", url);
#endif
            }
            [aReference release];
        }
    }
    
    //[baseFolder sort];
    [mainFolder sort];
    [othersFolder sort];
    
    if ([baseFolder childNodeCount] > 0) {
        [self addChildNode:baseFolder];
    }
    if ([mainFolder childNodeCount] > 0) {
        [self addChildNode:mainFolder];
    }
    if ([othersFolder childNodeCount] > 0) {
        [self addChildNode:othersFolder];
    }
    
    return (self.childNodeCount > 0)? YES: NO;
}

- (NSURL *)findDocumentsFolderURLForBaseURL:(NSURL *)baseURL
{
    NSString *extension = [baseURL pathExtension];
    if (extension && [extension caseInsensitiveCompare:@"docset"] == NSOrderedSame) {
        return [baseURL URLByAppendingPathComponent:@"Contents/Resources/Documents"];
    } else {
        return baseURL;
    }
}


//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSString *)description
{
    return [NSString stringWithFormat:@"docset<title=%@>", self.title];
}

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className
{
    for (BADocFolder *aFolder in self.childNodes) {
        BAClassLevelNode *classNode = [aFolder findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className;
{
    for (BADocFolder *aFolder in self.childNodes) {
        BAClassLevelNode *classNode = [aFolder findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

@end

