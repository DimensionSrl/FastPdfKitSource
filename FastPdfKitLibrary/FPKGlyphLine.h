//
//  FPKGlyphLine.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/5/12.
//
//

#import <Foundation/Foundation.h>

@class FPKGlyphBox;

@interface FPKGlyphLine : NSObject

@property (nonatomic,strong) NSMutableArray * glyphs;

-(void)addGlyphBox:(FPKGlyphBox *)box;

@end
