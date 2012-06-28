//
//  SZHTMLParser.h
//
//  Created by numata on 09/03/01.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SZHTMLParser;


@protocol SZHTMLParserDelegate

@optional
- (void)htmlParserStart:(SZHTMLParser *)parser;
- (void)htmlParser:(SZHTMLParser *)parser willUseSubsetWithExternalID:(NSString *)externalID systemID:(NSString *)systemID;
- (void)htmlParserEnd:(SZHTMLParser *)parser;

- (void)htmlParser:(SZHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs;
- (void)htmlParser:(SZHTMLParser *)parser foundText:(NSString *)text;
- (void)htmlParser:(SZHTMLParser *)parser foundComment:(NSString *)comment;
- (void)htmlParser:(SZHTMLParser *)parser foundIgnorableWhitespace:(NSString *)str;
- (void)htmlParser:(SZHTMLParser *)parser endTag:(NSString *)tagName;

- (void)htmlParser:(SZHTMLParser *)parser warning:(NSString *)warning;
- (void)htmlParser:(SZHTMLParser *)parser error:(NSString *)error;
- (void)htmlParser:(SZHTMLParser *)parser fatalError:(NSString *)error;

@end


@interface SZHTMLParser : NSObject {
    NSObject<SZHTMLParserDelegate>  *mDelegate;
    NSStringEncoding                mEncoding;
}

@property(readwrite, assign) NSObject<SZHTMLParserDelegate> *delegate;
@property(readwrite, assign) NSStringEncoding               encoding;

- (BOOL)parseHTML:(NSString *)htmlStr;
- (BOOL)parseHTMLData:(NSData *)htmlData;

@end

