//
//  BAImageButton.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BAImageButton : NSView {
@private
    BOOL                mEnabled;
    BOOL                mIsMouseInside;
    NSTrackingRectTag   mTrackingRectTag;
    
    id                  mTarget;
    SEL                 mAction;
    NSImage             *mImage;
    BOOL                mIsHighlighted;
}

@property(readwrite, assign) id         target;
@property(readwrite, assign) SEL        action;
@property(readwrite, retain) NSImage    *image;
@property(readonly) BOOL                isHighlighted;
@property(readwrite) BOOL               enabled;

@end

