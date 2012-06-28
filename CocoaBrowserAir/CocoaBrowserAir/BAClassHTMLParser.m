//
//  BAClassHTMLParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "BAClassHTMLParser.h"
#import "BAClassLevelNode.h"
#import "NSURL+RelativeAddress.h"
#import "BAMethodLevelNode.h"
#import "BAGroupLevelNode.h"


enum ParseState {
    ParseStateFindingBody,
    ParseStateFindingH1,
    ParseStateFindingIntroDiv,
    ParseStateFindingIntroEnd,
    ParseStateGroup,
    ParseStateNone,
};

enum ParseSubState {
    ParseSubStateNone,
    ParseSubStateTitle,
};


@implementation BAClassHTMLParser

- (id)initWithClassLevelNode:(BAClassLevelNode *)classLevelNode
{
    self = [super initWithURL:classLevelNode.url];
    if (self) {
        mClassLevelNode = classLevelNode;
    }
    return self;
}

- (void)htmlParserStart:(SZHTMLParser *)parser
{
    mState = ParseStateFindingBody;
    mSubState = ParseSubStateNone;
    mANames = [[NSMutableArray array] retain];
    mPrevANames = [[NSMutableArray array] retain];
    mHTMLSource = [[NSMutableString string] retain];
    mTitle = [[NSMutableString string] retain];
}

- (void)htmlParserEnd:(SZHTMLParser *)parser
{
    [mANames release];
    [mPrevANames release];
    [mHTMLSource release];
    [mTitle release];
}

- (void)htmlParser:(SZHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if (mState == ParseStateFindingBody) {
        if ([tagName isEqualToString:@"body"]) {
            mState = ParseStateFindingH1;
        }
    }
    else if (mState == ParseStateFindingH1) {
        if ([tagName isEqualToString:@"a"]) {
            NSString *aname = [attrs objectForKey:@"name"];
            if (aname && [aname hasPrefix:@"/"]) {
                [mANames addObject:aname];
            }
        }
        else if ([tagName isEqualToString:@"h1"]) {
            mState = ParseStateFindingIntroDiv;
            mDivCount = 0;
            
            [mHTMLSource appendString:@"<h1 "];
            for (NSString *key in attrs) {
                NSString *value = [attrs objectForKey:key];
                [mHTMLSource appendFormat:@"%@=\"", key];
                if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                    NSURL *parentURL = mClassLevelNode.url;
                    NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                    [mHTMLSource appendString:[theURL absoluteString]];
                } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                    NSURL *parentURL = mClassLevelNode.url;
                    NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                    [mHTMLSource appendString:[theURL absoluteString]];
                } else {
                    [mHTMLSource appendString:value];
                }
                [mHTMLSource appendString:@"\""];
            }
            [mHTMLSource appendString:@">"];
        }
    }
    else if (mState == ParseStateFindingIntroDiv) {
        [mHTMLSource appendString:@"<"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@" "];
        for (NSString *key in attrs) {
            NSString *value = [attrs objectForKey:key];
            [mHTMLSource appendFormat:@"%@=\"", key];
            if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else {
                [mHTMLSource appendString:value];
            }
            [mHTMLSource appendString:@"\""];
        }
        [mHTMLSource appendString:@">"];
        
        if ([tagName isEqualToString:@"div"]) {
            mDivCount++;
            mState = ParseStateFindingIntroEnd;
        }
    }
    else if (mState == ParseStateFindingIntroEnd) {
        [mHTMLSource appendString:@"<"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@" "];
        for (NSString *key in attrs) {
            NSString *value = [attrs objectForKey:key];
            [mHTMLSource appendFormat:@"%@=\"", key];
            if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else {
                [mHTMLSource appendString:value];
            }
            [mHTMLSource appendString:@"\""];
        }
        [mHTMLSource appendString:@">"];

        if ([tagName isEqualToString:@"div"]) {
            mDivCount++;
        }
    }
    else if (mState == ParseStateGroup) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"] || ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"id"] isEqualToString:@"pageNavigationLinks_bottom"])) {
            if (mLevel < 0) {
                [mPrevANames addObjectsFromArray:mANames];
                [mANames removeAllObjects];
                mSubState = ParseSubStateTitle;
                mLevel = 2;
            } else {
                if (mLevel == 2) {
                    BAGroupLevelNode *groupNode = [BAGroupLevelNode new];
                    groupNode.title = mTitle;
                    [groupNode setParentNode:mClassLevelNode];
                    groupNode.contentHTMLSource = [mHTMLSource stringByAppendingString:@"</body></html>"];
                    [groupNode addTags:mPrevANames];
                    [mPrevANames removeAllObjects];
                    [mClassLevelNode addChildNode:groupNode];
                    mLastGroupNode = groupNode;
                }
                else if (mLevel == 3) {
                    NSString *title = mTitle;
                    if ([mLastGroupNode.title hasPrefix:@"Class Method"]) {
                        title = [@"+ " stringByAppendingString:title];
                    }
                    else if ([mLastGroupNode.title hasPrefix:@"Instance Method"]) {
                        title = [@"- " stringByAppendingString:title];
                    }
                    BAMethodLevelNode *methodNode = [BAMethodLevelNode new];
                    methodNode.title = title;
                    [methodNode setParentNode:mLastGroupNode];
                    methodNode.contentHTMLSource = [mHTMLSource stringByAppendingString:@"</body></html>"];
                    [methodNode addTags:mPrevANames];
                    [mPrevANames removeAllObjects];
                    [mLastGroupNode addChildNode:methodNode];
                }
                [mPrevANames removeAllObjects];
                [mTitle deleteCharactersInRange:NSMakeRange(0, [mTitle length])];
                [mHTMLSource deleteCharactersInRange:NSMakeRange(0, [mHTMLSource length])];

                mSubState = ParseSubStateTitle;
                if ([tagName isEqualToString:@"h2"]) {
                    mLevel = 2;
                } else {
                    mLevel = 3;
                }
            }
        }

        [mHTMLSource appendString:@"<"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@" "];
        for (NSString *key in attrs) {
            NSString *value = [attrs objectForKey:key];
            [mHTMLSource appendFormat:@"%@=\"", key];
            if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                NSURL *parentURL = mClassLevelNode.url;
                NSURL *theURL = [NSURL numataURLWithString:value relativeToURL:parentURL];
                [mHTMLSource appendString:[theURL absoluteString]];
            } else {
                [mHTMLSource appendString:value];
            }
            [mHTMLSource appendString:@"\""];
        }
        [mHTMLSource appendString:@">"];

        if ([tagName isEqualToString:@"a"]) {
            NSString *aname = [attrs objectForKey:@"name"];
            if (aname && [aname hasPrefix:@"/"]) {
                [mANames addObject:aname];
            }
        }
        else if ([tagName isEqualToString:@"div"]) {
            mDivCount++;
        }
    }
}

