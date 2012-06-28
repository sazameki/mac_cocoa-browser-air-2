#import <Cocoa/Cocoa.h>
#import "BADocumentNode.h"


@interface BAOutlineViewCell : NSCell {
    NSObject<BADocumentNode>    *mNode;
}

@property(readwrite, assign) NSObject<BADocumentNode>   *node;

@end


