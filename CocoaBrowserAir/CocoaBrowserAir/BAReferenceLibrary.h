//
//  BAReferenceLibrary.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BADocSet;
@protocol BADocumentNode;


@interface BAReferenceLibrary : NSObject {
    NSMutableArray  *mPreCreatedDocSets;
    NSMutableArray  *mDocSets;
    BOOL            mIsCheckingEnvironment;
}

@property(readonly) BOOL    isCheckingEnvironment;

+ (BAReferenceLibrary *)sharedInstance;

- (NSInteger)docSetCount;
- (BADocSet *)docSetAtIndex:(NSInteger)index;

- (NSArray *)nodesToNode:(id<BADocumentNode>)node;
- (NSArray *)nodesToURL:(NSURL *)url startNode:(id<BADocumentNode>)startNode;

@end

