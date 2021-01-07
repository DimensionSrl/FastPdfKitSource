//
//  MFTextState.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFTextState.h"
#import "MFTextBox.h"
#import "MFFontData.h"
#import "mffontencoding.h"


// Calculate tx factor for text rendering matrix transformation.
CGFloat calculateTx(CGFloat h_disp, CGFloat pos_adj, CGFloat font_size, CGFloat h_scale, CGFloat char_space, CGFloat word_space) {
	return ((h_disp - (pos_adj/1000.0)) * font_size + char_space + word_space) * h_scale;
}

// Calculate ty factor for text rendering matrix transformation.
CGFloat calculateTy(CGFloat v_disp, CGFloat pos_adj, CGFloat font_size, CGFloat char_space, CGFloat word_space) {
	return (v_disp - (pos_adj/1000.0)) * font_size + char_space + word_space;
}

#pragma mark -
#pragma mark MFTextState

@implementation MFTextState

@synthesize adjustment;
@synthesize textboxDestination, fonts; 
//@synthesize scale, render, charSpace, wordSpace, leading, rise;
@synthesize currentBox;
//@synthesize currentFont;
@synthesize profile;
void initGraphicState(GraphicState *gs) {
	
	gs->charSpace = 0.0f;
	gs->wordSpace = 0.0f;
	gs->scale = 1.0f;
	gs->leading = 0.0f;
	gs->render = 0;
	gs->rise = 0.0f;
	gs->ctm = CGAffineTransformIdentity;
	
	//textRenderingMatrix = textLineMatrix = textMatrix = CGAffineTransformIdentity;
}

+(NSString *)newStringFromUTF32Buffer:(unsigned int *)buffer length:(long int)length {
    
    unsigned char * utf8buffer = NULL;
    int utf8buffer_len = 0;
    
    utf8buffer = UTF8StringFromUTF32buffer(buffer, length, &utf8buffer_len);
    
	NSData * data = [[NSData alloc]initWithBytes:utf8buffer length:utf8buffer_len];
	NSString * text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
	    
    if(utf8buffer)
        free(utf8buffer);
    
    [data release];
	
	return text;
}

-(void)setCTMwithValuesA:(CGFloat) a B:(CGFloat) b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andFinallyF:(CGFloat) f {
    
	CGAffineTransform transform = CGAffineTransformMake(a,b,c,d,e,f);
	
    // NSLog(@"Current CTM %@", NSStringFromCGAffineTransform(currentGS->ctm));
    
    
    currentGS->ctm = CGAffineTransformConcat(transform, currentGS->ctm);
}

-(void)pushGraphicState {
	
	// Remember the old state, move up the stack and copy the preeceding state
	// into the new current one.

    if(gsStackIndex < 30) {
        gsStackIndex++;
        GraphicState *tmp = currentGS;
        currentGS++;
        (*currentGS) = (*tmp);
    
    } else {
        
        NSLog(@"FPK graphic stack overflow");
    }
}

-(void)beginBlock {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)endBlock {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)showCodes:(const unsigned char *)codes length:(int)length {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)showCodes:(const unsigned char *)codes length:(int)length adjustment:(CGFloat)adj {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)showString:(const char *)aString {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)showString:(const char *)aString withAdjustment:(CGFloat)adj {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)popGraphicState {
	
    
	// Just move down the stack.
    if(gsStackIndex > 0) {
        gsStackIndex--;
        currentGS--;
        
    } else {
        NSLog(@"FPK graphic stack underflow. Defaulting to identity matrix");
    }
}

-(void)resetState {
	
	textRenderingMatrix = textLineMatrix = textMatrix = CGAffineTransformIdentity;
}

