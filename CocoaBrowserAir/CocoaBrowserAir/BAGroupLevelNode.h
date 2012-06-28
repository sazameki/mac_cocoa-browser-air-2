//
//  BACategoryLevelNode.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"


@interface BAGroupLevelNode : BADocumentNodeImpl {
@private
    NSArray             *mFilteredMethodLevelNodes;
}

- (BAMethodLevelNode *)findNodeForMethodWithName:(NSString *)methodName;
- (BAMethodLevelNode *)findNodeForPropertyWithName:(NSString *)methodName;
- (BAMethodLevelNode *)findNodeForConstantWithName:(NSString *)methodName;

// フィルタリング処理
- (void)setSearchString:(NSString *)str;
- (void)clearSearchString;

@end

