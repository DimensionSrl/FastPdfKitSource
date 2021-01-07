//
//  MFTextStateWholeExtraction.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/30/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFTextState.h"
#import "unbuffer.h"
#define DEF_BUFFER_SIZE 256

@interface MFTextStateSmartExtraction : MFTextState {

	NSMutableString *textBuffer;
	
	unsigned int * unicodeBuffer;
	int unicodeBufferSize;
	int unicodeBufferMaxSize;
    
    CGPoint lastTextPoint;
    
    int growthBias;
    
    unbuffer unbuffer;
}

@property (readonly) NSString *textBuffer;

@end
