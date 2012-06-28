//
//  BAWebView.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/15.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <WebKit/WebKit.h>


@class BADocument;


@interface BAWebView : WebView {
    IBOutlet BADocument     *oDocument;
}

@end