// Init.
-(id)init {
	
	if((self = [super init])) {
		
		// Set the first gsStack as the currentGS and initialize it.
		currentGS = gsStack;
		initGraphicState(currentGS);
		textRenderingMatrix = textLineMatrix = textMatrix = CGAffineTransformIdentity;
		gsStackIndex = 0;
        
		//
//		// Text state variables. Persist between test object.
////		charSpace = 0.0f;
////		wordSpace = 0.0f;
////		scale = 1.0f;
////		leading = 0.0f;
////		render = 0;
////		rise = 0.0f;
		
		// Text matrix do not persist. Initialize them in the reset() method.
		
		// currentFont = NULL;
		currentBox = NULL;
		textboxDestination = NULL;
		fonts = NULL;	
	}
	return self;
}

-(void) dealloc {

	profile = NULL;
	
	[fonts release],fonts = nil;
	[textboxDestination release],textboxDestination = nil;
	[currentBox release],currentBox = nil;
	
	currentGS = NULL; // This is only a pointer to the current gsStack array element.
	
	[currentBox release],currentBox = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Setters and getters

-(void)setFont:(char *)fontname andSize:(CGFloat)fontsize {
	
    // Reset space hint
    avgGlyphWidth = 0.0;
    glyphCount = 0;
    
	currentGS->fontSize = fontsize;
	
	if(nil!=fonts) {
		
		currentGS->currentFont = [fonts objectForKey:[NSString stringWithCString:fontname encoding:NSUTF8StringEncoding]];
        
//		if([(currentGS->currentFont)isKindOfClass:[MFFontDataType0 class]]) {
//            
//            MFFontDataType0 * font = currentGS->currentFont;
//            
//            NSLog(@"Font %@", font);
//        }
        
#if DEBUG && 0
		printf("Request to load font %s\n",fontname);
		if(!currentGS->currentFont) {
			printf("\tNOT FOUND\n");
		} else {
			printf("\tFOUND\n");
		}
#endif
		
	} else {
		currentGS->currentFont = NULL;
	}
}

-(void) adjustTextMatrix:(CGFloat)adj {
	textMatrix = CGAffineTransformTranslate(textMatrix, adj, 0);
}


-(void) setTextAndLineMatrixA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andFinallyF:(CGFloat)f {
	
	textLineMatrix = CGAffineTransformMake(a, b, c, d, e, f);
	textMatrix = textLineMatrix;
}

-(void)updateTextAndLineMatrixTx:(CGFloat)tx andTy:(CGFloat)ty {
	
	textLineMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textLineMatrix);
	textMatrix = textLineMatrix;
}

#pragma mark -
#pragma mark Text position operators

-(void) operatorTDWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty {
	
	currentGS->leading = -ty;
	
	textLineMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textLineMatrix);
	textMatrix = textLineMatrix;
}

-(void) operatorTmWithValuesA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andF:(CGFloat)f {
	
	textLineMatrix = CGAffineTransformMake(a, b, c, d, e, f);
	textMatrix = textLineMatrix;
}

-(void) operatorTdWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty {
	
	textLineMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textLineMatrix);
	textMatrix = textLineMatrix;
}

-(void) operatorTStar {
	
	// This suck, the reference is wrong. Either set the leading to ty instead of -ty in TD and TL or use -leading here. Using
	// -leading seems more correct.
	textLineMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, -currentGS->leading),textLineMatrix);
	textMatrix = textLineMatrix;
}

// // Unused
//-(void) updateTextMatrixTx:(float)tx andTy:(float)ty {
//	
//	// TM = TM X I(tx,ty)
//	textMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textMatrix);
//}

-(CGFloat)leading {
	return currentGS->leading;
}

-(void)setLeading:(CGFloat) leading {
	currentGS->leading = leading;
}

-(void)setCharSpace:(CGFloat) cspace {
	currentGS->charSpace = cspace;
}

-(void)setWordSpace:(CGFloat) wspace {
	currentGS->wordSpace = wspace;
}

-(void)setRise:(CGFloat)rise {
	currentGS->rise = rise;
}

-(void)setRender:(long int)render {
	currentGS->render = render;
}

-(void) setScale:(CGFloat)aScale {
	currentGS->scale = aScale/100.0;
}

@end