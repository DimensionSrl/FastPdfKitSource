//
//  MFTextStateGlyphData.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFTextState.h"
#import "FPKGlyphBox.h"

@interface MFTextStateGlyphData : MFTextState {
    
    NSMutableArray * boxes;
    CGPoint lastTextPoint, textPoint;
    FPKGlyphBox * lastBox;
    
}

@property (nonatomic,readonly) NSMutableArray * boxes;
-(NSArray *)textLines;

@end
