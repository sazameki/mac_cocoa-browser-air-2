//
//  BAHTMLParser.h
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SZHTMLParser.h"


@class BAHTMLParser;


@protocol BAHTMLParserDelegate
@optional
- (void)htmlParserStarted:(BAHTMLParser *)parser;

// htmlParserFinished: はエラーが起きても呼ばれる。
- (void)htmlParserFinished:(BAHTMLParser *)parser;

- (void)htmlParserFacedWarning:(BAHTMLParser *)warning;
- (void)htmlParserFacedError:(BAHTMLParser *)error;
- (void)htmlParserFacedFatalError:(BAHTMLParser *)error;

@end


@interface BAHTMLParser : NSObject<SZHTMLParserDelegate> {
    SZHTMLParser    *mHTMLParser;
    NSURL           *mURL;
    
    NSObject<BAHTMLParserDelegate>  *mDelegate;
}

@property(readwrite, assign) NSObject<BAHTMLParserDelegate>   *delegate;

- (id)initWithURL:(NSURL *)url;
- (BOOL)parse;

- (NSURL *)URL;

@end

