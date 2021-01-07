//
//  MFTextStateWholeExtraction.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/30/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFTextStateSmartExtraction.h"
#import "mffontencoding.h"
#import "MFFontData.h"
#import "PrivateStuff.h"

#define FPK_SPACE_HINT_AVG_WIDTH_RATIO 0.3f
#define FPK_NEWLINE_WIDTH_RATIO 0.5f

@interface MFTextStateSmartExtraction()

@end
	
@implementation MFTextStateSmartExtraction
@synthesize textBuffer;

-(NSString *)textBuffer {

    NSString * retval = [MFTextState newStringFromUTF32Buffer:unicodeBuffer length:unicodeBufferSize];
    
    return [retval autorelease];
    
    /*
	int utf8_length = 0;
	int utf8_size = unicodeBufferSize + 1;
	unsigned char * utf8_buffer = calloc(utf8_size, sizeof(unsigned char));
	int chunk_length = 0;
    
	int index;
	for(index = 0; index < unicodeBufferSize; index++) {
        
        //fprintf(stdout, "%X\n",unicodeBuffer[index]);
        
        chunk_length = unicodeToUTF8BufferSpaceRequired(unicodeBuffer[index]);
        
        if(utf8_length + chunk_length >= utf8_size) {
            
            int new_size = utf8_size + unicodeBufferSize;
            unsigned char * tmp = calloc(new_size, sizeof(unsigned char));
            
            memcpy(tmp, utf8_buffer, utf8_length);
            
            free(utf8_buffer);
            utf8_buffer = tmp;
            
            utf8_size = new_size;
        }
        
		utf8_length+= writeUnicodeToUTF8Buffer(unicodeBuffer + index, utf8_buffer+utf8_length);		
	}
	
	NSData * data = [[NSData alloc]initWithBytes:utf8_buffer length:utf8_length];
	NSString * text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
	
    [data release];
	MF_C_FREE(utf8_buffer);
	
	return [text autorelease];
     */
}

-(void)appendUnicodeToBuffer:(unsigned int *) unicode length:(int)length {
	
    int index;
    
    unbuffer_init_with_codepoints(&unbuffer, unicode, length);
    unbuffer_decompose(&unbuffer);
    unbuffer_compose(&unbuffer, unbuffer_compose_mode_canonical);
    
    int composed_length = self->unbuffer.length;
    unsigned int * composed_buffer = self->unbuffer.buffer;
    
	if((unicodeBufferSize+composed_length)>=unicodeBufferMaxSize) {
        
		int newSize = unicodeBufferMaxSize + (DEF_BUFFER_SIZE * ((growthBias++)+1));
        
        unsigned int * tmp = calloc(newSize,sizeof(unsigned int));
        memcpy(tmp,unicodeBuffer,unicodeBufferMaxSize * (sizeof(unsigned int)));
        free(unicodeBuffer);
        unicodeBuffer = tmp;
        unicodeBufferMaxSize = newSize;	
	}
	
    for (index = 0; index < composed_length; index++)
        unicodeBuffer[unicodeBufferSize++] = composed_buffer[index];    
}

-(id)init {
	
	if((self = [super init])) {
		
		textBuffer = [[NSMutableString alloc]init];
		
		unicodeBuffer = calloc(DEF_BUFFER_SIZE,sizeof(unsigned int));
		unicodeBufferSize = 0;
		unicodeBufferMaxSize = DEF_BUFFER_SIZE;
        
        lastTextPoint = CGPointZero;
        
	}
	return self;
}

-(void)dealloc{
	
    [textBuffer release], textBuffer = nil;
    
	MF_C_FREE(unicodeBuffer);
	
	[super dealloc];
}

-(void)handleUnicode:(unsigned int *)unicode length:(int)length {
    
    [self appendUnicodeToBuffer:unicode length:length];
}

