//
//  BAReferenceUnderbarIndexHTMLParser.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAHTMLParser.h"


@class BADocReference;
@class BADocCategory;


@interface BAReferenceUnderbarIndexHTMLParser : BAHTMLParser {
@private
    BADocReference  *mDocRef;
    NSMutableString *mStr;
    
    BOOL            mHasSucceeded;
    int             mCurrentType;
    
    BOOL            mIsCollectionHead;
    BOOL            mIsForums;
    NSString        *mForumHref;
    
    BADocCategory   *mClassCategory;
    BADocCategory   *mOthersCategory;
    BADocCategory   *mCurrentCategory;
}

- (id)initWithDocReference:(BADocReference *)docRef;

- (BOOL)hasSucceeded;

@end

