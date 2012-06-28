//
//  BAClassParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "BAHTMLParser.h"


@class BAClassLevelNode;
@class BAGroupLevelNode;


@interface BAClassHTMLParser : BAHTMLParser {
    BAClassLevelNode        *mClassLevelNode;
    int                     mState;
    int                     mSubState;
    NSMutableArray          *mANames;
    NSMutableArray          *mPrevANames;
    NSMutableString         *mHTMLSource;
    int                     mDivCount;

    int                     mLevel;
    NSMutableString         *mTitle;
    
    BAGroupLevelNode        *mLastGroupNode;
}

- (id)initWithClassLevelNode:(BAClassLevelNode *)classLevelNode;

@end

