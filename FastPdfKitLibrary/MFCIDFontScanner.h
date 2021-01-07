//
//  MFCIDFontScanner.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "mftypefontsupport.h"

@class MFCIDCluster;
@interface MFCIDFontScanner : NSObject {
    
    char * stringbuffer;
    MFCIDCluster * cidRanges;
    MFCIDCluster * notdefCids;
    NSUInteger writingMode;
}

@property (nonatomic, readwrite) char * stringbuffer;
@property (nonatomic, assign) MFCIDCluster * cidRanges;
@property (nonatomic, assign) MFCIDCluster * notdefCids;
@property (nonatomic, readonly) NSUInteger writingMode;

-(void)scan;

@end
