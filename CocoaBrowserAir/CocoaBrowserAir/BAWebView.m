//
//  BAWebView.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAWebView.h"
#import "BADocument.h"


@implementation BAWebView

- (void)swipeWithEvent:(NSEvent *)event
{
    if ([event deltaX] < 0) {
        [oDocument goForward:self];
    } else {
        [oDocument goBackward:self];
    }
}

@end

