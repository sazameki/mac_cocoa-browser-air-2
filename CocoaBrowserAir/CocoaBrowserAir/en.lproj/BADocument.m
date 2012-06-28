//
//  BADocument.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BADocument.h"

#import <QuartzCore/QuartzCore.h>
#import "BAOutlineViewCell.h"
#import "BATopBarBackgroundView.h"
#import "BAImageButton.h"

#import "BAAppDelegate.h"
#import "BAReferenceLibrary.h"
#import "BADocSet.h"
#import "BADocFolder.h"
#import "BADocReference.h"
#import "BADocCategory.h"
#import "BAClassLevelNode.h"
#import "BAGroupLevelNode.h"
#import "BAMethodLevelNode.h"


@interface BADocument()

- (BADocCategory *)selectedCategory;
- (BAClassLevelNode *)selectedClassLevelNode;
- (BAGroupLevelNode *)selectedGroupLevelNode;
- (BAMethodLevelNode *)selectedMethodLevelNode;
- (void)windowDidResize:(NSNotification *)notification;

@end


@interface BAWindowController : NSWindowController {
}
@end


@implementation BADocument

//-------------------------------------------------------------------------
#pragma mark ==== 初期化、クリーンアップ ====
//-------------------------------------------------------------------------

- (void)makeWindowControllers
{
    NSWindowController* controller = [[BAWindowController alloc] initWithWindowNibName:@"BADocument" owner:self];
    [self addWindowController:controller];
}

- (NSString *)windowNibName
{
    return @"BADocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    ///// 基本の初期化処理
    mShownNodes = [[NSMutableArray array] retain];
    mHistoryPos = -1;
    mForcedNavigating = NO;
    mSelectedDocSetListViewIndex = -1;
    
    ///// インタフェース要素のセットアップ
    
    // ブラウザのセットアップ
    [oBrowser setMinColumnWidth:1.0];
    
    // アウトラインビューのセットアップ
    NSTableColumn *frameworkColumn = [[oDocSetListView tableColumns] lastObject];
    BAOutlineViewCell *templateCell = [[BAOutlineViewCell new] autorelease];
    [frameworkColumn setDataCell:templateCell];
    
    // ウェブビューのセットアップ
    [oWebView setPolicyDelegate:self];
    
    // 戻るボタン
    oGoBackwardButton.target = self;
    oGoBackwardButton.action = @selector(goBackward:);
    oGoBackwardButton.image = [NSImage imageNamed:@"go_left.png"];
    oGoBackwardButton.enabled = NO;
    
    // 進むボタン
    oGoForwardButton.target = self;
    oGoForwardButton.action = @selector(goForward:);
    oGoForwardButton.image = [NSImage imageNamed:@"go_right.png"];
    oGoForwardButton.enabled = NO;
    
    // 読み込み中インディケータ
    [oLoadingIndicator setHidden:YES];
    
    // アウトラインビューをアクティブにする
    [oMainWindow makeFirstResponder:oDocSetListView];
    
    // ドキュメントセットチェック中のシートを表示する
    [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(showCheckingSheet:) userInfo:nil repeats:NO];
}

