//
//  BADocument.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@class BATopBarBackgroundView;
@class BAImageButton;

@class BADocCategory;
@class BAGroupLevelNode;

@protocol BADocumentNode;


@interface BADocument : NSDocument {
@private
    IBOutlet NSWindow           *oMainWindow;
    IBOutlet NSOutlineView      *oDocSetListView;
    IBOutlet NSBrowser          *oBrowser;
    IBOutlet WebView            *oWebView;
    IBOutlet NSPanel            *oCheckingPanel;
    IBOutlet NSProgressIndicator    *oCheckingProgressIndicator;

    IBOutlet BATopBarBackgroundView *oTopBarBackLeft;
    IBOutlet BATopBarBackgroundView *oTopBarBackRight;
    
    IBOutlet NSSearchField      *oClassLevelSearchField;
    IBOutlet NSSearchField      *oMethodLevelSearchField;
    
    IBOutlet BAImageButton      *oGoBackwardButton;
    IBOutlet BAImageButton      *oGoForwardButton;
    
    IBOutlet NSProgressIndicator    *oLoadingIndicator;
    IBOutlet NSTextField        *oAddedNodeCountField;
    
    BADocCategory               *mLastFilteredCategoryNode;
    BAGroupLevelNode            *mLastFilteredGroupLevelNode;
    id<BADocumentNode>          mPreviewingNode;
    
    NSInteger                   mSelectedDocSetListViewIndex;
    
    NSInteger                   mCheckedTargetCount;
    NSInteger                   mAddedNodeCount;
    
    NSMutableArray              *mShownNodes;
    NSInteger                   mHistoryPos;
    BOOL                        mForcedNavigating;
}

// アクション
- (IBAction)browserSelectionChanged:(id)sender;
- (IBAction)goBackward:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)changedClassLevelSearchString:(id)sender;
- (IBAction)changedMethodLevelSearchString:(id)sender;
- (IBAction)activateClassLevelSearchField:(id)sender;
- (IBAction)activateMethodLevelSearchField:(id)sender;

// ヘルパメソッド
- (void)hideCheckingSheet;
- (void)splitViewResized;
- (void)startLoadingContent;
- (void)finishLoadingContent;
- (void)validateGoBackButtons;
- (void)removeFutureHitoryNodes;
- (void)incrementAddedNodeCount;

// アウトラインビューとブラウザでのキー操作のサポート
- (void)activateWebView;
- (void)activateBrowser;
- (void)activateDocSetListView;
- (void)startSearchWithString:(NSString *)str;
- (void)clearCurrentSearchWord;

@end

