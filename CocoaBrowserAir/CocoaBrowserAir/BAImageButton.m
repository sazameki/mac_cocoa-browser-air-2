//
//  BAImageButton.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAImageButton.h"


@implementation BAImageButton

@synthesize target = mTarget;
@synthesize action = mAction;
@synthesize image = mImage;
@synthesize isHighlighted = mIsHighlighted;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        mIsHighlighted = NO;
        mEnabled = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [mImage release];
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.isHighlighted) {
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.08] set];
        [NSBezierPath fillRect:dirtyRect];
    }
    
    NSRect frame = [self frame];
    
    NSSize imageSize = [self.image size];
    [self.image drawAtPoint:NSMakePoint((int)((frame.size.width - imageSize.width)/2), (int)((frame.size.height - imageSize.height)/2))
                   fromRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)
                  operation:NSCompositeSourceOver
                   fraction:(mEnabled? 1.0: 0.4)];
}

- (BOOL)enabled
{
    return mEnabled;
}

- (void)setEnabled:(BOOL)flag
{
    mEnabled = flag;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.enabled) {
        return;
    }
    mIsMouseInside = YES;
    
    mTrackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];

    mIsHighlighted = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    mIsMouseInside = NO;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    mIsMouseInside = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (mIsMouseInside && self.enabled) {
        if (self.target && [self.target respondsToSelector:self.action]) {
            [self.target performSelector:self.action withObject:self];
        }
    }

    mIsHighlighted = NO;
    [self setNeedsDisplay:YES];
    [self removeTrackingRect:mTrackingRectTag];
}

@end

