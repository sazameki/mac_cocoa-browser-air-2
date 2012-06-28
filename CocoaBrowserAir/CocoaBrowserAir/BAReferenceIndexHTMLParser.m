//
//  BAReferenceIndexHTMLParser.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAReferenceIndexHTMLParser.h"
#import "BADocReference.h"
#import "BADocCategory.h"
#import "BAClassLevelNode.h"


enum {
    CategoryTypeHeader,
    CategoryTypeClass,
    CategoryTypeCategory,
    CategoryTypeProtocol,
    CategoryTypeOthers,
    CategoryTypeUnknown,
};


@interface BADocReference()

- (void)setTitle:(NSString *)str;

@end


@interface BAClassLevelNode()

- (void)setIconImage:(NSImage *)image;

@end


@implementation BAReferenceIndexHTMLParser

- (id)initWithDocReference:(BADocReference *)docRef
{
    NSURL *htmlURL = [docRef.url URLByAppendingPathComponent:@"index.html"];
    self = [super initWithURL:htmlURL];
    if (self) {
        mDocRef = docRef;
    }
    return self;
}

- (void)htmlParserStart:(SZHTMLParser *)parser
{
    mStr = [[NSMutableString string] retain];

    mIsFinished = NO;
    mIsEmpty = NO;
    
    mIsCollection = NO;
    mHasSucceeded = NO;
    mIsForums = NO;

    mClassCategory = [[BADocCategory alloc] initWithTitle:@"Classes"];
    [mClassCategory setParentNode:mDocRef];
    
    mOthersCategory = [[BADocCategory alloc] initWithTitle:@"Others"];
    [mOthersCategory setParentNode:mDocRef];

    mCurrentType = CategoryTypeUnknown;
    mCurrentCategory = mClassCategory;
}

- (void)htmlParserEnd:(SZHTMLParser *)parser
{
    if (!mIsEmpty) {
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
    }

    [mStr release];
    [mForumHref release];
    [mClassCategory release];
    [mOthersCategory release];
}

- (void)htmlParser:(SZHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if (mIsFinished) {
        return;
    }
    
    [mStr deleteCharactersInRange:NSMakeRange(0, [mStr length])];

    if ([tagName isEqualToString:@"meta"]) {
        NSString *idStr = [attrs objectForKey:@"id"];
        NSString *contentStr = [attrs objectForKey:@"content"];
        if ([idStr caseInsensitiveCompare:@"refresh"] == NSOrderedSame
            && [contentStr hasSuffix:@"_index.html"])
        {
            mIsEmpty = YES;
            mIsFinished = YES;
        }
    }
    else if ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"collection"]) {
        mIsCollection = YES;
    }
    else if ([tagName isEqualToString:@"td"] && [[attrs objectForKey:@"class"] isEqualToString:@"forums"]) {
        mIsForums = YES;
    }
    else if ([tagName isEqualToString:@"a"] && mIsForums) {
        mForumHref = [[attrs objectForKey:@"href"] retain];
    }
}

- (void)htmlParser:(SZHTMLParser *)parser endTag:(NSString *)tagName
{
    if ([tagName isEqualToString:@"h1"]) {
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
    else if ([tagName isEqualToString:@"h3"]) {
        if (mIsCollection) {
            if ([mStr hasPrefix:@"Header"]) {
                mCurrentType = CategoryTypeHeader;
                mCurrentCategory = nil;
            } else if ([mStr hasPrefix:@"Class"]) {
                mCurrentType = CategoryTypeClass;
                mCurrentCategory = mClassCategory;
            } else if ([mStr hasPrefix:@"Protocol"]) {
                mCurrentType = CategoryTypeProtocol;
                mCurrentCategory = mClassCategory;
            } else if ([mStr hasPrefix:@"Categor"]) {
                mCurrentType = CategoryTypeCategory;
                mCurrentCategory = mClassCategory;
            } else {
                mCurrentType = CategoryTypeOthers;
                mCurrentCategory = mOthersCategory;
            }
            mIsCollection = NO;
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
                
                if (mCurrentCategory) {
                    BAClassLevelNode *classLevelNode = [BAClassLevelNode new];
                    classLevelNode.title = classLevelTitle;
                    classLevelNode.url = url;
                    if (mCurrentType == CategoryTypeClass) {
                        [classLevelNode setIconImage:[NSImage imageNamed:@"class-icon.png"]];
                    } else if (mCurrentType == CategoryTypeProtocol) {
                        [classLevelNode setIconImage:[NSImage imageNamed:@"protocol-icon.png"]];
                    } else if (mCurrentType == CategoryTypeCategory) {
                        [classLevelNode setIconImage:[NSImage imageNamed:@"category-icon.png"]];
                    }
                    [classLevelNode setParentNode:mCurrentCategory];
                    [mCurrentCategory addChildNode:classLevelNode];
                    [classLevelNode release];
                }
            }
            mIsForums = NO;
            [mForumHref release];
            mForumHref = nil;
        }
    }
}

- (void)htmlParser:(SZHTMLParser *)parser foundText:(NSString *)text
{
    if (mIsFinished) {
        return;
    }
    [mStr appendString:text];
}

- (BOOL)hasSucceeded
{
    return mHasSucceeded;
}

@end

