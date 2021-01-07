//
//  MFUnicodeCluster.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MFUnicodeRange;

/*
 Contains a collection of MFUnicodeRange used to map cid values to unicode sequences.
 */
@interface MFUnicodeCluster : NSObject {
    
    @public
    NSMutableArray * ranges;    // Unicode ranges.
}

-(void)addRange:(MFUnicodeRange *)range;
-(int)getUnicode:(unsigned int **)unicode length:(int *)length forCid:(unsigned int)cid;
@end

/*
 Base, abstract implementation for the unicode range classes. It only
 define first and last valid character identifier for the unicode
 sequence range.
 */
@interface MFUnicodeRange : NSObject {
    
    unsigned int cidFirst;  // First codepoint of the range.
    unsigned int cidLast;   // Last codepoint of the range.
    
}

-(int)isCidInRange:(int)sequence;
-(int)getUnicode:(unsigned int **)u length:(int*)length forCid:(unsigned int)cid;

@end


/*
 Constains a single unicode sequence.
 */
@interface MFUnicodeRangeSingle : MFUnicodeRange {
    
    unsigned int * unicode; // Single unicode sequence.
    int unicodeLength;      // Unicode sequence length.
}

-(id)initWithCid:(unsigned int)c andUnicode:(unsigned int *)u length:(int)length;

@end


/*
 Contains multiple sequential unicode sequences of the same length whose last
 unicode value differs by 1 from its neighborhoods.
 */
@interface MFUnicodeRangeSequential : MFUnicodeRange {
    
    unsigned int ** unicodes;   // Array of unicode sequences.
    int unicodeLength;          // Common unicode sequence length.
    int unicodeCount;           // Nr of unicode sequences.
}

-(id)initWithFirstCid:(unsigned int)fCid lastCid:(unsigned int)lCid andFirstUnicode:(unsigned int *)fUnicode length:(int)length;

@end


/*
 Contains multiple unicode sequences of different length.
 */
@interface MFUnicodeRangeMulti : MFUnicodeRange {
    
    unsigned int ** unicodes;   // Array of unicode sequences.
    int * unicodeLengths;       // Array of sequence length.
    int unicodeCount;           // Nr of unicode sequences.
    int unicodeSize;            // Max nr of unicode sequences.
}

-(id)initWithFirstCid:(unsigned int)fCid andLastCid:(unsigned int)lCid;
-(int)addUnicode:(unsigned int *)unicode length:(int)length;

@end
