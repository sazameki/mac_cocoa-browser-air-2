//
//  BAHTMLParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "BAHTMLParser.h"


@interface BAHTMLParser()

- (void)parseProc:(id)dummy;

@end


@implementation BAHTMLParser

@synthesize delegate = mDelegate;

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        mURL = [url retain];
    }
    return self;
}

- (void)dealloc
{
    [mURL release];
    [super dealloc];
}

- (NSURL *)URL
{
    return mURL;
}

- (BOOL)parse
{
    //[NSThread detachNewThreadSelector:@selector(parseProc:) toTarget:self withObject:nil];
    [self parseProc:self];
    return YES;
}

- (void)parseProc:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(htmlParserStarted:)]) {
        [mDelegate performSelectorOnMainThread:@selector(htmlParserStarted:) withObject:self waitUntilDone:NO];
    }
    
    mHTMLParser = [[SZHTMLParser alloc] init];
    mHTMLParser.delegate = self;
    mHTMLParser.encoding = NSUTF8StringEncoding;

    NSData *htmlData = [[NSData alloc] initWithContentsOfURL:mURL];
    [mHTMLParser parseHTMLData:htmlData];
    [htmlData release];

    [mHTMLParser release];
    
    if (mDelegate && [mDelegate respondsToSelector:@selector(htmlParserFinished:)]) {
        [mDelegate performSelectorOnMainThread:@selector(htmlParserFinished:) withObject:self waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)htmlParserStart:(SZHTMLParser *)parser
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser foundComment:(NSString *)comment
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser foundText:(NSString *)text
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser endTag:(NSString *)tagName
{
    // Do nothing
}

- (void)htmlParserEnd:(SZHTMLParser *)parser
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser willUseSubsetWithExternalID:(NSString *)externalID systemID:(NSString *)systemID
{
    // Do nothing
}

- (void)htmlParser:(SZHTMLParser *)parser warning:(NSString *)warning
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(htmlParserFacedWarning:)]) {
        [mDelegate performSelectorOnMainThread:@selector(htmlParserFacedWarning:) withObject:warning waitUntilDone:NO];
    }
}

- (void)htmlParser:(SZHTMLParser *)parser error:(NSString *)error
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(htmlParserFacedError:)]) {
        [mDelegate performSelectorOnMainThread:@selector(htmlParserFacedError:) withObject:error waitUntilDone:NO];
    }
}

- (void)htmlParser:(SZHTMLParser *)parser fatalError:(NSString *)error
{
    if (mDelegate && [mDelegate respondsToSelector:@selector(htmlParserFacedFatalError:)]) {
        [mDelegate performSelectorOnMainThread:@selector(htmlParserFacedFatalError:) withObject:error waitUntilDone:NO];
    }
}

@end

