//
//  BAJavaScriptParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/27.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "BAJavaScriptParser.h"
#import "NSString+Tokenizer.h"
#import "NSString+JsonParser.h"


typedef enum {
    BAJavaScriptTypeJSON,
    BAJavaScriptTypeArray,
} BAJavaScriptType;


@interface BAJavaScriptParser()

- (void)parseJavaScriptInfos:(id)infos;

@end


@implementation BAJavaScriptParser

- (BOOL)parse
{
    [NSThread detachNewThreadSelector:@selector(parseProc:) toTarget:self withObject:nil];
    return YES;
}

- (BAJavaScriptType)checkJavaScriptTypeForSource:(NSString *)source
{
    NSUInteger pos = 0;
    NSUInteger length = [source length];
    while (pos < length) {
        unichar c = [source characterAtIndex:pos];
        
        // Skip Line Endings or white spaces
        if (c == '\r' || c == '\n' || isspace((int)c)) {
            pos++;
            continue;
        }
        
        // Skip Comment Lines
        if (c == '/') {
            pos++;
            if (pos < length) {
                do {
                    c = [source characterAtIndex:pos];
                    pos++;
                } while (pos < length && (c != '\r' && c != '\n'));
            }
            continue;
        }

        if (c == '[' || c == '{') {
            return BAJavaScriptTypeJSON;
        } else {
            return BAJavaScriptTypeArray;
        }
    }
    return BAJavaScriptTypeArray;
}

- (void)parseProc:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(htmlParserStarted:)]) {
        [self.delegate performSelectorOnMainThread:@selector(htmlParserStarted:) withObject:self waitUntilDone:NO];
    }
    
    NSData *theData = [[NSData alloc] initWithContentsOfURL:self.URL];
    NSString *sourceStr = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    
    BAJavaScriptType scriptType = [self checkJavaScriptTypeForSource:sourceStr];
    
    id infos = nil;
    if (scriptType == BAJavaScriptTypeJSON) {
        infos = [sourceStr jsonObject];
    } else {
        infos = [BAJavaScriptParser parseJavaScriptArray:sourceStr];
    }
    [self parseJavaScriptInfos:infos];
    
    [sourceStr release];
    [theData release];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(htmlParserFinished:)]) {
        [self.delegate performSelectorOnMainThread:@selector(htmlParserFinished:) withObject:self waitUntilDone:NO];
    }
    
    [pool release];
}

+ (NSDictionary *)parseJavaScriptArray:(NSString *)scriptSource
{
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];
    
    NSEnumerator *enums = [scriptSource tokenize:@"\n"];
    
    NSMutableArray *lines = [NSMutableArray array];
    
    NSString *indexStr = nil;
    for (NSString *aStr in enums) {
        aStr = [aStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aStr length] == 0) {
            continue;
        }
        if ([aStr hasSuffix:@"= new Array();"]) {
            continue;
        }
        NSEnumerator *parts = [aStr tokenize:@";"];
        for (NSString *aPart in parts) {
            aPart = [aPart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:aPart];
        }
    }
    
    for (NSString *aStr in lines) {
        NSEnumerator *substrs = [aStr tokenize:@"[]\"=\'"];
        NSString *header = [substrs nextObject];
        if (![header isEqualToString:@"docs"] && ![header isEqualToString:@"docElt"]) {
            continue;
        }
        NSString *key = [substrs nextObject];
        if (!key) {
            continue;
        }
        NSString *value = [substrs nextObject];
        while (value && [value length] == 1) {
            value = [substrs nextObject];
        }
        if (!value) {
            continue;
        }
        if ([key isEqualToString:@"title"]) {
            indexStr = value;
        }
        if (!indexStr) {
            continue;
        }
        NSMutableDictionary *anInfo = [infos objectForKey:indexStr];
        if (!anInfo) {
            anInfo = [NSMutableDictionary dictionary];
            [infos setObject:anInfo forKey:indexStr];
        }
        [anInfo setObject:value forKey:key];
    }
    
    return infos;
}

- (void)parseJavaScriptInfos:(id)infos
{
    // Do nothing
}

@end

