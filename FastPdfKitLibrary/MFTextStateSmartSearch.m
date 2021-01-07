//
//  MFTextStateSmartSearch.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 5/10/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFTextStateSmartSearch.h"
#import "MFFontData.h"
#import "unbuffer.h"
#import "PrivateStuff.h"
#import "FPKTextSearchState.h"

#define DEF_BUFFER_SIZE 256

#define FPK_SPACE_HINT_AVG_WIDTH_RATIO 0.3
#define FPK_NEWLINE_WIDTH_RATIO 0.5

@implementation MFTextStateSmartSearch

@synthesize searchTerms;
@synthesize unicodeBuffer;
@synthesize searchTerm;

#pragma mark - Settings

-(void)setSearchMode:(FPKSearchMode)mode
{    
    searchMode = mode;
}

-(void)setIgnoreCase:(BOOL)ignoreOrNot 
{    
    if(ignoreOrNot) {
        ignoreCase = 1;
    } else {
        ignoreCase = 0;
    }
}

-(void)setExactMatch:(BOOL)exactMatchOrNot
{
    exactMatch = exactMatchOrNot;
}

#pragma mark - 

-(void)prepare
{
    if(exactMatch)
    {
        FPKTextSearchState * state = [FPKTextSearchState textSearchStateWithString:searchTerm];
        state.ignoreCase = ignoreCase;
        state.searchMode = searchMode;
        state.textBuffer = unicodeBuffer;
        [searchTerms addObject:state];
    }
    else
    {
        NSString * trimmed = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray * components = [trimmed componentsSeparatedByString:@" "];
        NSSet * uniqueComponents = [NSSet setWithArray:components];
        for(NSString * component in uniqueComponents)
        {
            FPKTextSearchState * state = [FPKTextSearchState textSearchStateWithString:component];
            state.ignoreCase = ignoreCase;
            state.searchMode = searchMode;
            state.textBuffer = unicodeBuffer;
            [searchTerms addObject:state];
        }
    }
}

-(id)initWithSearchTerm:(NSString *)sTerm {
	
    if((self = [super init])) {
		
        tempTextBoxes = [[NSMutableArray alloc]init];
		
        self.searchTerm = sTerm;
        
        FPKTextBuffer * buffer = [[FPKTextBuffer alloc]init];
		self.unicodeBuffer = buffer;
        [buffer release];
        
        self.searchTerms = [NSMutableOrderedSet orderedSet];
	}
	
	return self;
}

