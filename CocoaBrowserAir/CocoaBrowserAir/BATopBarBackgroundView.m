//
//  BATopBarBackgroundView.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BATopBarBackgroundView.h"


@implementation BATopBarBackgroundView

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
    NSImage *image;
    if ([[self window] isMainWindow]) {
        image = [NSImage imageNamed:@"back_active.png"];
    } else {
        image = [NSImage imageNamed:@"back_inactive.png"];
    }

    NSRect frame = [self frame];
    frame.origin = NSZeroPoint;
    
    [image drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

@end
