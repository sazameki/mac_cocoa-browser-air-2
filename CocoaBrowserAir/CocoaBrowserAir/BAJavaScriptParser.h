//
//  BAJavaScriptParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/27.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "BAHTMLParser.h"


@interface BAJavaScriptParser : BAHTMLParser {
}

+ (NSDictionary *)parseJavaScriptArray:(NSString *)scriptSource;

@end

