//
//  MFTextStateGlyphData.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MFTextStateGlyphData.h"
#import "MFFontData.h"

@interface MFTextStateGlyphData()

@property (nonatomic,retain) FPKGlyphBox * lastBox;

@end

@implementation MFTextStateGlyphData

@synthesize lastBox;
@synthesize boxes;

-(void)handleBox:(FPKGlyphBox *)box {
    
    if(box.synthesized) {
        
        if(lastBox.synthesized) {
            // Skip, merge or substitute...
        }
        
    } else {
        
        [boxes addObject:box];
    }
    
    self.lastBox = box;
}

-(NSArray *)textLines {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unimplemented method %@", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

-(void)showCodes2:(unsigned char *)codes length:(int)length adjustment:(float)adj {
    
    static unsigned int kUnicodeNotdef = 0x25AF;
    
    MFFontData * currentFont = currentGS->currentFont;
    if(!currentFont.isValid) {
        
#if DEBUG
        NSLog(@"Font not valid");
#endif
        
        return;
    }
    
    int count = 0;
    unsigned char * ptr = codes;
    unsigned int cid = 0;
    
    unsigned int * unicode = NULL;
    int unicodeLength;
    
    int bytes_read = 0;
    CGRect box;
    CGFloat h_disp;
    CGAffineTransform tmpMtx;
    CGFloat dx, dy;
    float tx, ty;
    CGPoint tp;
    
    while(count < length) {
        
        bytes_read = [currentFont getCid:&cid fromByteSequence:ptr];
        
        ptr+=bytes_read;
        count+=bytes_read;
        
        unicode = [currentFont unicodeForCharacterCode:cid length:&unicodeLength];
        
        if(!unicode) {
            unicode = &kUnicodeNotdef;
            unicodeLength = 1;
        } 
        
        box = [currentGS->currentFont boxForCharacterCode:cid];	// Box is in text space coordinates.
        h_disp = box.size.width;
        
        textRenderingMatrix = CGAffineTransformMake((currentGS->fontSize*currentGS->scale), 0, 0, currentGS->fontSize, 0, currentGS->rise);
        
        tmpMtx = CGAffineTransformConcat(textMatrix,currentGS->ctm); // Premultipies tm on CTM.
        tmpMtx = CGAffineTransformConcat(textRenderingMatrix,tmpMtx);
        
        if(fabsf(adjustment) > 0.0001) {
            tmpMtx = CGAffineTransformTranslate(tmpMtx, -adjustment/1000.0, 0);
        }
        
        box = CGRectApplyAffineTransform(box, tmpMtx);
        
        textPoint = CGPointApplyAffineTransform(CGPointZero, tmpMtx);
        dx = textPoint.x - lastTextPoint.x;
        dy = textPoint.y - lastTextPoint.y;
        
        /*
        if(!hints_calculated) {
            
            // Calculate hint to guess space and new lines on matrix changes.
            
            hints_calculated = 1;
            
            newline_hint = fabsf(currentGS->currentFont.ascent * tmpMtx.d / 1000.0);
            
            CGFloat wswidth = [currentGS->currentFont widthForCharacterCode:32];
            
            if(wswidth == 0) {
                wswidth = [currentGS->currentFont missingWidth];
            }
            
            space_hint = ((wswidth*tmpMtx.a)/1000.0)*0.5;
        }
        
        if(fabsf(dy) > newline_hint) {
            
            [self handleUnicode:&kUnicodeNewline length:unicodeLength andBox:CGRectNull synthesized:YES];
            
        } else {
            
            if (dx > (space_hint)) {
                
                //NSLog(@"Appending space %.3f > %.3f",dx*1000,[currentGS->currentFont widthForCharacterCode:32]);
                CGRect spaceBox = [currentGS->currentFont boxForCharacterWidth:dx*1000];
                
                spaceBox = CGRectApplyAffineTransform(spaceBox, tmpMtx);
                
                [self handleUnicode:&kUnicodeSpace length:unicodeLength andBox:spaceBox synthesized:YES];            
            
                
            }
        }
        */
        
        FPKGlyphBox * glyphBox = [[FPKGlyphBox alloc]initWithBox:box unicodes:unicode length:unicodeLength];
        
        [self handleBox:glyphBox];
        
        [glyphBox release];
        
        
        tp.x = dx;
        tp.y = dy;
        
        if(cid != 32) {
            tx = calculateTx(h_disp, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, 0);
        } else {
            tx = calculateTx(h_disp, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, currentGS->wordSpace);
        }
        
        ty = 0.0;
        
        textMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textMatrix);
        textRenderingMatrix = CGAffineTransformMake((currentGS->fontSize*currentGS->scale), 0, 0, currentGS->fontSize, 0, currentGS->rise);
        tmpMtx = CGAffineTransformConcat(textMatrix,currentGS->ctm); // Premultipies tm on CTM.
        tmpMtx = CGAffineTransformConcat(textRenderingMatrix,tmpMtx);
        
        lastTextPoint = CGPointApplyAffineTransform(CGPointZero, tmpMtx);
        
        if(fabsf(adjustment) > 0.0001) {
            adjustment = 0.0;
        }
    }
}

-(void)showCodes2:(unsigned char *)codes length:(int)length {
    [self showCodes2:codes length:length adjustment:0.0];
}

-(void)beginBlock  {
    
	[self resetState];
}

-(void)endBlock {
    
}

-(void) setFont:(char *)fontname andSize:(CGFloat)fontsize {
	
	[super setFont:fontname andSize:fontsize];
}

-(id)init {
    
    if((self = [super init])) {
        
        boxes = [[NSMutableArray alloc]init];
        
    }
    return self;
}

-(void)dealloc {
    
    [boxes release];
    [lastBox release];
    
    [super dealloc];
}

@end