- (void)dealloc
{
    [mShownNodes release];

    [super dealloc];
}

 - (void)showCheckingSheet:(NSTimer *)timer
{
    if ([BAReferenceLibrary sharedInstance].isCheckingEnvironment) {
        NSInteger checkTargetCount = [[BAAppDelegate sharedInstance] checkTargetCount];
        if (checkTargetCount > 0) {
            mCheckedTargetCount = 0;
            [oCheckingProgressIndicator setDoubleValue:0.0];
            [oCheckingProgressIndicator setIndeterminate:NO];
        } else {
            [oCheckingProgressIndicator setIndeterminate:YES];
        }
        [oCheckingProgressIndicator startAnimation:self];
        [NSApp beginSheet:oCheckingPanel modalForWindow:oMainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)incrementCheckedTargetCount
{
    mCheckedTargetCount++;
    [oCheckingProgressIndicator setDoubleValue:((double)mCheckedTargetCount / [[BAAppDelegate sharedInstance] checkTargetCount])];
}

 - (void)hideCheckingSheet
{
    [oCheckingProgressIndicator stopAnimation:self];
    [oCheckingPanel orderOut:self];
    [NSApp endSheet:oCheckingPanel];
    
    [oDocSetListView reloadData];
}


//-------------------------------------------------------------------------
#pragma mark ==== アクション ====
//-------------------------------------------------------------------------

- (IBAction)goBackward:(id)sender
{
    if (mHistoryPos > 0 && [mShownNodes count] >= 2) {
        mHistoryPos--;
        id<BADocumentNode> prevNode = [mShownNodes objectAtIndex:mHistoryPos];
        [self validateGoBackButtons];
        NSArray *nodes = [[BAReferenceLibrary sharedInstance] nodesToNode:prevNode];
        if (nodes) {
            mForcedNavigating = YES;
            [NSTimer scheduledTimerWithTimeInterval:0
                                             target:self
                                           selector:@selector(showFirstNodeInArray:)
                                           userInfo:[NSMutableArray arrayWithArray:nodes]
                                            repeats:NO];
        }
    }
}

- (IBAction)goForward:(id)sender
{
    if (mHistoryPos >= 0 && mHistoryPos < [mShownNodes count]-1) {
        mHistoryPos++;
        id<BADocumentNode> nextNode = [mShownNodes objectAtIndex:mHistoryPos];
        [self validateGoBackButtons];
        NSArray *nodes = [[BAReferenceLibrary sharedInstance] nodesToNode:nextNode];
        if (nodes) {
            mForcedNavigating = YES;
            [NSTimer scheduledTimerWithTimeInterval:0
                                             target:self
                                           selector:@selector(showFirstNodeInArray:)
                                           userInfo:[NSMutableArray arrayWithArray:nodes]
                                            repeats:NO];
        }
    }
}

- (IBAction)changedClassLevelSearchString:(id)sender
{
    BADocCategory *category = [self selectedCategory];
    mLastFilteredCategoryNode = category;
    [category setSearchString:[oClassLevelSearchField stringValue]];
    [oBrowser selectRow:-1 inColumn:0];
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reloadBrowserFirstColumn:) userInfo:nil repeats:NO];
}

- (IBAction)changedMethodLevelSearchString:(id)sender
{
    BAGroupLevelNode *groupLevelNode = [self selectedGroupLevelNode];
    mLastFilteredGroupLevelNode = groupLevelNode;
    [groupLevelNode setSearchString:[oMethodLevelSearchField stringValue]];
    [oBrowser reloadColumn:2];
    [oBrowser selectRow:-1 inColumn:2];
}

- (IBAction)activateClassLevelSearchField:(id)sender
{
    if ([oClassLevelSearchField isEnabled]) {
        [oMainWindow makeFirstResponder:oClassLevelSearchField];
    }
}

- (IBAction)activateMethodLevelSearchField:(id)sender
{
    if ([oMethodLevelSearchField isEnabled]) {
        [oMainWindow makeFirstResponder:oMethodLevelSearchField];
    }
}


//-------------------------------------------------------------------------
#pragma mark ==== ユーティリティメソッド ====
//-------------------------------------------------------------------------

- (void)splitViewResized
{
    [self windowDidResize:nil];
}

- (void)startLoadingContent
{
    [oLoadingIndicator setHidden:NO];
    [oLoadingIndicator startAnimation:self];
}

- (void)finishLoadingContent
{
    [oLoadingIndicator stopAnimation:self];
    [oLoadingIndicator setHidden:YES];
}

- (void)validateGoBackButtons
{
    oGoBackwardButton.enabled = (mHistoryPos > 0 && [mShownNodes count] >= 2);
    oGoForwardButton.enabled = (mHistoryPos >= 0 && mHistoryPos < [mShownNodes count]-1);
}

