#import "BAOutlineViewCell.h"
#import "BADocSet.h"
#import "BADocFolder.h"


static float BAOutlineViewCellIconMargin = 1.0f;


@implementation BAOutlineViewCell

@synthesize node = mNode;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (!self.node) {
        return;
    }
    
    CGFloat paddingLeft = 0.0;
    if (NSClassFromString(@"NSFileCoordinator")) {
        if (![mNode isKindOfClass:[BADocSet class]]) {
            paddingLeft += 14;
        }
    }
    
    // Draw Image
    NSSize iconSize = NSZeroSize;
    NSImage *iconImage = self.node.iconImage;
    if (iconImage) {
        iconSize = [iconImage size];
        NSPoint iconPos = cellFrame.origin;
        iconPos.x += paddingLeft;
        iconPos.x += BAOutlineViewCellIconMargin;
        
        if([controlView isFlipped]) {
            iconPos.y += iconSize.height;
        }
        
        [iconImage setSize:iconSize];
        [iconImage compositeToPoint:iconPos operation:NSCompositeSourceOver];
    }
    
    // Draw text
    NSRect pathRect;
    pathRect.origin.x = cellFrame.origin.x + BAOutlineViewCellIconMargin;
    if (iconSize.width > 0) {
        pathRect.origin.x += iconSize.width + BAOutlineViewCellIconMargin;
    }
    pathRect.origin.x += paddingLeft;
    pathRect.origin.y = cellFrame.origin.y;
    pathRect.size.width = cellFrame.size.width - (pathRect.origin.x - cellFrame.origin.x);
    pathRect.size.height = cellFrame.size.height;
    
    NSString *title = self.node.localizedTitle;
    if (title) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        if ([self isHighlighted]) {
            [attrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        } else if ([self.node isKindOfClass:[BADocFolder class]]) {
            [attrs setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
        } else {
            [attrs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
        }
        if ([self.node isKindOfClass:[BADocSet class]]) {
            [attrs setObject:[NSFont fontWithName:@"LucidaGrande-Bold" size:12.0] forKey:NSFontAttributeName];
        } else {
            [attrs setObject:[NSFont fontWithName:@"LucidaGrande" size:12.0] forKey:NSFontAttributeName];
        }
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [attrs setObject:paraStyle forKey:NSParagraphStyleAttributeName];
        [title drawInRect:pathRect withAttributes:attrs];
        [paraStyle release];
    }
}

@end


