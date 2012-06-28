//
//  BADocumentNodeImpl.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BADocumentNode.h"


@class BADocSet;
@class BADocFolder;
@class BADocReference;
@class BADocCategory;
@class BAClassLevelNode;
@class BAGroupLevelNode;
@class BAMethodLevelNode;


@interface BADocumentNodeImpl : NSObject<BADocumentNode> {
@protected
    NSString            *mTitle;
    NSURL               *mURL;
    NSImage             *mIconImage;
    id<BADocumentNode>  mParentNode;
    NSMutableArray      *mTags;
    NSMutableArray      *mChildNodes;
    NSString            *mContentHTMLSource;
}

@end

