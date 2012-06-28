#import "BASplitView.h"
#import "BADocument.h"


@implementation BASplitView

- (void)drawDividerInRect:(NSRect)aRect
{
    if (![self isVertical]) {
        [super drawDividerInRect:aRect];
        return;
    }

    if ([[self window] isMainWindow]) {
        [[NSColor colorWithCalibratedWhite:85/255.0 alpha:1.0] set];
    } else {
        [[NSColor colorWithCalibratedWhite:128/255.0 alpha:1.0] set];
    }
    NSRectFill(NSMakeRect(aRect.origin.x, aRect.origin.y, aRect.size.width, 22));

    [[NSColor colorWithCalibratedWhite:153/255.0 alpha:1.0] set];
    NSRectFill(NSMakeRect(aRect.origin.x, aRect.origin.y+22, aRect.size.width, aRect.size.height-22));
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect newFrame = [self frame];
    
    NSView *firstView = [[self subviews] objectAtIndex:0];
    NSView *secondView = [[self subviews] objectAtIndex:1];
    
    NSRect firstFrame = [firstView frame];
    NSRect secondFrame = [secondView frame];
    float dividerThickness = [self dividerThickness];
    
    if ([self isVertical]) {
        firstFrame.size.height = newFrame.size.height;
        secondFrame.size.height = newFrame.size.height;

        secondFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + dividerThickness;
        secondFrame.size.width = newFrame.size.width - firstFrame.size.width - dividerThickness;
    } else {
        firstFrame.size.width = newFrame.size.width;
        secondFrame.size.width = newFrame.size.width;

        secondFrame.origin.y = firstFrame.origin.y + firstFrame.size.height + dividerThickness;
        secondFrame.size.height = newFrame.size.height - firstFrame.size.height - dividerThickness;
    }
    
    [firstView setFrame:firstFrame];
    [secondView setFrame:secondFrame];
    
    [self setNeedsDisplay:YES];
    
    [(BADocument *)oDocument splitViewResized];
}

@end


