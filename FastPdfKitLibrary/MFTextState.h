//
//  MFTextState.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "mfprofile.h"

@class MFFontData;
@class MFTextBox;

CGFloat calculateTx(CGFloat h_disp, CGFloat pos_adj, CGFloat font_size, CGFloat h_scale, CGFloat char_space, CGFloat word_space);
CGFloat calculateTy(CGFloat v_disp, CGFloat pos_adj, CGFloat font_size, CGFloat char_space, CGFloat word_space);

struct GraphicState;
typedef struct GraphicState {
	
	CGFloat charSpace;	// Tc
	CGFloat wordSpace;	// Tw
	CGFloat scale;		// Th (?)
	CGFloat leading;
	CGFloat fontSize;		// Tfs
	long int render;
	CGFloat rise;
    
	MFFontData *currentFont;
	
	// float adjustment;
	
	CGAffineTransform ctm;
	
} GraphicState;

@interface MFTextState : NSObject {
	
	// Graphic state
	GraphicState *currentGS;
	GraphicState gsStack [32];
	unsigned int gsStackIndex;
    
	CGAffineTransform textMatrix;
	CGAffineTransform textLineMatrix;
	CGAffineTransform textRenderingMatrix;
	
	//
//	float charSpace;	// Tc
//	float wordSpace;	// Tw
//	float scale;		// Th (?)
//	float leading;
//	float fontSize;		// Tfs
//	long int render;
//	float rise;
	CGFloat adjustment;
	
    CGFloat avgGlyphWidth;
    long glyphCount;
    
	//MFFontData *currentFont;
	NSDictionary *fonts;
	
	MFTextBox *currentBox;
	NSMutableArray *textboxDestination;
	
	MFProfile * profile;
}

@property (retain) MFTextBox * currentBox;
//@property (assign) MFFontData * currentFont;
//@property (readwrite,assign) float charSpace;
//@property (readwrite,assign) float wordSpace;
//@property (readwrite,assign) float scale;
//@property (readwrite,assign) float leading;
//@property (readwrite,assign) float rise;
//@property (readwrite,assign) long int render;
-(CGFloat)leading;
-(void)setLeading:(CGFloat) leading;
-(void)setCharSpace:(CGFloat) cspace;
-(void)setWordSpace:(CGFloat) wspace;
-(void)setScale:(CGFloat) scale;
-(void)setRise:(CGFloat)rise;
-(void)setRender:(long int)render;

@property (nonatomic, readwrite) MFProfile * profile;

@property (readwrite,assign) CGFloat adjustment;

@property (retain) NSMutableArray *textboxDestination;
@property (retain) NSDictionary *fonts;

-(void) setFont:(char *)fontname andSize:(CGFloat)fontsize;

-(void) resetState;
-(void) setTextAndLineMatrixA:(CGFloat) a B:(CGFloat) b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andFinallyF:(CGFloat) f;
-(void) updateTextAndLineMatrixTx:(CGFloat)tx andTy:(CGFloat) ty;

-(void) operatorTdWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty;
-(void) operatorTDWithValuesTx:(CGFloat)tx andTy:(CGFloat)ty;
-(void) operatorTmWithValuesA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andF:(CGFloat)f;
-(void) operatorTStar;

-(void) adjustTextMatrix:(CGFloat)adj;

-(void) showCodes:(const unsigned char *)codes length:(int)length adjustment:(CGFloat)adj;
-(void) showCodes:(const unsigned char *)codes length:(int)length;
-(void) showString:(const char *)aString;
-(void) showString:(const char *)aString withAdjustment:(CGFloat)adj;
-(void) endBlock;
-(void) beginBlock;

-(void)setCTMwithValuesA:(CGFloat) a B:(CGFloat) b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e andFinallyF:(CGFloat) f;
-(void)pushGraphicState;
-(void)popGraphicState;

+(NSString *)newStringFromUTF32Buffer:(unsigned int *)buffer length:(long int)length;

@end


