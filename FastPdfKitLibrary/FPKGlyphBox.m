//
//  MFGlyphBox.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FPKGlyphBox.h"
#import "mffontencoding.h"

@interface FPKGlyphBox() 

@property (nonatomic,retain) NSString * _text;

@end

@implementation FPKGlyphBox

@synthesize synthesized;
@synthesize _text;
@synthesize box;
@synthesize origin, width, ascent, descent;

-(CGRect)box {
    
    if(CGRectIsNull(box)) {
        
        box = CGRectStandardize(CGRectMake(origin.x, (origin.y - ascent), width, (ascent - descent)));
    }
    
    return box;
}

-(id)initWithBox:(CGRect)aBox unicodes:(unsigned int *)aUnicodeSequence length:(int)aLen {
    
    if((self = [super init])) {

        unicodes_len = aLen;
        unicodes = calloc(aLen,sizeof(unsigned int));
        memcpy(unicodes,aUnicodeSequence,aLen * sizeof(unsigned int));
        
        box = aBox;
    }
    
    return self;
}

-(NSString *)text {
    
    if(!_text) {
        
        self._text = [FPKGlyphBox textFromBoxArray:[NSArray arrayWithObject:self]];
    }
    
    return _text;
}

-(void)dealloc {
    
    if(unicodes)
        free(unicodes);
    
    [_text release];
    
    [super dealloc];
}

+(NSString *)textFromBoxArray:(NSArray *)array {

    unsigned char * utf8_buffer;
    int utf8_buffer_size;
    int utf8_buffer_length;
    
    int box_count = [array count];
    int utf8_chunk_length;
    unsigned int unicode;
    unsigned int * unicodes;
    FPKGlyphBox * box;
    
    NSData * data = nil;
    NSString * text = nil;
    
    if(box_count <= 0)
        return nil; // Return early if empty
    
    utf8_buffer = calloc(box_count, sizeof(unsigned char));
    utf8_buffer_length = 0;
    utf8_buffer_size = box_count;
    
    for(id obj in array) {
        
        if(![obj isKindOfClass:[FPKGlyphBox class]])
            continue;   // Skip if not a GlyphBox
        
        box = (FPKGlyphBox *)obj;
        
        int i;
        unicodes = box->unicodes;
        
        for(i = 0; i < box->unicodes_len; i++) { // Loop on each unicode in the box (typically just one)
            
            unicode = unicodes[i];
            utf8_chunk_length = unicodeToUTF8BufferSpaceRequired(unicode);
            
            while(utf8_buffer_size <= utf8_buffer_length + utf8_chunk_length) {
                
                // Grow buffer if necessary
                
                int new_size = utf8_buffer_size * 2;
                unsigned char * tmp = NULL;
                
                if(!tmp) {
                    
                    tmp = calloc(new_size, sizeof(unsigned char));
                    memcpy(tmp,utf8_buffer,utf8_buffer_length);
                    
                    if(utf8_buffer)
                        free(utf8_buffer);
                }
                
                utf8_buffer_size = new_size;
                utf8_buffer = tmp;
            }
            
            utf8_buffer_length += writeUnicodeToUTF8Buffer(&unicode, utf8_buffer + utf8_buffer_length); // Write the unicode as UTF-8 byte array
        }
    } // End of box array loop
    
    if(utf8_buffer && (utf8_buffer_length > 0)) {
        
        // Build up the NSString from the buffer
        
        data = [[NSData alloc]initWithBytes:utf8_buffer length:utf8_buffer_length];
        
        text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        [data release];
    }
    
    if(utf8_buffer)
        free(utf8_buffer);
    
    return [text autorelease];
}

@end