- (void)addLatestHistoryNode:(id<BADocumentNode>)aNode
{
    if (!aNode) {
        return;
    }
    [self removeFutureHitoryNodes];
    [mShownNodes addObject:aNode];
    mHistoryPos++;
    [self validateGoBackButtons];
}

- (void)removeFutureHitoryNodes
{
    [mShownNodes removeObjectsInRange:NSMakeRange(mHistoryPos+1, [mShownNodes count]-(mHistoryPos+1))];
}

- (void)incrementAddedNodeCount
{
    mAddedNodeCount++;
    [oAddedNodeCountField setStringValue:[NSString stringWithFormat:@"(nodes=%ld)", mAddedNodeCount]];
}

- (void)printShowingPrintPanel:(BOOL)flag
{
    NSPrintInfo *printInfo = [self printInfo];
    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:[[[oWebView mainFrame] frameView] documentView] printInfo:printInfo];
    [printOp setShowsPrintPanel:flag];
    [printOp setCanSpawnSeparateThread:YES];

    [printOp runOperationModalForWindow:oMainWindow
                               delegate:nil 
                         didRunSelector:NULL 
                            contextInfo:NULL];
}


//-------------------------------------------------------------------------
#pragma mark ==== アウトラインビューとブラウザでのキー操作のサポート ====
//-------------------------------------------------------------------------

- (void)activateWebView
{
    [oMainWindow makeFirstResponder:oWebView];
}

- (void)activateBrowser
{
    [oMainWindow makeFirstResponder:oBrowser];
    
    if ([oBrowser selectedColumn] >= 1) {
        NSInteger selectedRow = [oBrowser selectedRowInColumn:2];
        if (selectedRow < 0) {
            if ([self selectedGroupLevelNode].childNodeCount > 0) {
                [oBrowser selectRow:0 inColumn:2];
            }
        }
    } else {
        NSInteger selectedRow = [oBrowser selectedRowInColumn:0];
        if (selectedRow < 0) {
            if ([self selectedCategory].childNodeCount > 0) {
                [oBrowser selectRow:0 inColumn:0];
            }
        }
    }
}

- (void)activateDocSetListView
{
    [oMainWindow makeFirstResponder:oDocSetListView];
}

- (void)clearCurrentSearchWord
{
    // 最初のカラムが選択されていれば左側の検索フィールドのクリア
    if ([oBrowser selectedColumn] == 0) {
        [oClassLevelSearchField setStringValue:@""];
    }
    // それ以外の場合は右側の検索フィールドのクリア
    else {
        [oMethodLevelSearchField setStringValue:@""];
    }
}

- (void)startSearchWithString:(NSString *)str
{
    // 最初のカラムが選択されていれば左側の検索フィールドのセット
    if (([oBrowser selectedColumn] == 0 || ![self selectedGroupLevelNode]) && [self selectedCategory]) {
        [oMainWindow makeFirstResponder:oClassLevelSearchField];
        [oClassLevelSearchField setStringValue:str];

        // 末尾の選択
        NSTextView *fieldEditor = (NSTextView *)[oMainWindow fieldEditor:NO forObject:oClassLevelSearchField];
        [fieldEditor setSelectedRange:NSMakeRange([str length], 0)];
        
        // 検索の開始
        [self changedClassLevelSearchString:self];
    }
    // それ以外の場合は右側の検索フィールドのセット
    else if ([self selectedGroupLevelNode]) {
        [oMainWindow makeFirstResponder:oMethodLevelSearchField];
        [oMethodLevelSearchField setStringValue:str];

        // 末尾の選択
        NSTextView *fieldEditor = (NSTextView *)[oMainWindow fieldEditor:NO forObject:oMethodLevelSearchField];
        [fieldEditor setSelectedRange:NSMakeRange([str length], 0)];

        // 検索の開始
        [self changedMethodLevelSearchString:self];
    }
    // 入力できない場合は警告
    else {
        NSBeep();
    }
}


