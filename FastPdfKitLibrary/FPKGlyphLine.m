//
//  FPKGlyphLine.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/5/12.
//
//

#import "FPKGlyphLine.h"
#import "FPKGlyphBox.m"

@implementation FPKGlyphLine

@synthesize glyphs;

-(NSMutableArray *) glyphs {
    
    // Lazy allocation
    
    if(!glyphs) {
        NSMutableArray * tmp = [[NSMutableArray alloc]init];
        self.glyphs = tmp;
        [tmp release];
    }
    
    return glyphs;
}

-(void)addGlyphBox:(FPKGlyphBox *)box {
    
    [self.glyphs addObject:box];
}

-(void)dealloc {
    
    [glyphs release];
    
    [super dealloc];
}

@end