-(void)compileTextBoxes {
    
    NSMutableArray * results = [NSMutableArray array];
    
    /* If there's just a search term, just add its result to the array. Otherwise,
     we need to first sort the results */
    
    if(searchTerms.count <= 1)
    {
        FPKTextSearchState * state = [searchTerms lastObject];
        [results addObjectsFromArray:[[state boxes]array]];
    }
    else
    {
        NSMutableArray * boxes = [NSMutableArray array];
        for(FPKTextSearchState * state in searchTerms)
        {
            [results addObjectsFromArray:[[state boxes]array]];
        }
        
        [boxes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            MFTextBox * box1 = (MFTextBox *)obj1;
            MFTextBox * box2 = (MFTextBox *)obj2;
            
            if(box1.startPosition > box2.startPosition)
            {
                return NSOrderedAscending;
            }
            else if (box1.startPosition < box2.startPosition)
            {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    }
    
    /* Compile the results as usual */
    for(MFTextBox * box in results) 
    {
        [box sampleTextFromUnicodeBuffer:unicodeBuffer];
        [textboxDestination addObject:box];
    }
}

-(void)handleUnicode:(unsigned int *)unicode 
              length:(int)length 
              andBox:(CGRect)box 
         synthesized:(BOOL)synth {
    
    static unsigned int kUnicodeSpace = 0x0020;
    static unsigned int kUnicodeNewline = 0x000A;
    
    // Se il carattere da maneggiare è uno spazio controllare l'ultimo carattere aggiunto: se è anch'esso uno spazio
    // non va' aggiunto al buffer ma va solo aggiornato il rettangolo dell'ultimo glifo.
    // fprintf(stdout,"%c",unicode);
    
    if(synth) {
        
        if(*unicode == kUnicodeSpace) {
            
            if([unicodeBuffer lastUnicode] == kUnicodeSpace) {
                
                // Continuazione dello spazio precedente, aggiorna il current box se necessario.
                
                for(FPKTextSearchState * state in searchTerms)
                {
                    [state extendBoxIfRequired:box];
                }
                
            } else {
                
                // Nuovo spazio, handle as a real character.
                
                goto check; // ATTENZIONE! Controllare bene che non crei problemi.
            }
            
        } else if (*unicode == kUnicodeNewline) {
         
            [unicodeBuffer appendUnicodeToBuffer:&kUnicodeSpace length:1];
        }
        
    } else {
        
    check:
        
       for(FPKTextSearchState * state in searchTerms)
       {
           [state handleUnicode:unicode length:length andBox:box];
       }
        
        [unicodeBuffer appendUnicodeToBuffer:unicode length:length];
    }
}

-(void)beginBlock 
{
    [self resetState];   
}

-(void)endBlock 
{
    // Empty implementation.
}

-(void)showCodes:(const unsigned char *)codes
          length:(int)length 
      adjustment:(CGFloat)adj
{
    
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
    
    __unused int hints_calculated = 0;   // Hint already calculated flag.
    
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
//    fprintf(stdout, "%s\n", _dbg_buffer);
    
#if DEBUG
    if(NO) {
        // Print hex representation of the codes. Usually set to no
        char * _dbg_buffer = calloc(length+1,sizeof(unsigned char));
        memcpy(_dbg_buffer, codes, length);
        int  _dbg_idx;
        
        __unused int _idx;
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
        
        box = CGRectApplyAffineTransform(box, transformMatrix);
        
        CGPoint txtPt = CGPointApplyAffineTransform(CGPointZero, transformMatrix);
        
        dx = txtPt.x - lastTextPoint.x;
        dy = txtPt.y - lastTextPoint.y;
        
        newline_hint = fabs(currentGS->currentFont.ascent * transformVerticalScale(transformMatrix) / 1000.0);
        
        // NSLog(@"ascent %f %@", currentGS->currentFont.ascent, NSStringFromCGAffineTransform(transformMatrix));
        
        space_hint = ([currentFont averageWidth] * transformHorizontalScale(transformMatrix))/1000.0;
        
        if(fabs(space_hint) < FLT_EPSILON)
        {
            
            CGFloat wswidth = [currentGS->currentFont missingWidth];
            if(fabs(wswidth) < FLT_EPSILON)
                wswidth = [currentGS->currentFont widthForCharacterCode:32];
            
            space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
        }

        /*
        CGFloat wswidth = [currentGS->currentFont widthForCharacterCode:32];
        
        if(wswidth == 0.0) {
            
            if(avgGlyphWidth != 0.0) {
                
                wswidth = (float)avgGlyphWidth/glyphCount;
                // fprintf(stdout, "USING AVG WIDTH %f!\n", wswidth);
                // space_hint = ((wswidth * transformHorizontalScale(transformMatrix)));
                space_hint = ([currentFont averageWidth] * transformHorizontalScale(transformMatrix))/1000.0;
                
            } else {
                
                wswidth = [currentGS->currentFont missingWidth];
                //fprintf(stdout, "USING MISSING WIDTH %f!\n", wswidth);
                space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
            }
        }
        else {
            space_hint = ((wswidth * transformHorizontalScale(transformMatrix))/1000.0);
            //fprintf(stdout, "USING SPACE WIDTH %f!\n", wswidth);
            
        }
        */
        
        CGPoint tp;
        tp.x = dx;
        tp.y = dy;
        
        if(cid != 32) {
            tx = calculateTx(glyphWidth, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, 0);
        } else {
            tx = calculateTx(glyphWidth, adjustment, currentGS->fontSize, currentGS->scale, currentGS->charSpace, currentGS->wordSpace);
        }
        
        ty = 0.0;
        
        textMatrix = CGAffineTransformConcat(CGAffineTransformMakeTranslation(tx, ty),textMatrix);
        textRenderingMatrix = CGAffineTransformMake((currentGS->fontSize*currentGS->scale), 0, 0, currentGS->fontSize, 0, currentGS->rise);
        
        transformMatrix = CGAffineTransformConcat(textMatrix,currentGS->ctm); // Premultipies tm on CTM.
        transformMatrix = CGAffineTransformConcat(textRenderingMatrix,transformMatrix);
        
        if(unicodeLength > 1 || ((*unicode) != kUnicodeSpace)) {
            
            lastTextPoint = CGPointApplyAffineTransform(CGPointZero, transformMatrix);
            
            if(fabs(dy) > newline_hint) { // Old version (fabsf(dy) > currentGS->leading)
                
                [self handleUnicode:&kUnicodeNewline length:unicodeLength andBox:CGRectNull synthesized:YES];
                // [self handleUnicode:&kUnicodeSpace length:1];
                
            } else {
                
                // If the shift is greater than the size of a space, add a space.
                
                // fprintf(stdout, "%f > %f (%f)\n", dx, space_hint, glyphWidth);
                
                if (dx > (space_hint * FPK_SPACE_HINT_AVG_WIDTH_RATIO)) {

                    
                    CGRect spaceBox = box;
                    spaceBox.size.width = fabs(dx);
                    
                    [self handleUnicode:&kUnicodeSpace length:unicodeLength andBox:spaceBox synthesized:YES];
                    
                } else if ((skippedSpace | first) && (dx > (space_hint * FPK_SPACE_HINT_AVG_WIDTH_RATIO))) {
                    
                    CGRect spaceBox = box;
                    spaceBox.size.width = fabs(dx);
                    
                    [self handleUnicode:&kUnicodeSpace length:unicodeLength andBox:spaceBox synthesized:YES];
                }
            }
            
            [self handleUnicode:unicode 
                         length:unicodeLength 
                         andBox:box 
                    synthesized:NO];
            
            skippedSpace = NO;
            first = NO;
            avgGlyphWidth+=glyphWidth;
            glyphCount++;
            
        } else if(unicodeLength == 1 &&
                  (*unicode) == 32) {
            
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

-(void)showCodes:(const unsigned char *)codes
          length:(int)length 
{
    [self showCodes:codes 
             length:length 
         adjustment:0.0];
}


-(void)showCodes2:(unsigned char *)codes 
           length:(int)length 
       adjustment:(CGFloat)adj 
{
    [self showCodes:codes 
             length:length 
         adjustment:adj];
}

-(void)showCodes2:(unsigned char *)codes 
           length:(int)length 
{
    [self showCodes:codes 
             length:length 
         adjustment:0.0];
}


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

-(void)dealloc 
{
    [tempTextBoxes release], tempTextBoxes = nil;
    [unicodeBuffer release], unicodeBuffer = nil;
    [searchTerms release], searchTerms = nil;
    [searchTerm release], searchTerm = nil;
    
    [super dealloc];
}

@end
