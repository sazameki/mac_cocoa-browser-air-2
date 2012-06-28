//
//  BADocSet.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"


@interface BADocSet : BADocumentNodeImpl

- (id)initWithBaseURL:(NSURL *)baseURL;

- (BOOL)tryToLoad;

- (BAClassLevelNode *)findNodeForClassWithName:(NSString *)className;
- (BAClassLevelNode *)findNodeForProtocolWithName:(NSString *)className;

@end

