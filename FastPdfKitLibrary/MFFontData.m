//
//  MFFontData.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFFontData.h"

#import "MFCIDCluster.h"
#import "MFWidthCluster.h"
#import "MFUnicodeCluster.h"
// #import "mftypefontsupport.h"

#define MF_FONT_TYPE0 0
#define MF_FONT_TYPE1 1
#define MF_FONT_TYPE3 2
#define MF_FONT_TYPET 3

/* Convert an int to a big endian byte sequence */
void int_to_bytes(int value, unsigned char * bytes) {
	
	bytes[0] = value >> 24;
	bytes[1] = value >> 16;
	bytes[2] = value >> 8;
	bytes[3] = value;
	
}

/* Convert a big endian byte sequence to an int */
int bytes_to_int(const unsigned char * bytes, int len) {
	int v = 0;
	switch(len) {
		case 1:
			v = bytes[0];
			break;
		case 2:
			v = bytes[0] << 8 | bytes[1];
			break;
		case 3:
			v = bytes[0] << 16 | bytes[1] << 8 | bytes[2];
			break;
		case 4:
			v = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
			break;
		default:
			v = 0;
			break;
	}
	return v;
}


@implementation MFFontData

@synthesize firstChar, lastChar, ascent, descent, missingWidth;
@synthesize encoder;
@synthesize valid;

/**
 * This will calculate the average width of the glyph of this font. It will not
 * count glyph with 0 width.
 */
-(CGFloat)averageWidth {
    
    if(!averageWidthCalculated)
    {
        averageWidthCalculated = 1;
        averageWidth = 0.0f;
        
        int i;
        int notNulls = 0;
        for(i=0; i < 256; i++)
        {
            if(widths[i] > 0.0)
            {
                averageWidth+=widths[i];
                notNulls++;
            }
        }
        if(notNulls > 0)
        {
            averageWidth = averageWidth/(1.0 * notNulls);
        }
    }
    
    return averageWidth;
}

-(id)init {
    
    if((self = [super init])) {
        
        encoder = NULL;
        missingWidth = 0.0f;
    }
    return self;
}

-(int)getCid:(unsigned int *) cid fromByteSequence:(const unsigned char *)sequence {

    // Default implementation for single byte font: return the byte int value.
    
    *cid = (int)(*sequence);
    
    return 1; /* Return that a single byte has been read */
}

-(unsigned int *)unicodeForCharacterCode:(unsigned int)cCode length:(int *)length {
    
    if(!encoder) {
        *length = 0;
        return NULL;
    }
    
    return fontEncoderUnicodeForCode(encoder, cCode, length);
}

-(float)widthForCharacterCode:(unsigned int)cCode {
	if((cCode >= firstChar) && (cCode <= lastChar)) {
		return widths[cCode-firstChar];
	}
	return missingWidth;
}

-(CGRect)boxForCharacterWidth:(CGFloat)width {
    
    return CGRectApplyAffineTransform(CGRectMake(0, descent, width, ascent-descent), CGAffineTransformMakeScale(0.001, 0.001));
}


-(CGRect)boxForCharacterCode:(unsigned int) cCode {

	CGFloat w,asc,dsc;
	
	if((cCode >= firstChar) && (cCode <= lastChar)) {
		w = widths[cCode-firstChar]*0.001;
	} else {
		
		w = missingWidth*0.001;
	}
	
	asc = ascent*0.001;
	dsc = descent*0.001;
	
	return CGRectMake(0, dsc, w, asc-dsc);
}

-(void) sizesForCharacterCode:(unsigned int)cCode width:(CGFloat *)width ascent:(CGFloat *)asc andDescent:(CGFloat *)dsc {
	
	if((cCode >= firstChar) && (cCode <= lastChar)) {
		*width = widths[cCode-firstChar]*0.001;
	} else {
		
		*width = missingWidth*0.001;
	}

	*asc = ascent*0.001;
	*dsc = descent*0.001;
}

-(void) setWidths:(CGFloat *)wds length:(unsigned int)wdsLength {
	
	unsigned i;
	for(i = 0; i < wdsLength; i++) {
		
		widths[i] = wds[i];
	}
}

-(void)dealloc {

	if(encoder) {
		deleteFontEncoder(encoder);
		free(encoder),encoder = NULL;
	}
	
	[super dealloc];
}


@end

@implementation MFFontDataType0

@synthesize widthRanges, unicodeRanges, cidRanges;
@synthesize  defaultWidth;
@synthesize undefinedCids;
@synthesize writingMode;

-(NSString *)description {
    
    return [NSString stringWithFormat:@"{\n%@\n%@\n%@\n}", cidRanges, undefinedCids, unicodeRanges];
}

-(id)init {
    
    if((self = [super init])) {
        
        type = MF_FONT_TYPE0;
        
        cidRanges = [[MFCIDCluster alloc]init];
        widthRanges = [[MFWidthCluster alloc]init];
        unicodeRanges  = [[MFUnicodeCluster alloc]init];
        undefinedCids = [[MFCIDCluster alloc]init];
        self.writingMode = 0;
        defaultWidth = 1000;
    }
       return self;
}

