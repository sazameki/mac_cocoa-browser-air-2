//
//  BAClassLevelNode.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocumentNodeImpl.h"
#import "BAClassHTMLParser.h"


typedef enum {
    BAClassLevelNodeTypeClass,
    BAClassLevelNodeTypeProtocol,
    BAClassLevelNodeTypeNone,
} BAClassLevelNodeType;


@interface BAClassLevelNode : BADocumentNodeImpl<BAHTMLParserDelegate> {
@private
    BOOL                    mHasLoaded;    
    BAClassLevelNodeType    mClassLevelNodeType;    

    BAClassHTMLParser       *mParser;
}

@property(readwrite)    BAClassLevelNodeType    classLevelNodeType;
@property(readonly)     BOOL                    hasLoaded;

- (void)loadContent;

- (BAMethodLevelNode *)findNodeForInstanceMethodWithName:(NSString *)methodName;
- (BAMethodLevelNode *)findNodeForClassMethodWithName:(NSString *)methodName;
- (BAMethodLevelNode *)findNodeForPropertyWithName:(NSString *)methodName;
- (BAMethodLevelNode *)findNodeForConstantWithName:(NSString *)methodName;

@end

