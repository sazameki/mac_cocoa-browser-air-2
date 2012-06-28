//
//  BABrowser.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BABrowser.h"
#import "BADocument.h"


@implementation BABrowser

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    NSUInteger modifiers = [theEvent modifierFlags];
    
    // 矢印キーは親クラスで処理する
    if ((modifiers & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask))
        || keyCode == 0x7e
        || keyCode == 0x7d
        || keyCode == 0x7c
        || keyCode == 0x7b)
    {
        if (keyCode == 0x7b && [self selectedColumn] == 0) {
            [oDocument activateDocSetListView];
            return;
        }
        [super keyDown:theEvent];
    }
    // escキーは検索ワードをクリアする
    else if (keyCode == 0x35) {
        [oDocument clearCurrentSearchWord];
        return;
    }
    // returnキーとenterキーが押されたらWebビューをアクティブにする
    else if (keyCode == 0x24 || keyCode == 0x4c) {
        [oDocument activateWebView];
        return;
    }
    // それ以外の場合は検索を開始する
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

@end

