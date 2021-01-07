//
//  MFTextBox.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFTextBox.h"
#import "mffontencoding.h"
#import "Stuff.h"
#import "FPKTextBuffer.h"

@implementation MFGlyphQuad

-(id)init {
	
	if((self = [super init])) {
		_transform = CGAffineTransformIdentity;
		_box = CGRectZero;
	}
	
	return self;
}

-(id)initWithBox:(CGRect *) aBox andTranfrom:(CGAffineTransform *)aTransform {
	if((self = [super init])) {
		_transform = *aTransform;
		_box = *aBox;
	}
	return self;
}

-(id)initWithX:(float)x Y:(float)y width:(float)w height:(float)h andTranfrom:(CGAffineTransform *)aTransform {
	
	if((self = [super init])) {
		
		_transform = *aTransform;
		_box = CGRectMake(x, y, w, h);
	}
	
	return self;
}

-(void)extendBox:(CGRect)anotherBox {
    _box = CGRectUnion(_box, anotherBox);
}

@end

@implementation MFTextBox

@synthesize quads,text;
@synthesize startPosition,endPosition;
@synthesize searchTermRange;
@synthesize completed;

-(void)discardLastGlyphQuad {
    [quads removeLastObject];
}

-(MFGlyphQuad *)lastGlyphQuad {
    return [quads lastObject];
}

-(void)sampleTextFromUnicodeBuffer:(FPKTextBuffer *)buffer
{
    unsigned int * unicodeBuffer = [buffer backingBuffer];
    int length = [buffer length];
    
    [self sampleTextFromUnicodeBuffer:unicodeBuffer length:length];
}

-(void) sampleTextFromUnicodeBuffer:(unsigned int *)buffer length:(int)length{
	
    NSData * data = nil;
    NSString * sample = nil;
    
    int unicode_length;
    unsigned int * unicode = NULL;
    
    int leftmostPosition = startPosition - 25;
	int rightmostPosition = endPosition + 35;
	
    unsigned char * utf8_buffer = NULL;
    int utf8_length, utf8_size;
    
    int chunk_length;
    int index;
    
	// Calculate the slice of unicode buffer to convert into NSString.
	
	if(leftmostPosition < 0)
		leftmostPosition = 0;
	
	if(rightmostPosition >= length)
		rightmostPosition = length-1;
	
	// Lenght of the slice.
	
	unicode_length = rightmostPosition-leftmostPosition+1;
	
	// Allocate a dynamic utf8buffer.
	
	utf8_buffer = calloc(unicode_length, sizeof(char));	// Buffer.
	utf8_length = 0;									// Lenght of bytes written into the buffer.
	utf8_size = unicode_length;                         // Size.
    
	// Write each unicode into the utf8 buffer with the utility method.
	for(index = 0; index < unicode_length; index++) {
        
        unicode = (buffer + leftmostPosition + index);
        
        chunk_length = unicodeToUTF8BufferSpaceRequired((*unicode));
        
        if(utf8_length + chunk_length >= utf8_size) {
            
            int new_size = utf8_size + unicode_length;
            unsigned char * tmp = calloc(new_size, sizeof(unsigned char));
            memcpy(tmp, utf8_buffer, utf8_length);
            utf8_size = new_size;
            
            free(utf8_buffer);
            
            utf8_buffer = tmp;
        }
        
		utf8_length+=writeUnicodeToUTF8Buffer(unicode, (utf8_buffer+utf8_length));
	}
	
	// Allocate the data, then the NSString.
	
	data = [[NSData alloc]initWithBytes:utf8_buffer length:utf8_length];
	
	sample = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    if(!sample)
    {
        sample = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
    }
	
	self.text = sample;
	
	searchTermRange = NSMakeRange((startPosition - leftmostPosition), (endPosition - startPosition + 1));
	
	// Cleanup.
	MF_C_FREE(utf8_buffer);
	[sample release];
	[data release];
}


-(id)init {
	
	if((self = [super init])) {
		text = nil;
		
		NSMutableArray *tmp = [[NSMutableArray alloc]init];
		self.quads = tmp;
		[tmp release];
	}
	
	return self;
}

-(void)dealloc {

	[text release],text = nil;
 	[quads release],quads = nil;
	
	[super dealloc];
}


-(void)addGlyphQuad:(MFGlyphQuad *)quad {
	
	[quads addObject:quad];
}

@end
