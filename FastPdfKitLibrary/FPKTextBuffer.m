//
//  FPKTextBuffer.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 27/27/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "FPKTextBuffer.h"
#import "Stuff.h"

#define DEF_BUFFER_SIZE 256

@implementation FPKTextBuffer

-(id)init
{
    self = [super init];
    if(self)
    {
        unicodeBuffer = calloc(DEF_BUFFER_SIZE,sizeof(unsigned int));
		unicodeBufferSize = 0;
		unicodeBufferMaxSize = DEF_BUFFER_SIZE;
        currentTextPosition = 0;
    }
    return self;
}

-(void)appendUnicodeToBuffer:(unsigned int *) unicode length:(int)length {
	
	if((unicodeBufferSize+length) >= unicodeBufferMaxSize)
    {
        int newSize = unicodeBufferMaxSize + DEF_BUFFER_SIZE;
     
        unsigned int * tmp = calloc(newSize,sizeof(unsigned int));
		memcpy(tmp,unicodeBuffer,unicodeBufferMaxSize * (sizeof(unsigned int)));
		free(unicodeBuffer);
		unicodeBuffer = tmp;
		unicodeBufferMaxSize = newSize;	
	}
	
    int index;
    for(index = 0; index < length; index++) {
        unicodeBuffer[unicodeBufferSize++] = unicode[index];
        currentTextPosition++;
    }
}

-(unsigned int *)backingBuffer
{
    return unicodeBuffer;
}

-(unsigned int)length
{
    return unicodeBufferSize;
}

-(unsigned int) lastUnicode {
    
    if(unicodeBufferSize > 0) {
        return unicodeBuffer[unicodeBufferSize-1];
    }
    return 0;
}

-(void)dealloc
{
    MF_C_FREE(unicodeBuffer);
    
    [super dealloc];
}

@end