-(CGRect)boxForCharacterCode:(unsigned int)cCode {
    
    CGFloat w, asc, dsc;
    
    if(![widthRanges getWidth:&w forCid:cCode]) {
        w = defaultWidth;
    }
    w*=0.001f;
    asc = ascent*0.001f;
    dsc = descent*0.001f;
    
    return CGRectMake(0, dsc, w, asc-dsc);
}

-(CGFloat)averageWidth {
    
    if(!averageWidthCalculated) {
        averageWidthCalculated = 1;
        averageWidth = [widthRanges averageWidth];
    }
    
    return averageWidth;
}


-(float)widthForCharacterCode:(unsigned int)cCode {
    
    CGFloat w = 0.0f;
    if(![widthRanges getWidth:&w forCid:cCode]) {
        w = defaultWidth;
    }
    
    return w;
}

-(void) sizesForCharacterCode:(unsigned int)cCode width:(CGFloat *)width ascent:(CGFloat *)asc andDescent:(CGFloat *)dsc {
	
    // Intialized to 0.0, but will end up either as the right width or the
    // default width.
    
    CGFloat w = 0.0f;
    
    if(![widthRanges getWidth:&w forCid:cCode]) {
        w = defaultWidth;
    }
    
    w*=0.001f;
    *width = w;
    
    *asc = ascent*0.001f;
    *dsc = descent*0.001f;
}


-(int)getCid:(unsigned int *) cid fromByteSequence:(const unsigned char *)sequence {
    
    int sequence_as_int = bytes_to_int(sequence, 1);
    
    if([cidRanges getCid:cid forSequence:sequence_as_int ofLength:1]) {
        
        //printf("%X",*sequence);
        
        return 1;
    }
    
    sequence_as_int = bytes_to_int(sequence, 2);
    if([cidRanges getCid:cid forSequence:sequence_as_int ofLength:2]) {
                //printf("%X%X",sequence[0],sequence[1]);
        return 2;
    }
    
    sequence_as_int = bytes_to_int(sequence, 4);
    if([cidRanges getCid:cid forSequence:sequence_as_int ofLength:4]) {
                //printf("%X%X%X%X",sequence[0],sequence[1],sequence[2],sequence[3]);
        return 4;
        
    }
    
    
        
        sequence_as_int = bytes_to_int(sequence,1);
    if([undefinedCids getCid:cid forSequence:sequence_as_int ofLength:1]) {
                //printf("ndef %X",*sequence);
        return 1;
    }
        sequence_as_int = bytes_to_int(sequence,2);
    if([undefinedCids getCid:cid forSequence:sequence_as_int ofLength:2]) {
         //printf("ndef %X%X",sequence[0],sequence[1]);
        return 2;
    }
        sequence_as_int = bytes_to_int(sequence, 4);
    if([undefinedCids getCid:cid forSequence:sequence_as_int ofLength:4]){
    //printf("ndef %X%X%X%X",sequence[0],sequence[1],sequence[2],sequence[3]);
        return 4;
    }
    
        *cid = 0;
        return 1;
}

-(unsigned int *)unicodeForCharacterCode:(unsigned int)cCode length:(int *)length {
    
    unsigned int * unicode = NULL;
    
    if([unicodeRanges getUnicode:&unicode length:length forCid:cCode]) {
        
        return unicode;
        
    } else {
        
        *length = 0;
        return NULL;
    }
}

-(void)dealloc {
    
    [undefinedCids release], undefinedCids = nil;
    [cidRanges release], cidRanges = nil;
    [widthRanges release], widthRanges = nil;
    [unicodeRanges release], unicodeRanges = nil;
    
    [super dealloc];
}

@end

@implementation MFFontDataType1

-(id)init {
    if((self = [super init])) {
        type = MF_FONT_TYPE1;
    }
    return self;
}

@end


@implementation MFFontDataType3

-(id)init {
    if((self = [super init])) {
        type = MF_FONT_TYPE3;
    }
    return self;
}

-(CGRect)boxForCharacterWidth:(CGFloat)width {
    
    return CGRectApplyAffineTransform(CGRectMake(0, descent, width, ascent-descent), matrix);
}

-(CGRect)boxForCharacterCode:(unsigned int) cCode {
	
	float w;
	
	if((cCode >= firstChar) && (cCode <= lastChar)) {
		w = widths[cCode-firstChar];
	} else {
		
		w = missingWidth;
	}
	
	return CGRectApplyAffineTransform(CGRectMake(0, descent, w, ascent-descent),matrix);
}



@synthesize matrix;

@end


@implementation MFFontDataTrueType 

-(id)init {
    if((self = [super init])) {
        type = MF_FONT_TYPET;
    }
    return self;
}

@end