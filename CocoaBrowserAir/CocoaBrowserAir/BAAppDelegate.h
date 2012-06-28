//
//  BAAppDelegate.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BAAppDelegate : NSObject {
    IBOutlet NSPanel    *oSettingPanel;
    
    NSInteger   mCheckTargetCount;
}

+ (BAAppDelegate *)sharedInstance;

- (void)finishedCheckingEnvironment;
- (void)setCheckTargetCount:(NSInteger)count;
- (void)incrementCheckedTargetCount;
- (void)incrementAddedNodeCount;
- (NSInteger)checkTargetCount;

- (void)startLoadingContent;
- (void)finishLoadingContent;

@end

