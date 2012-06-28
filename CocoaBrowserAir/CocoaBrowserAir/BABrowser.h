//
//  BABrowser.h
//  CocoaBrowserAir
//
//  Created by numata on 11/05/14.
//  Copyright 2011 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BADocument;


@interface BABrowser : NSBrowser {
@private
    IBOutlet BADocument     *oDocument;
}

@end

