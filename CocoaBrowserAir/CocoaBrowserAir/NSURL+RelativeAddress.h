//
//  NSURL+RelativeAddress.h
//  Cocoa Browser Air
//
//  Created by numata on 09/08/31.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (RelativeAddress)

+ (id)numataURLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL;

- (NSURL *)numataStandardizedURL;

@end



