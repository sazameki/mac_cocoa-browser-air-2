//
//  CBAppController.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBNode.h"
#import <CoreServices/CoreServices.h>


@interface CBAppController : NSObject {
    IBOutlet    NSMenu      *oMenu;
    IBOutlet    NSPanel     *oPrefPanel;
    IBOutlet    NSTableView *oPlatformTable;
    
    IBOutlet    NSMenuItem  *oHideSearchBarMenuItem;
    
    NSMutableArray      *mPlatforms;
    
    CBNode              *mRootNode;
    
    CBNode              *mLoadTargetNode;
    NSString            *mLoadTargetURLStr;
    int                 mLoadTargetColumn;
    
    BOOL                mHidesSearchBarAutomatically;
    
    FSEventStreamRef    mFileEventSream;
    NSTimer             *mFileObservationTimer;
}

+ (CBAppController *)sharedAppController;

- (CBNode *)rootNode;

- (IBAction)showPreferences:(id)sender;
- (IBAction)setHidesSearchBarAutomatically:(id)sender;

- (void)updateFrameworkList;
- (void)updateBrowser;
- (void)updateColumn:(NSInteger)column;
- (void)updateWebView;

- (BOOL)hidesSearchBarAutomatically;

- (unsigned)installedPlatformCount;

@end


