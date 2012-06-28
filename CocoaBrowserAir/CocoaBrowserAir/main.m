//
//  main.m
//  CocoaBrowserAir
//
//  Created by numata on 11/05/10.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "validatereceipt.h"


const NSString * gAppBundleVersion = @"4.5";
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
#ifndef DEBUG
    if (!checkAppReceipt()) {
        exit(173);
    }
#else
    NSLog(@"Starting with DEBUG Mode");
#endif
    return NSApplicationMain(argc, (const char **)argv);
}

