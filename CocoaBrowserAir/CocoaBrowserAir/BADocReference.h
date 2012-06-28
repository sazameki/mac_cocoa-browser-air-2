//
//  BADocReference.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"


@interface BADocReference : BADocumentNodeImpl {
}

- (id)initWithContentsOfURL:(NSURL *)baseURL;

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className;
- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className;

@end

