//
//  BADocFolder.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"


@interface BADocFolder : BADocumentNodeImpl {
@private
}

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className;
- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className;

- (void)sort;

@end
