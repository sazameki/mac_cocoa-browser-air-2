//
//  BAOutlineView.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAOutlineView.h"
#import "BADocument.h"
#import "BADocCategory.h"


@implementation BAOutlineView

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
{
    NSRect frame = [super frameOfOutlineCellAtRow:row];
    if (NSClassFromString(@"NSFileCoordinator")) {
        NSInteger level = [self levelForRow:row];
        if (level > 0) {
            frame.origin.x += 14;
        }
    }
    return frame;
}

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    NSUInteger modifiers = [theEvent modifierFlags];
    
    // 矢印キーは通常のアウトラインビューの操作
    if ((modifiers & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask))
        || keyCode == 0x7e
        || keyCode == 0x7d
        || keyCode == 0x7c
        || keyCode == 0x7b)
    {
        // 右キーが押されていて、カテゴリノードであれば、ブラウザビューをアクティブにする
        if (keyCode == 0x7c) {
            NSInteger selectedRow = [self selectedRow];
            if (selectedRow >= 0) {
                NSObject<BADocumentNode> *node = [self itemAtRow:selectedRow];
                if ([node isKindOfClass:[BADocCategory class]]) {
                    [oDocument activateBrowser];
                    return;
                }
            }
        }
        // それ以外の場合は通常のアウトラインビューの操作
        [super keyDown:theEvent];
    }
    // それ以外の場合は検索キーワードの設定
    else {
        [oDocument startSearchWithString:[theEvent characters]];
    }
}

- (void)swipeWithEvent:(NSEvent *)event
{
    if ([event deltaX] < 0) {
        [oDocument goForward:self];
    } else {
        [oDocument goBackward:self];
    }
}

- (NSInteger)levelForItem:(id)item
{
    NSLog(@"Test!!!!");
    return 2;
}

@end

