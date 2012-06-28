//
//  BAReferenceIndexHTMLParser.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAHTMLParser.h"


@class BADocReference;
@class BADocCategory;


@interface BAReferenceIndexHTMLParser : BAHTMLParser {
@private
    BADocReference  *mDocRef;
    NSMutableString *mStr;

    BOOL    mIsFinished;
    BOOL    mIsEmpty;

    int             mCurrentType;
    BOOL            mIsCollection;
    BOOL            mIsForums;
    NSString        *mForumHref;

    BOOL    mHasSucceeded;

    BADocCategory   *mClassCategory;
    BADocCategory   *mOthersCategory;
    BADocCategory   *mCurrentCategory;
}

- (id)initWithDocReference:(BADocReference *)docRef;

- (BOOL)hasSucceeded;

@end

