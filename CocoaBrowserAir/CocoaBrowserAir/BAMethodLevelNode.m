//
//  BAMethodLevelNode.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/11.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAMethodLevelNode.h"
#import "BAGroupLevelNode.h"


@implementation BAMethodLevelNode

//-------------------------------------------------------------------------
#pragma mark ==== ノードの基本操作 ====
//-------------------------------------------------------------------------

- (NSString *)description
{
    return [NSString stringWithFormat:@"method-level<title=%@>", self.title];
}

@end

