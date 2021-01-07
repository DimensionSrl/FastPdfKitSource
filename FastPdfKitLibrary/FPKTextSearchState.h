//
//  FPKTextSearchState.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 27/27/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Stuff.h"

@class FPKTextBuffer;

@interface FPKTextSearchState : NSObject

-(id)initWithString:(NSString *)string;

+(FPKTextSearchState *)textSearchStateWithString:(NSString *)string;

-(void)handleUnicode:(unsigned int *)unicode 
              length:(int)length 
              andBox:(CGRect)box;

-(void)extendBoxIfRequired:(CGRect)box;

-(void)reset;

@property (readwrite, nonatomic) FPKSearchMode searchMode;
@property (readwrite, nonatomic) BOOL ignoreCase;
@property (strong, nonatomic) FPKTextBuffer * textBuffer;

-(NSOrderedSet *)boxes;

@end
