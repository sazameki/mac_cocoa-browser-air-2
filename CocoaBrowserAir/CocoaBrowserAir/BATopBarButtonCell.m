//
//  BATopBarButtonCell.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BATopBarButtonCell.h"


@implementation BATopBarButtonCell

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (flag) {
        [super highlight:flag withFrame:cellFrame inView:controlView];
        [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1] set];
        [NSBezierPath fillRect:cellFrame];
    } else {
        [super highlight:flag withFrame:cellFrame inView:controlView];
    }
}

@end

