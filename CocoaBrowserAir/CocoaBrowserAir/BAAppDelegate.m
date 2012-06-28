//
//  BAAppDelegate.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import "BAAppDelegate.h"
#import "BAReferenceLibrary.h"
#import "BADocument.h"


@interface BAReferenceLibrary()

- (void)checkEnvironment;

@end


static BAAppDelegate    *sInstance = nil;


@implementation BAAppDelegate

+ (void)initialize
{
    NSUserDefaultsController *defController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUserDefaults *defaults = [defController defaults];
    if (![defaults objectForKey:@"useOfflineDocSets"]) {
        [defaults setBool:YES forKey:@"useOfflineDocSets"];
    }
    if (![defaults objectForKey:@"useOnlineDocSets"]) {
        [defaults setBool:YES forKey:@"useOnlineDocSets"];
    }
    [defaults synchronize];
}

+ (BAAppDelegate *)sharedInstance
{
    return sInstance;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    sInstance = self;
    [[BAReferenceLibrary sharedInstance] checkEnvironment];
}

- (void)finishedCheckingEnvironment
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (NSDocument *aDocument in [docController documents]) {
        if ([aDocument isKindOfClass:[BADocument class]]) {
            [(BADocument *)aDocument performSelectorOnMainThread:@selector(hideCheckingSheet) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)incrementCheckedTargetCount
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (NSDocument *aDocument in [docController documents]) {
        if ([aDocument isKindOfClass:[BADocument class]]) {
            [(BADocument *)aDocument performSelectorOnMainThread:@selector(incrementCheckedTargetCount) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)incrementAddedNodeCount
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (NSDocument *aDocument in [docController documents]) {
        if ([aDocument isKindOfClass:[BADocument class]]) {
            [(BADocument *)aDocument performSelectorOnMainThread:@selector(incrementAddedNodeCount) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)setCheckTargetCount:(NSInteger)count
{
    mCheckTargetCount = count;
}

- (NSInteger)checkTargetCount
{
    return mCheckTargetCount;
}

- (void)showPreferencesPanel:(id)sender
{
    if (![oSettingPanel isVisible]) {
        [oSettingPanel center];
    }
    [oSettingPanel makeKeyAndOrderFront:self];
}

- (void)startLoadingContent
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (NSDocument *aDocument in [docController documents]) {
        if ([aDocument isKindOfClass:[BADocument class]]) {
            [(BADocument *)aDocument performSelectorOnMainThread:@selector(startLoadingContent) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)finishLoadingContent
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (NSDocument *aDocument in [docController documents]) {
        if ([aDocument isKindOfClass:[BADocument class]]) {
            [(BADocument *)aDocument performSelectorOnMainThread:@selector(finishLoadingContent) withObject:nil waitUntilDone:NO];
        }
    }
}

@end

