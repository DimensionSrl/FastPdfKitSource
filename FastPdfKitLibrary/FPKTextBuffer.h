//
//  FPKTextBuffer.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 27/27/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPKTextBuffer : NSObject
{
    unsigned int * unicodeBuffer;
	int unicodeBufferSize;
	int unicodeBufferMaxSize;
    int currentTextPosition;
}
 
-(void)appendUnicodeToBuffer:(unsigned int *)unicode length:(int)length;
-(unsigned int)lastUnicode;
-(unsigned int)length;
-(unsigned int *)backingBuffer;

@end
