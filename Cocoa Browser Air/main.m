//
//  main.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright Satoshi Numata 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "validatereceipt.h"


const NSString * gAppBundleVersion = @"4.3";
const NSString * gAppBundleIdentifier = @"jp.sazameki.CocoaBrowserAir2";


BOOL checkAppReceipt()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSURL *receiptURL = [[NSBundle mainBundle] bundleURL];
    receiptURL = [receiptURL URLByAppendingPathComponent:@"Contents"];
    receiptURL = [receiptURL URLByAppendingPathComponent:@"_MASReceipt"];
    receiptURL = [receiptURL URLByAppendingPathComponent:@"receipt"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[receiptURL path]]) {
        NSLog(@"No app receipt was found.");
        [pool release];
        return NO;
    }
    
    if (!validateReceiptAtURL(receiptURL)) {
        NSLog(@"Failed to validate the app receipt.");
        [pool release];
        return NO;
    }
    
    [pool release];    
    return YES;
}

int main(int argc, char *argv[])
{
#ifndef __DEBUG__
    if (!checkAppReceipt()) {
        exit(173);
    }
#endif
    return NSApplicationMain(argc, (const char **) argv);
}
