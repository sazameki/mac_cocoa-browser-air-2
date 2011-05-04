//
//  CBWhiteBGView.m
//  Cocoa Browser Air
//
//  Created by numata on 11/05/04.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "CBWhiteBGView.h"


@implementation CBWhiteBGView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
}

@end
