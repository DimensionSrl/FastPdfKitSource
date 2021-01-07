//
//  MFToUnicodeCMapScannerMultibyte.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
// #import "mftypefontsupport.h"
#import "unbuffer.h"

@class MFUnicodeCluster;

@interface MFToUnicodeCMapScannerMultibyte : NSObject {
    
    MFUnicodeCluster * unicodeRanges;
    char * stringbuffer;
    unbuffer unbuffer;
    
    char * ut16buffer;
    int utf16bufferLength;
}

-(void)scan;

@property (nonatomic, readwrite) char * stringbuffer;
@property (nonatomic, assign) MFUnicodeCluster * unicodeRanges;

@end
