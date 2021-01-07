//
//  FPKTextSearchState.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 27/27/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "FPKTextSearchState.h"
#import "MFTextBox.h"
#import "unbuffer.h"

@interface FPKTextSearchState() {
@private
    NSMutableOrderedSet * glyphBoxes;
    NSUInteger currentIndex;
    NSUInteger searchTermLength;
    NSString * searchTerm;
    
    unbuffer text_buffer;
    unbuffer term_buffer;
}

@property (copy, nonatomic) NSString * searchTerm;
@property (strong, nonatomic) NSMutableOrderedSet * glyphBoxes;
@property (strong, nonatomic) MFTextBox * termHighlightBox;
@end

@implementation FPKTextSearchState
@synthesize searchTerm;
@synthesize termHighlightBox;
@synthesize searchMode;
@synthesize ignoreCase;
@synthesize textBuffer;
@synthesize glyphBoxes;

-(NSOrderedSet *)boxes
{
    return [NSOrderedSet orderedSetWithOrderedSet:glyphBoxes];
}

-(id)initWithString:(NSString *)string
{
    self = [super init];
    if(self)
    {
        NSMutableOrderedSet * set = [[NSMutableOrderedSet alloc]init];
        self.glyphBoxes = set;
        [set release];
        currentIndex = 0;
        self.searchTerm = string;
        searchTermLength = string.length;
    }
    return self;
}

+(FPKTextSearchState *)textSearchStateWithString:(NSString *)string
{
    FPKTextSearchState * state = [[FPKTextSearchState alloc]initWithString:string];
    
    return [state autorelease];
}

-(void)extendBoxIfRequired:(CGRect)box
{
    if(termHighlightBox && (!termHighlightBox.completed))
    {
        [[termHighlightBox lastGlyphQuad]extendBox:box];
    }
}

-(void)reset
{
    self.termHighlightBox = nil;
    currentIndex = 0;
}

-(void)handleUnicode:(unsigned int *)unicode 
              length:(int)length 
              andBox:(CGRect)box 
{
    
    CGAffineTransform identity = CGAffineTransformIdentity;
    
    // Se il carattere da maneggiare è uno spazio controllare l'ultimo carattere aggiunto: se è anch'esso uno spazio
    // non va' aggiunto al buffer ma va solo aggiornato il rettangolo dell'ultimo glifo.
    // fprintf(stdout,"%c",unicode);
    
    // 1. Get the unicode to match
   unsigned int term_unicode = [searchTerm characterAtIndex:currentIndex];
        
    // 2. Compose/decompose if necessary
        unbuffer_init_with_codepoints(&text_buffer, unicode, length);
        unbuffer_init_with_codepoint(&term_buffer,term_unicode);
        
        if(searchMode == FPKSearchModeHard) {
            
            // Decompose/compose both.
            unbuffer_decompose(&text_buffer);
            unbuffer_compose(&text_buffer,0);
            
            unbuffer_decompose(&term_buffer);
            unbuffer_compose(&term_buffer,0);
            //            
        } else {
            
            // Decompose/compose the term, decompose the unicode.
            unbuffer_decompose(&text_buffer);
            unbuffer_decompose(&term_buffer);
        }
        
    // 3. Compare
        if(unbuffer_compare(&term_buffer,&text_buffer,searchMode,ignoreCase) == 0) {
            
            // There's a match for the current character in the search term.
            currentIndex++;
            
            // If the old box is completed, discard it.
            if(termHighlightBox.completed) {
                self.termHighlightBox = nil;
            }
            
            // Lazy initialization of the new box.
            if(currentIndex == 1) {
                
                if(!termHighlightBox) {
                    self.termHighlightBox = [[[MFTextBox alloc]init]autorelease];
                }
                
                termHighlightBox.startPosition = [textBuffer length];
            }
            
            // Handle of the match.
            
            MFGlyphQuad * quad = [[MFGlyphQuad alloc]initWithBox:&box andTranfrom:&identity];
            [termHighlightBox addGlyphQuad:quad];
            [quad release];
            termHighlightBox.endPosition = [textBuffer length];
            
            // Check conditions.
            
            if(currentIndex == searchTermLength) {
                
                // Full match.
                
                termHighlightBox.completed = YES;
                [glyphBoxes addObject:termHighlightBox];
                
                currentIndex = 0;
            }
            
            
        } else {
            
            // Does not match at current index, but could be the start of the new search term.
            
            // Reset the current index, and check again.
            
            [self reset];
            
            unbuffer_init_with_codepoint(&term_buffer,[searchTerm characterAtIndex:currentIndex]);
            
            if(searchMode == FPKSearchModeHard) 
            {    
                unbuffer_decompose(&term_buffer);
                unbuffer_compose(&term_buffer,0);
            } 
            else 
            {    
                unbuffer_decompose(&term_buffer);
            }
            
            if(unbuffer_compare(&term_buffer, &text_buffer, searchMode, ignoreCase) == 0) 
            {
                if(!termHighlightBox) {
                    self.termHighlightBox = [[[MFTextBox alloc]init]autorelease];
                }
                
                termHighlightBox.startPosition = [textBuffer length];
                [termHighlightBox addGlyphQuad:[[[MFGlyphQuad alloc]initWithBox:&box andTranfrom:&identity]autorelease]];
                currentIndex++;
            }
        }
    
    unbuffer_destroy(&term_buffer);
    unbuffer_destroy(&text_buffer);
}

-(void)dealloc
{
    [glyphBoxes release], glyphBoxes = nil;
    [searchTerm release], searchTerm = nil;
    [textBuffer release], textBuffer = nil;
    [termHighlightBox release], termHighlightBox = nil;
    
    [super dealloc];
}

@end