//-------------------------------------------------------------------------
#pragma mark ==== ドキュメントノードの取得メソッド ====
//-------------------------------------------------------------------------

- (BADocSet *)selectedRootDocSet
{
    NSInteger selectedRow = [oDocSetListView selectedRow];
    if (selectedRow >= 0) {
        id<BADocumentNode> selectedItem = [oDocSetListView itemAtRow:selectedRow];
        return [selectedItem docSet];
    }
    return nil;
}

- (BADocCategory *)selectedCategory
{
    NSInteger selectedRow = [oDocSetListView selectedRow];
    id selectedItem = [oDocSetListView itemAtRow:selectedRow];
    if (![selectedItem isKindOfClass:[BADocCategory class]]) {
        return nil;
    }
    return (BADocCategory *)selectedItem;
}

- (BAClassLevelNode *)selectedClassLevelNode
{
    BADocCategory *category = [self selectedCategory];
    if (!category) {
        return nil;
    }
    
    int selectedRow = (int)[oBrowser selectedRowInColumn:0];
    if (selectedRow < 0) {
        return nil;
    }
    return (BAClassLevelNode *)[category childNodeAtIndex:selectedRow];
}

- (BAGroupLevelNode *)selectedGroupLevelNode
{
    if ([oBrowser selectedColumn] == 0) {
        return nil;
    }
    
    BAClassLevelNode *classLevelNode = [self selectedClassLevelNode];
    if (!classLevelNode) {
        return nil;
    }
    
    int selectedRow = (int)[oBrowser selectedRowInColumn:1];
    if (selectedRow < 0) {
        return nil;
    }
    return (BAGroupLevelNode *)[classLevelNode childNodeAtIndex:selectedRow];
}

- (BAMethodLevelNode *)selectedMethodLevelNode
{
    BAGroupLevelNode *groupLevelNode = [self selectedGroupLevelNode];
    if (!groupLevelNode) {
        return nil;
    }
    
    int selectedRow = (int)[oBrowser selectedRowInColumn:2];
    if (selectedRow < 0) {
        return nil;
    }
    return (BAMethodLevelNode *)[groupLevelNode childNodeAtIndex:selectedRow];
}

- (id<BADocumentNode>)previewingNode
{
    return mPreviewingNode;
}


//-------------------------------------------------------------------------
#pragma mark ==== 左側のアウトラインビューの Data Source & Delegate ====
//-------------------------------------------------------------------------

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if ([BAReferenceLibrary sharedInstance].isCheckingEnvironment) {
        return nil;
    }
    // Root
    if (!item) {
        return [[BAReferenceLibrary sharedInstance] docSetAtIndex:index];
    }
    return [item childNodeAtIndex:index];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ([BAReferenceLibrary sharedInstance].isCheckingEnvironment) {
        return 0;
    }
    // Root
    if (!item) {
        return [[BAReferenceLibrary sharedInstance] docSetCount];
    }
    return [item childNodeCount];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    BAOutlineViewCell *cell = [tableColumn dataCell];
    cell.node = item;
    return ((id<BADocumentNode>)item).localizedTitle;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    // キーボードの矢印キーでブラウズ移動できるように、すべてのノード選択を可能にする
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    // Don't use the group in Mac OS X 10.7
    if (NSClassFromString(@"NSFileCoordinator")) {
        return NO;
    }

    // DocSet
    if ([item isKindOfClass:[BADocSet class]]) {
        return YES;
    }
    // Folder
    /*if ([item isKindOfClass:[BADocFolder class]]) {
     return YES;
     }*/
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // DocSet
    if ([item isKindOfClass:[BADocSet class]]) {
        return YES;
    }
    // Folder
    else if ([item isKindOfClass:[BADocFolder class]]) {
        return YES;
    }
    // Reference
    else if ([item isKindOfClass:[BADocReference class]]) {
        return YES;
    }
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [oDocSetListView selectedRow];
    if (selectedRow == mSelectedDocSetListViewIndex) {
        return;
    }
    mSelectedDocSetListViewIndex = selectedRow;
    [oBrowser loadColumnZero];
    [oBrowser reloadColumn:0];

    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reflectOutlineViewSelectionChange:) userInfo:nil repeats:NO];
}