-(void)handleCodes:(const unsigned char *)codes
            length:(int)length 
        adjustment:(float)adj 
{
    
    static unsigned int kUnicodeNotdef = 0x25AF;
    
    CGFloat fontSizeT = currentGS -> fontSize;
    CGFloat horizontalScalingT = currentGS -> scale;
    CGFloat riseT = currentGS -> rise;
    CGFloat wordSpacingT = currentGS -> wordSpace;
    CGFloat characterSpacingT = currentGS -> charSpace;
    
    CGFloat fontMatrixXScale = 1/1000.0f;
    CGFloat fontMatrixYScale = 1/1000.0f;
    CGFloat glyphSpaceToTextSpaceScale = 1/1000.0f;
    
    if([currentGS->currentFont isKindOfClass:[MFFontDataType3 class]]) {
        
        MFFontDataType3 * font = (MFFontDataType3 *)currentGS->currentFont;
        CGAffineTransform matrix = font.matrix;
        
        fontMatrixXScale = matrix.a;
        fontMatrixYScale = matrix.d;
        glyphSpaceToTextSpaceScale = 1.0f/matrix.a;
    }
    
    CGFloat spaceWidthT = 0.0f;
    
    spaceWidthT = [currentGS->currentFont widthForCharacterCode:32];
    
    if(spaceWidthT == 0.0f) {
        
        spaceWidthT = [currentGS->currentFont missingWidth]; // This might fuck everything up...
        //TODO: calculate average here
    }
    
    CGFloat maxVerticalDisplacementT = 0.0f;
    
    CGAffineTransform textStateParameters = CGAffineTransformIdentity;
    textStateParameters.a = fontSizeT * horizontalScalingT;
    textStateParameters.d = fontSizeT;
    textStateParameters.ty = riseT;
    
    CGAffineTransform ctm = currentGS -> ctm;
    CGAffineTransform textXctm = CGAffineTransformIdentity;
    CGAffineTransform td = CGAffineTransformIdentity;
    CGAffineTransform tmpMatrix = CGAffineTransformIdentity;
    CGAffineTransform textMatrixEnd = CGAffineTransformIdentity;
    
    int count = 0;
    const unsigned char * ptr = codes;
    unsigned int cid = 0;
    unsigned int * unicode = NULL;
    int unicodeLength;
    int bytes_read = 0;
    
    while(count < length) {
        
        bytes_read = [currentGS->currentFont getCid:&cid fromByteSequence:ptr];
        ptr+=bytes_read;
        count+=bytes_read;
        
        // Get the unicode
        unicode = [currentGS->currentFont unicodeForCharacterCode:cid length:&unicodeLength];
        if(!unicode) {
            
            unicode = &kUnicodeNotdef;
            unicodeLength = 1;
        }
        
        CGFloat characterHorizontalDisplacementT = [currentGS->currentFont widthForCharacterCode:cid];
        CGFloat characterVerticalDisplacementT = [currentGS->currentFont widthForCharacterCode:cid];
        
        characterHorizontalDisplacementT*=fontMatrixXScale;
        characterHorizontalDisplacementT*=fontMatrixYScale;
        
        maxVerticalDisplacementT = MAX(maxVerticalDisplacementT, characterVerticalDisplacementT);
        
        CGFloat spacingT = 0.0f;
        if(*unicode == 0x20 && unicodeLength == 1) {
            spacingT += wordSpacingT;
        }
        
        textXctm = CGAffineTransformConcat(textMatrix, ctm);
        
        CGFloat tx = ((characterHorizontalDisplacementT * fontSizeT) * horizontalScalingT);
        CGFloat ty = 0.0f;
        
        td.tx = tx;
        td.ty = ty;
        
        tmpMatrix = CGAffineTransformConcat(textStateParameters, tmpMatrix);
        textMatrixEnd = CGAffineTransformConcat(tmpMatrix, textMatrixEnd);
        
        tx = (characterHorizontalDisplacementT * fontSizeT + characterSpacingT + spacingT) * horizontalScalingT;
        td.tx = tx;
        
        textMatrix = CGAffineTransformConcat(textMatrix, td); // textMatrix = td.multiply(textMatrix, td)
    }
}

