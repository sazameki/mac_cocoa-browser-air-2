//
//  BADocReference.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocReference.h"
#import "SZJsonParser.h"
#import "BADocSet.h" 
#import "BAClassLevelNode.h"
#import "BADocCategory.h"
#import "BAReferenceIndexHTMLParser.h"
#import "BAReferenceUnderbarIndexHTMLParser.h"


@interface BADocReference()

- (BOOL)tryGetClassInformationFromIndexHTML;
- (BOOL)tryGetClassInformationFromUnderbarIndexHTML;
- (BOOL)tryGetClassInformationFromBookJSON;

@end


@implementation BADocReference


//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (id)initWithContentsOfURL:(NSURL *)baseURL
{
    self = [super init];
    if (self) {
        self.url = baseURL;
        
        if (![self tryGetClassInformationFromIndexHTML]) {
            if (![self tryGetClassInformationFromUnderbarIndexHTML]) {
                if (![self tryGetClassInformationFromBookJSON]) {
                    [self release];
                    return nil;
                }
            }
        }
        
        NSURL *innerImageMapURL = [[NSBundle mainBundle] URLForResource:@"InnerImageMap" withExtension:@"plist"];
        NSDictionary *innerImageMap = [NSDictionary dictionaryWithContentsOfURL:innerImageMapURL];
        
        NSURL *appImageMapURL = [[NSBundle mainBundle] URLForResource:@"AppImageMap" withExtension:@"plist"];
        NSDictionary *appImageMap = [NSDictionary dictionaryWithContentsOfURL:appImageMapURL];
        
        NSString *imageName = [innerImageMap objectForKey:self.title];
        if (imageName) {
            mIconImage = [[NSImage imageNamed:imageName] retain];
            NSSize imageSize = [mIconImage size];
            if (imageSize.width > 16 || imageSize.height > 16) {
                [mIconImage setSize:NSMakeSize(16, 16)];
            }
        }
        if (!mIconImage) {
            NSString *imageAppPath = [appImageMap objectForKey:self.title];
            if (imageAppPath && [[NSFileManager defaultManager] fileExistsAtPath:imageAppPath]) {
                NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
                mIconImage = [[workspace iconForFile:imageAppPath] copy];
                [mIconImage setSize:NSMakeSize(16, 16)];
            }
        }
        if (!mIconImage) {
            mIconImage = [[NSImage imageNamed:@"framework_other.png"] retain];
        }
    }
    return self;
}


//-------------------------------------------------------------------------
#pragma mark ==== リファレンス情報の取得（各種） ====
//-------------------------------------------------------------------------

- (BOOL)tryGetClassInformationFromIndexHTML
{
    BAReferenceIndexHTMLParser *parser = [[BAReferenceIndexHTMLParser alloc] initWithDocReference:self];
    [parser parse];
    BOOL result = [parser hasSucceeded];
    [parser release];
    
    return result;
}

- (BOOL)tryGetClassInformationFromUnderbarIndexHTML
{
    BAReferenceUnderbarIndexHTMLParser *parser = [[BAReferenceUnderbarIndexHTMLParser alloc] initWithDocReference:self];
    [parser parse];
    BOOL result = [parser hasSucceeded];
    [parser release];

    return result;
}

- (BOOL)tryGetClassInformationFromBookJSON
{
    NSURL *bookInfoURL = [self.url URLByAppendingPathComponent:@"book.json"];
    SZJsonParser *bookInfoParser = [[SZJsonParser alloc] initWithContentsOfURL:bookInfoURL encoding:NSUTF8StringEncoding];
    NSDictionary *bookInfo = [bookInfoParser parse];
    [bookInfoParser release];
    if (!bookInfo) {
        return NO;
    }
    
    NSString *title = [bookInfo objectForKey:@"title"];
    if ([title hasSuffix:@" Framework Reference"]) {
        title = [title substringToIndex:[title length]-[@" Framework Reference" length]];
    }
    else if ([title hasSuffix:@" Reference Collection"]) {
        title = [title substringToIndex:[title length]-[@" Reference Collection" length]];
    }
    NSRange objcRange = [title rangeOfString:@" Objective-C" options:NSBackwardsSearch];
    if (objcRange.location != NSNotFound) {
        title = [title substringToIndex:objcRange.location];
    }
    mTitle = [title copy];
    
    BADocCategory *classCategory = [[BADocCategory alloc] initWithTitle:@"Classes"];
    [classCategory setParentNode:self];
    
    BADocCategory *otherCategory = [[BADocCategory alloc] initWithTitle:@"Others"];
    [otherCategory setParentNode:self];
    
    // カテゴリ分けして情報を格納
    NSArray *sections = [bookInfo objectForKey:@"sections"];
    for (NSDictionary *aSectionInfo in sections) {
        NSString *href = [aSectionInfo objectForKey:@"href"];
        if (!href || [href length] == 0 || [href isEqualToString:@"<@@>"]) {
            continue;
        }
        NSString *sectionTitle = [aSectionInfo objectForKey:@"title"];
        if (!sectionTitle || [sectionTitle length] == 0) {
            continue;
        }
        if ([sectionTitle isEqualToString:@"Introduction"] || [sectionTitle isEqualToString:@"Revision History"]) {
            continue;
        }
        
        NSRange sharpRange = [href rangeOfString:@"#"];
        if (sharpRange.location != NSNotFound) {
            href = [href substringToIndex:sharpRange.location];
        }
        
        NSURL *url = [[self.url URLByAppendingPathComponent:href] standardizedURL];
        
#ifdef DEBUG
        if ([href hasPrefix:@"<"]) {
            NSLog(@"Warning: invalid href for \"%@\" (href=%@)", sectionTitle, href);
        }
#endif
        
        BADocCategory *targetCategory;
        if ([sectionTitle hasSuffix:@" Class Reference"]
            || [sectionTitle hasSuffix:@" Additions"]
            || [sectionTitle hasSuffix:@" Additions Reference"]
            || [sectionTitle hasSuffix:@" Class Objective-C Reference"]
            || [sectionTitle hasSuffix:@" Class"]
            || [sectionTitle hasSuffix:@" Protocol Reference"])
        {
            targetCategory = classCategory;
        } else {
            targetCategory = otherCategory;
        }
        
        BAClassLevelNode *theNode = [BAClassLevelNode new];
        theNode.title = sectionTitle;
        theNode.url = url;
        [theNode setParentNode:targetCategory];
        [targetCategory addChildNode:theNode];
        [theNode release];
    }
    
    if (classCategory.childNodeCount > 0) {
        [classCategory sortClassLevelNodes];
        [self addChildNode:classCategory];
    }
    if (otherCategory.childNodeCount > 0) {
        [otherCategory sortClassLevelNodes];
        [self addChildNode:otherCategory];
    }
    return YES;
}


//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSString *)description
{
    return [NSString stringWithFormat:@"reference<title=%@>", mTitle];
}

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className
{
    for (BADocCategory *aCategory in self.childNodes) {
        BAClassLevelNode *classNode = [aCategory findNodeForClassWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className
{
    for (BADocCategory *aCategory in self.childNodes) {
        BAClassLevelNode *classNode = [aCategory findNodeForProtocolWithName:className];
        if (classNode) {
            return classNode;
        }
    }
    return nil;
}

@end