- (void)reflectOutlineViewSelectionChange:(NSTimer *)timer
{    
    if ([oBrowser selectedColumn] < 2 && [[oMethodLevelSearchField stringValue] length] > 0) {
        [oMethodLevelSearchField setStringValue:@""];
        [mLastFilteredGroupLevelNode clearSearchString];
        mLastFilteredGroupLevelNode = nil;
    }
    
    if (mLastFilteredCategoryNode && [self selectedCategory] != mLastFilteredCategoryNode) {
        [oClassLevelSearchField setStringValue:@""];
        [mLastFilteredCategoryNode clearSearchString];
        mLastFilteredCategoryNode = nil;
    }
    
    [oClassLevelSearchField setEnabled:([self selectedCategory]? YES: NO)];
    [oMethodLevelSearchField setEnabled:([self selectedGroupLevelNode]? YES: NO)];
 
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reloadBrowserFirstColumn:) userInfo:nil repeats:NO];

    NSInteger selectedRow = [oDocSetListView selectedRow];
    if (!mForcedNavigating && selectedRow >= 0) {
        NSObject<BADocumentNode> *selectedNode = [oDocSetListView itemAtRow:selectedRow];
        if ([selectedNode isKindOfClass:[BADocCategory class]]) {
            [self addLatestHistoryNode:selectedNode];
        }
    }
}

- (void)reloadBrowserFirstColumn:(NSTimer *)timer
{
    [oBrowser reloadColumn:0];
}


//-------------------------------------------------------------------------
#pragma mark ==== ブラウザビューの Delegate ====
//-------------------------------------------------------------------------

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
    if (column == 0) {
        return [self selectedCategory].childNodeCount;
    }
    else if (column == 1) {
        return [self selectedClassLevelNode].childNodeCount;
    }
    else if (column == 2) {
        return [self selectedGroupLevelNode].childNodeCount;
    }
    return 0;
}

- (void)browser:(NSBrowser *)browser didChangeLastColumn:(NSInteger)oldLastColumn toColumn:(NSInteger)column
{
    // Do nothing
}

- (void)setHTMLSource:(NSString *)htmlSource
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *cssFilePath = [bundle pathForResource:@"stylesheet" ofType:@"css"];
    NSData *cssData = [NSData dataWithContentsOfFile:cssFilePath];
    NSString *cssStr = [[[NSString alloc] initWithData:cssData encoding:NSUTF8StringEncoding] autorelease];
    cssStr = [NSString stringWithFormat:@"<html lang=\"en\"><head><style type=\"text/css\">\n<!--\n%@\n-->\n</style></head><body>\n", cssStr];
    
    htmlSource = [cssStr stringByAppendingString:htmlSource];
    
    [[oWebView mainFrame] loadHTMLString:htmlSource baseURL:nil];
    
    //NSMutableAttributedString *sourceAttrStr = [oSourceView textStorage];
    //[sourceAttrStr setAttributedString:[[[NSAttributedString alloc] initWithString:htmlSource] autorelease]];
}