-(void)showCodes:(const unsigned char *)codes length:(int)length adjustment:(CGFloat)adj {
    
    static unsigned int kUnicodeNotdef = 0x25AF;
    static unsigned int kUnicodeNewline = 0x000A;
    static unsigned int kUnicodeSpace = 0x0020;
    
    MFFontData * currentFont = nil;
    
    int count = 0;
    const unsigned char * ptr = codes;
    unsigned int cid = 0;
    unsigned int * unicode = NULL;
    int unicodeLength;
    int bytes_read = 0;
    CGRect box;
    CGFloat glyphWidth;
    CGAffineTransform transformMatrix;
    CGFloat dx, dy;
    CGFloat tx, ty;
    BOOL skippedSpace;
    BOOL first = YES;
    
    CGFloat newline_hint;   // Newline hint in page space.
    CGFloat space_hint;     // Space hint in page space.
    
    currentFont = currentGS->currentFont;
    if(!currentFont.isValid) {
        
#if DEBUG
        NSLog(@"Font not valid");
#endif
        
        return;
    }
    
//    char * _dbg_buffer = calloc(length+1,sizeof(unsigned char));
//    memcpy(_dbg_buffer, codes, length);
//    fprintf(stdout, "Char (%s)\n", _dbg_buffer);
    
#if DEBUG
    if(NO) {
        // Print hex representation of the codes. Usually set to no
        char * _dbg_buffer = calloc(length+1,sizeof(unsigned char));
        memcpy(_dbg_buffer, codes, length);
        int  _dbg_idx;
        
        for(_dbg_idx = 0; _dbg_idx < length; _dbg_idx++) {
            fprintf(stdout, "%04X ",codes[_dbg_idx]);
        }
        fprintf(stdout, "\n");
        free(_dbg_buffer);
    }
#endif
    
    while(count < length) {
        
        bytes_read = [currentFont getCid:&cid fromByteSequence:ptr];
        ptr+=bytes_read;
        count+=bytes_read;
        
        // Get the unicode
        unicode = [currentFont unicodeForCharacterCode:cid length:&unicodeLength];
        if(!unicode) {
            
            unicode = &kUnicodeNotdef;
            unicodeLength = 1;
        }
        
        box = [currentGS->currentFont boxForCharacterCode:cid];	// Box is in text space coordinates.
        glyphWidth = box.size.width;
        
        transformMatrix = CGAffineTransformConcat(textMatrix,currentGS->ctm); // Premultipies tm on CTM.
        
        textRenderingMatrix = CGAffineTransformMake((currentGS->fontSize*currentGS->scale), 0, 0, currentGS->fontSize, 0, currentGS->rise);
        
        transformMatrix = CGAffineTransformConcat(textRenderingMatrix, transformMatrix);
        
        if(fabs(adjustment) > FLT_EPSILON) {
            
            transformMatrix = CGAffineTransformTranslate(transformMatrix, -adjustment/1000.0, 0);
        }
        
        /*
        CGFloat angle = atan2f(textRenderingMatrix.a, textRenderingMatrix.b);
        fprintf(stdout, "TRM %f\n", angle);
        angle = atan2f(textMatrix.a, textMatrix.b);
        fprintf(stdout, "TM %f\n", angle);
        angle = atan2f(currentGS->ctm.a, currentGS->ctm.b);
        fprintf(stdout, "CTM %f\n", angle);
        angle = atan2f(transformMatrix.a, transformMatrix.b);
        fprintf(stdout, "TM %f\n", angle);
        */
        
        CGPoint textPoint = CGPointApplyAffineTransform(CGPointZero, transformMatrix);
        
        dx = textPoint.x - lastTextPoint.x;
        dy = textPoint.y - lastTextPoint.y;
        
        // fprintf(stdout, "calculating %f - %f = %f, %f - %f = %f\n", textPoint.x, lastTextPoint.x, dx, textPoint.y, lastTextPoint.y, dy);
        
        newline_hint = fabs(currentGS->currentFont.ascent * transformVerticalScale(transformMatrix) / 1000.0f); // * 2.0f;
        
        // NSLog(@"ascent %f %@", currentGS->currentFont.ascent, NSStringFromCGAffineTransform(transformMatrix));
        
        /* Use as space hint the average width of the glyph for this font. If
         average width end up being ~0, fallback to the missing font width of the
         current font or, eventually, the width of the space character */
        
        space_hint = ([currentFont averageWidth] * transformHorizontalScale(transformMatrix))/1000.0;
        
        if(fabs(space_hint) < FLT_EPSILON)
        {
            
            CGFloat wswidth = [currentGS->currentFont missingWidth];
            if(fabs(wswidth) < FLT_EPSILON)
                wswidth = [currentGS->currentFont widthForCharacterCode:32];
            
            space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
        }
        
        /*
         // OLD SPACE HINT STUFF
            if(!(wswidth > 0.0)) {

                if(!(avgGlyphWidth > 0.0))
                {

                    wswidth = (float)avgGlyphWidth/glyphCount;
                    // fprintf(stdout, "USING AVG WIDTH %f!\n", wswidth);
                    // space_hint = ((wswidth * transformHorizontalScale(transformMatrix)));
                    space_hint = ([currentFont averageWidth] * transformHorizontalScale(transformMatrix))/1000.0;
                    
                }
                else
                {

                    wswidth = [currentGS->currentFont missingWidth];
                    //fprintf(stdout, "USING MISSING WIDTH %f!\n", wswidth);
                    space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
                }
            }
            else {
                
                space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
                
            }
            */
        
        
//        float alternative = ([currentFont averageWidth] * transformHorizontalScale(transformMatrix))/1000.0;
//        
//        NSLog(@"%f vs %f", space_hint, alternative);
//        // printfintf(stdout, "Word space %f\n", currentGS->wordSpace);
        
        
        CGPoint tp;
        tp.x = dx;
        tp.y = dy;
        
        if(cid != 32) {
            tx = calculateTx(glyphWidth, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, 0);
        } else {
            tx = calculateTx(glyphWidth, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, currentGS->wordSpace);
        }
        
        ty = 0.0;
        
        textMatrix = CGAffineTransformTranslate(textMatrix, tx, ty);
        textRenderingMatrix = CGAffineTransformMake((currentGS->fontSize*currentGS->scale), 0, 0, currentGS->fontSize, 0, currentGS->rise);
        
        transformMatrix = CGAffineTransformConcat(textMatrix,currentGS->ctm); // Premultipies tm on CTM.
        transformMatrix = CGAffineTransformConcat(textRenderingMatrix,transformMatrix);
        
        // NSLog(@"%@", NSStringFromCGPoint(tp));
#if DEBUG
        printf("%c (%f) h: %f > %f v: %f > %f\n", *unicode, glyphWidth, dx, space_hint * FPK_SPACE_HINT_AVG_WIDTH_RATIO, dy, newline_hint);
#endif
        
        if(unicodeLength > 1 || ((*unicode) != kUnicodeSpace))
        {
            if(fabs(dy) > newline_hint)
            { // Old version (fabsf(dy) > currentGS->leading)
                
                // NSLog(@"%f > %f", fabs(dy), newline_hint);
                
                [self handleUnicode:&kUnicodeNewline length:1];
                // [self handleUnicode:&kUnicodeSpace length:1];
                
            }
            else
            {
                
                // If the shift is greater than the size of a space, add a space.
                
                // fprintf(stdout, "%f > %f (%f) begin at {%f, %f}\n", dx, space_hint, glyphWidth, textPoint.x, textPoint.y);
            
                if (dx > (space_hint * FPK_SPACE_HINT_AVG_WIDTH_RATIO)) {
                    
                    [self handleUnicode:&kUnicodeSpace length:1];
                
                } else if ((skippedSpace | first) && (dx > (space_hint * FPK_SPACE_HINT_AVG_WIDTH_RATIO))) {
                    
                    [self handleUnicode:&kUnicodeSpace length:1];
                }
            }

            // fprintf(stdout, "glyph began at {%f, %f} while previous glyph ended at {%f, %f}\n", textPoint.x, textPoint.y, lastTextPoint.x, lastTextPoint.y);
            
            // Save where does this glyph end.
            lastTextPoint = CGPointApplyAffineTransform(CGPointZero, transformMatrix);

            // fprintf(stdout, "glyph end at {%f, %f}\n", lastTextPoint.x, lastTextPoint.y);
            
            [self handleUnicode:unicode length:unicodeLength];
            
            skippedSpace = NO;
            first = NO;
            avgGlyphWidth+=glyphWidth;
            glyphCount++;
            
        } else if(unicodeLength == 1 &&
                  (*unicode) == 32) {
            
                // fprintf(stdout, "SPACE begin at {%f, %f}\n", textPoint.x, textPoint.y);
            
            // Flag that we have stripped a space.
            // fprintf(stdout, "stripped dx %f tx %f (%f)\n", dx, tx, adjustment);
            skippedSpace = NO;
        }
        
        // Reset the adjustment if still set.
        
        if(fabs(adjustment) > FLT_EPSILON) {
            adjustment = 0.0;
        }
    }

}

