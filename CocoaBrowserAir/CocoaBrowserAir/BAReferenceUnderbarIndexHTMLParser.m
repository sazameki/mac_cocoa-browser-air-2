//
//  BAReferenceUnderbarIndexHTMLParser.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAReferenceUnderbarIndexHTMLParser.h"
#import "BADocReference.h"
#import "BADocCategory.h"
#import "BAClassLevelNode.h"


enum {
    CategoryTypeUnknown,
    CategoryTypeClass,
    CategoryTypeProtocol,
    CategoryTypeOthers,
};


@interface BADocReference()

- (void)setTitle:(NSString *)str;

@end


@interface BAClassLevelNode()

- (void)setIconImage:(NSImage *)image;

@end


@implementation BAReferenceUnderbarIndexHTMLParser

- (id)initWithDocReference:(BADocReference *)docRef
{
    NSURL *htmlURL = [docRef.url URLByAppendingPathComponent:@"_index.html"];
    self = [super initWithURL:htmlURL];
    if (self) {
        mDocRef = docRef;
    }
    return self;
}

- (void)htmlParserStart:(SZHTMLParser *)parser
{
    mStr = [[NSMutableString string] retain];
    mIsCollectionHead = NO;
    mIsForums = NO;
    mHasSucceeded = NO;
    
    mClassCategory = [[BADocCategory alloc] initWithTitle:@"Classes"];
    [mClassCategory setParentNode:mDocRef];

    mOthersCategory = [[BADocCategory alloc] initWithTitle:@"Others"];
    [mOthersCategory setParentNode:mDocRef];
    
    mCurrentType = CategoryTypeUnknown;
    mCurrentCategory = mClassCategory;
}

- (void)htmlParserEnd:(SZHTMLParser *)parser
{
    if (mClassCategory.childNodeCount > 0) {
        mHasSucceeded = YES;
        [mClassCategory sortClassLevelNodes];
        [mDocRef addChildNode:mClassCategory];
    }

    if (mOthersCategory.childNodeCount > 0) {
        mHasSucceeded = YES;
        [mOthersCategory sortClassLevelNodes];
        [mDocRef addChildNode:mOthersCategory];
    }

    [mStr release];
    [mClassCategory release];
    [mOthersCategory release];
    [mForumHref release];
}

- (void)htmlParser:(SZHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    [mStr deleteCharactersInRange:NSMakeRange(0, [mStr length])];
    
    if ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"collectionHead"]) {
        mIsCollectionHead = YES;
    }
    else if ([tagName isEqualToString:@"li"] && [[attrs objectForKey:@"class"] isEqualToString:@"forums"]) {
        mIsForums = YES;
    }
    else if ([tagName isEqualToString:@"a"] && mIsForums) {
        mForumHref = [[attrs objectForKey:@"href"] retain];
    }
}

- (void)htmlParser:(SZHTMLParser *)parser endTag:(NSString *)tagName
{
    // タイトルの設定
    if ([tagName isEqualToString:@"title"]) {
        NSString *title = mStr;
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
        [mDocRef setTitle:title];
    }
    // カテゴリの作成
    else if ([tagName isEqualToString:@"div"]) {
        if (mIsCollectionHead) {
            if ([mStr hasPrefix:@"Class"]) {
                mCurrentType = CategoryTypeClass;
                mCurrentCategory = mClassCategory;
            } else if ([mStr hasPrefix:@"Protocol"]) {
                mCurrentType = CategoryTypeProtocol;
                mCurrentCategory = mClassCategory;
            } else {
                mCurrentType = CategoryTypeOthers;
                mCurrentCategory = mOthersCategory;
            }
            mIsCollectionHead = NO;
        }
    }
    else if ([tagName isEqualToString:@"a"]) {
        if (mIsForums) {
            NSString *classLevelTitle = [mStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([classLevelTitle length] > 0 && mForumHref) {
                NSString *href = mForumHref;
                NSRange sharpRange = [href rangeOfString:@"#"];
                if (sharpRange.location != NSNotFound) {
                    href = [href substringToIndex:sharpRange.location];
                }
                NSURL *url = [[mDocRef.url URLByAppendingPathComponent:href] standardizedURL];
                
                BAClassLevelNode *classLevelNode = [BAClassLevelNode new];
                classLevelNode.title = classLevelTitle;
                classLevelNode.url = url;
                if (mCurrentType == CategoryTypeClass) {
                    [classLevelNode setIconImage:[NSImage imageNamed:@"class-icon.png"]];
                    classLevelNode.classLevelNodeType = BAClassLevelNodeTypeClass;
                } else if (mCurrentType == CategoryTypeProtocol) {
                    [classLevelNode setIconImage:[NSImage imageNamed:@"protocol-icon.png"]];
                    classLevelNode.classLevelNodeType = BAClassLevelNodeTypeProtocol;
                }
                [classLevelNode setParentNode:mCurrentCategory];
                [mCurrentCategory addChildNode:classLevelNode];
                [classLevelNode release];
            }
            mIsForums = NO;
            [mForumHref release];
            mForumHref = nil;
        }
    }
}

- (void)htmlParser:(SZHTMLParser *)parser foundText:(NSString *)text
{
    [mStr appendString:text];
}

- (BOOL)hasSucceeded
{
    return mHasSucceeded;
}

@end