- (IBAction)browserSelectionChanged:(id)sender
{    
    NSInteger column = [oBrowser selectedColumn];
    
    if (column < 2 && mLastFilteredGroupLevelNode != [self selectedGroupLevelNode]) {
        [oMethodLevelSearchField setStringValue:@""];
        [mLastFilteredGroupLevelNode clearSearchString];
        mLastFilteredGroupLevelNode = nil;
    }

    if (column == 0) {
        BAClassLevelNode *classNode = [self selectedClassLevelNode];
        if (!classNode.hasLoaded) {
            [self startLoadingContent];
            [classNode loadContent];
            [self finishLoadingContent];
        }
        [oBrowser reloadColumn:1];
        [oBrowser reloadColumn:2];
        mPreviewingNode = classNode;
        NSString *contentHTML = classNode.contentHTMLSource;
        if (!contentHTML) {
            contentHTML = @"";
        }
        [self setHTMLSource:contentHTML];
        [oClassLevelSearchField setEnabled:YES];
        [oMethodLevelSearchField setEnabled:NO];
        
        if (!mForcedNavigating) {
            [self addLatestHistoryNode:classNode];
        }
    } else if (column == 1) {
        BAGroupLevelNode *groupNode = [self selectedGroupLevelNode];
        mPreviewingNode = groupNode;
        NSString *contentHTML = groupNode.contentHTMLSource;
        if (!contentHTML) {
            contentHTML = @"";
        }
        [self setHTMLSource:contentHTML];
        [oMethodLevelSearchField setEnabled:YES];

        if (!mForcedNavigating) {
            [self addLatestHistoryNode:groupNode];
        }
    } else if (column == 2) {
        BAMethodLevelNode *methodNode = [self selectedMethodLevelNode];
        mPreviewingNode = methodNode;
        NSString *contentHTML = methodNode.contentHTMLSource;
        if (!contentHTML) {
            contentHTML = @"";
        }
        [self setHTMLSource:contentHTML];

        if (!mForcedNavigating) {
            [self addLatestHistoryNode:methodNode];
        }
    }
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
    if (column == 0) {
        BADocCategory *category = [self selectedCategory];
        BAClassLevelNode *classLevelNode = (BAClassLevelNode *)[category childNodeAtIndex:row];
        [cell setStringValue:classLevelNode.title];
        [cell setImage:classLevelNode.iconImage];
        [cell setLeaf:NO];
    }
    else if (column == 1) {
        BAClassLevelNode *classLevelNode = [self selectedClassLevelNode];
        BAGroupLevelNode *groupLevelNode = (BAGroupLevelNode *)[classLevelNode childNodeAtIndex:row];
        [cell setStringValue:groupLevelNode.localizedTitle];
        [cell setLeaf:([groupLevelNode childNodeCount] == 0)? YES: NO];
    }
    else if (column == 2) {
        BAGroupLevelNode *groupLevelNode = [self selectedGroupLevelNode];
        BAMethodLevelNode *methodLevelNode = (BAMethodLevelNode *)[groupLevelNode childNodeAtIndex:row];
        [cell setStringValue:methodLevelNode.title];
        [cell setLeaf:YES];
    }
}


//-------------------------------------------------------------------------
#pragma mark ==== Webビューの Delegate ====
//-------------------------------------------------------------------------

- (void)webView:(WebView *)webView
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    // クリック処理だけ奪う
    WebNavigationType navType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
    if (navType != WebNavigationTypeLinkClicked) {
        [listener use];
        return;
    }
    [listener ignore];
    
    // 独自処理の実装
    NSURL *targetURL = [request URL];
    NSArray *nodes = [[BAReferenceLibrary sharedInstance] nodesToURL:targetURL startNode:mPreviewingNode];
    
    if (nodes) {
        [self addLatestHistoryNode:[nodes lastObject]];
        mForcedNavigating = YES;
        [NSTimer scheduledTimerWithTimeInterval:0
                                         target:self
                                       selector:@selector(showFirstNodeInArray:)
                                       userInfo:[NSMutableArray arrayWithArray:nodes]
                                        repeats:NO];
    } else {
        NSLog(@"Cannot find target jump target for URL: %@", targetURL);
        [[NSWorkspace sharedWorkspace] openURL:targetURL];
    }
}

