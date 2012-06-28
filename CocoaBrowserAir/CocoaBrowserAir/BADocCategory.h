//
//  BADocCategory.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"


@interface BADocCategory : BADocumentNodeImpl {
@private
    NSArray         *mFilteredClassLevelNodes;
}

- (id)initWithTitle:(NSString *)title;

- (void)sortClassLevelNodes;

- (void)setSearchString:(NSString *)str;
- (void)clearSearchString;

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className;
- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className;

@end