-(void)showCodes:(const unsigned char *)codes length:(int)length {
    [self showCodes:codes length:length adjustment:0];
}

-(void)showCodes2:(const unsigned char *)codes length:(int)length adjustment:(CGFloat)adj {
    [self showCodes:codes length:length adjustment:adj];
}

-(void)showCodes2:(const unsigned char *)codes length:(int)length {
	[self showCodes:codes length:length adjustment:0];
}

-(void)beginBlock  {

	// Empty implementation to override superclass's one.
	[self resetState];
}


-(void) setFont:(char *)fontname andSize:(CGFloat)fontsize {
	
	[super setFont:fontname andSize:fontsize];
}


-(void)endBlock {
	
	// Empty implementation.
}

/*
// Override
-(void)setTextAndLineMatrixA:(float)a B:(float)b C:(float)c D:(float)d E:(float)e andFinallyF:(float)f {
	[super setTextAndLineMatrixA:a B:b C:c D:devn, <#mode_t#>) E:<#e#> andFinallyF:<#f#>
	
}

// Override
-(void) updateTextAndLineMatrixTx:(float)tx andTy:(float)ty {
	
	[self appendUnicodeToBuffer:0x0020];
}
*/

#pragma mark -
#pragma mark Operators and policies

-(void) operatorTDWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty {
	
	[super operatorTDWithValuesTx:tx andTy:ty];
}

-(void) operatorTmWithValuesA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andF:(CGFloat)f {
	
	[super operatorTmWithValuesA:a B:b C:c D:d E:e andF:f];
}

-(void) operatorTdWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty {
	
	[super operatorTdWithValuesTx:tx andTy:ty];
}

-(void) operatorTStar {
	
	[super operatorTStar];
}

@end