- (void)htmlParser:(SZHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mState == ParseStateFindingIntroDiv) {
        [mHTMLSource appendString:@"</"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@">"];
    }
    else if (mState == ParseStateFindingIntroEnd) {
        [mHTMLSource appendString:@"</"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@">"];
        if ([tagName isEqualToString:@"div"]) {
            mDivCount--;
        }
        if (mDivCount == 0) {
            mClassLevelNode.contentHTMLSource = [mHTMLSource stringByAppendingString:@"</body></html>"];
            [mClassLevelNode addTags:mANames];
            [mANames removeAllObjects];
            [mHTMLSource deleteCharactersInRange:NSMakeRange(0, [mHTMLSource length])];
            mLevel = -1;
            mState = ParseStateGroup;
        }
    }
    else if (mState == ParseStateGroup) {
        [mHTMLSource appendString:@"</"];
        [mHTMLSource appendString:tagName];
        [mHTMLSource appendString:@">"];
        if ([tagName isEqualToString:@"div"]) {
            mDivCount--;
        }
        if (mSubState == ParseSubStateTitle) {
            if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"]) {
                mSubState = ParseSubStateNone;
            }
        }
    }
}    

- (void)htmlParser:(SZHTMLParser *)parser foundText:(NSString *)text
{
    if (mState == ParseStateFindingIntroDiv || mState == ParseStateFindingIntroEnd) {
        [mHTMLSource appendString:text];
    }
    else if (mState == ParseStateGroup) {
        [mHTMLSource appendString:text];
        
        if (mSubState == ParseSubStateTitle) {
            [mTitle appendString:text];
        }
    }
}

@end


