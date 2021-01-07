//
//  MFTextStateSmartSearch.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 5/10/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFTextState.h"
#import "MFTextBox.h"
#import "Stuff.h"
#import "unbuffer.h"
#import "FPKTextBuffer.h"

@interface MFTextStateSmartSearch : MFTextState {
    
    NSMutableArray *tempTextBoxes;
    
    CGPoint textPoint, lastTextPoint;
    
    FPKSearchMode searchMode;
    int ignoreCase;
    BOOL exactMatch;
}

-(id)initWithSearchTerm:(NSString *)sTerm;
-(void)compileTextBoxes;
-(void)setSearchMode:(FPKSearchMode)mode;
-(void)setIgnoreCase:(BOOL)ignoreOrNot;
-(void)setExactMatch:(BOOL)exactMatchOrNot;

-(void)prepare;

@property (strong, nonatomic) NSMutableOrderedSet * searchTerms;
@property (strong, nonatomic) FPKTextBuffer * unicodeBuffer;
@property (copy, nonatomic) NSString * searchTerm;

@end