- (void)showFirstNodeInArray:(NSTimer *)timer
{
    NSMutableArray *nodes = [timer userInfo];
    NSObject<BADocumentNode> *node = [nodes objectAtIndex:0];
    [nodes removeObjectAtIndex:0];
    
    if ([node isKindOfClass:[BADocFolder class]]
        || [node isKindOfClass:[BADocReference class]]
        || [node isKindOfClass:[BADocCategory class]])
    {
        NSInteger row = [oDocSetListView rowForItem:node];
        if (row >= 0) {
            if ([oDocSetListView isExpandable:node]) {
                [oDocSetListView expandItem:node];
            }
            if ([self outlineView:oDocSetListView shouldSelectItem:node]) {
                [oDocSetListView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            }
            [oMainWindow makeFirstResponder:oDocSetListView];
        } else {
            NSLog(@"Failed to show node(1): %@", node);
            return;
        }
    } else {
        if ([node isKindOfClass:[BAClassLevelNode class]]) {
            NSInteger classLevelNodeIndex = [node indexAtParentNode];
            if (classLevelNodeIndex >= 0) {
                [oBrowser selectRow:classLevelNodeIndex inColumn:0];
                [oMainWindow makeFirstResponder:oBrowser];
                [self browserSelectionChanged:self];
            }
            else {
                NSLog(@"Failed to show node(2): %@", node);
                return;
            }
        }
        else if ([node isKindOfClass:[BAGroupLevelNode class]]) {
            NSInteger groupLevelNodeIndex = [node indexAtParentNode];
            if (groupLevelNodeIndex >= 0) {
                [oBrowser selectRow:groupLevelNodeIndex inColumn:1];
                [oMainWindow makeFirstResponder:oBrowser];
                [self browserSelectionChanged:self];
            }
            else {
                NSLog(@"Failed to show node(3): %@", node);
                return;
            }
        }
        else if ([node isKindOfClass:[BAMethodLevelNode class]]) {
            NSInteger methodLevelNodeIndex = [node indexAtParentNode];
            if (methodLevelNodeIndex >= 0) {
                [oBrowser selectRow:methodLevelNodeIndex inColumn:2];
                [oMainWindow makeFirstResponder:oBrowser];
                [self browserSelectionChanged:self];
            }
            else {
                NSLog(@"Failed to show node(4): %@", node);
                return;
            }
        }
    }
    
    if ([nodes count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0
                                         target:self
                                       selector:@selector(showFirstNodeInArray:)
                                       userInfo:nodes
                                        repeats:NO];
    } else {
        [NSTimer scheduledTimerWithTimeInterval:0
                                         target:self
                                       selector:@selector(finishForcedNavigating:)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)finishForcedNavigating:(NSTimer *)timer
{
    mForcedNavigating = NO;
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [oTopBarBackLeft setNeedsDisplay:YES];
    [oTopBarBackRight setNeedsDisplay:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [oTopBarBackLeft setNeedsDisplay:YES];
    [oTopBarBackRight setNeedsDisplay:YES];
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSRect browserRect = [oBrowser frame];
    CGFloat baseWidth = (browserRect.size.width - 2) / 3;
    
    NSRect classLevelSearchFieldRect = [oClassLevelSearchField frame];
    classLevelSearchFieldRect.size.width = baseWidth - 24;
    [oClassLevelSearchField setFrame:classLevelSearchFieldRect];

    NSRect methodLevelSearchFieldRect = [oMethodLevelSearchField frame];
    methodLevelSearchFieldRect.origin.x = baseWidth * 2 + 8;
    methodLevelSearchFieldRect.size.width = baseWidth - 24;
    [oMethodLevelSearchField setFrame:methodLevelSearchFieldRect];
}

@end


@implementation BAWindowController

- (NSString*)windowTitleForDocumentDisplayName:(NSString*)displayName
{
    return @"Cocoa Browser Air";
}

@end

