//
//  MFUnicodeCluster.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFUnicodeCluster.h"

#define MFUC_UNICODES_SIZE 10
#define MFUC_UNICODE_WIDTH 4
#define MFUC_UNICODE_NOTDEF 0x25AF

unsigned int * copyUnicodeBuffer(unsigned int * src, int length) {
    unsigned int * tmp = calloc(length, MFUC_UNICODE_WIDTH);
    memcpy(tmp, src, length * MFUC_UNICODE_WIDTH);
    return tmp;
}

@implementation MFUnicodeRange

/*
 Incomplete implementation due to the missing getUnicode:length:forCid:.
 */

-(int)isCidInRange:(int)cid {

    if(cid < cidFirst || cid > cidLast)
        return 0;
    return 1;
}

-(int)getUnicode:(unsigned int **)u length:(int*)length forCid:(unsigned int)cid {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end


@implementation MFUnicodeRangeSingle 

-(NSString *)description {
    
    NSString * desc = [NSString stringWithFormat:@"[<%d %d>]", cidFirst, cidLast];
    
    return desc;
}

-(id)initWithCid:(unsigned int)c andUnicode:(unsigned int *)u length:(int)length {
    if((self = [super init])) {
        
        cidLast = cidFirst = c;
        unicode = copyUnicodeBuffer(u, length);
        unicodeLength = length;
        
    }
    return self;
}

-(int)getUnicode:(unsigned int **)u length:(int *)length forCid:(unsigned int)cid {
    
    if(cid < cidFirst || cid > cidLast)
        return 0;
    
    *u = unicode;
    *length = unicodeLength;
    return 1;
}

-(void)dealloc {
    
    free(unicode);
    
    [super dealloc];
}

@end


@implementation MFUnicodeRangeSequential

-(NSString *)description {
    
    NSString * desc = [NSString stringWithFormat:@"[<%d %d>", cidFirst, cidLast];
    
    desc = [desc stringByAppendingString:@"]"];
    
    return desc;
}

-(id)initWithFirstCid:(unsigned int)fCid lastCid:(unsigned int)lCid andFirstUnicode:(unsigned int *)fUnicode length:(int)length {
    
    if((self = [super init])) {
        
        int index;
        
        cidLast = lCid;
        cidFirst = fCid;
        
        unicodeCount = lCid-fCid+1;
        unicodeLength = length;
        
        unicodes = calloc(unicodeCount, sizeof(unsigned int *));
        
        for(index = 0; index < unicodeCount; index++) {
            
            unicodes[index] = copyUnicodeBuffer(fUnicode, length);
            
            unicodes[index][length-1]+=index; // This way, if U0 is U+0105, U1 is U+0106, U2 is U+0107, etc
        }
    }
    
    return self;
}

-(int)getUnicode:(unsigned int **)u length:(int *)length forCid:(unsigned int)cid {
    
    if(cid < cidFirst || cid > cidLast) {
        return 0;
    }
    
    *u = unicodes[cid-cidFirst];
    *length = unicodeLength;
    
    return 1;
}

-(void)dealloc {
    
    int index;
    for(index = 0; index < unicodeCount; index++) {
        free(unicodes[index]);
    }
    free(unicodes);
    
    [super dealloc];
}

@end

@implementation MFUnicodeRangeMulti

-(NSString *)description {
    
    NSString * desc = [NSString stringWithFormat:@"[<%d %d>", cidFirst, cidLast];
    
    desc = [desc stringByAppendingString:@"]"];
    
    return desc;
}

-(id)initWithFirstCid:(unsigned int)fCid andLastCid:(unsigned int)lCid {
    if((self = [super init])) {
        
        cidFirst = fCid;
        cidLast = lCid;
        
        unicodeSize = lCid - fCid + 1;
        unicodeCount = 0;
        unicodes = calloc(unicodeSize, sizeof(unsigned int *));
        unicodeLengths = calloc(unicodeSize, sizeof(int));
        
    }
    return self;
}

-(int)addUnicode:(unsigned int *)unicode length:(int)length {
    
    if(unicodeCount >= unicodeSize) {
        
        int newSize = unicodeSize+5;
        unsigned int ** tmp = calloc(newSize, sizeof(unsigned int *));
        memcpy(tmp, unicodes, unicodeCount * sizeof(unsigned int *));
        free(unicodes);
        unicodes = tmp;
        
        int * tmp2 = calloc(newSize, sizeof(int));
        memcpy(tmp2, unicodeLengths, unicodeCount * sizeof(int));
        free(unicodeLengths);
        unicodeLengths = tmp2;
        
        unicodeSize = newSize;
    }
    
    unicodes[unicodeCount] = copyUnicodeBuffer(unicode, length);
    unicodeLengths[unicodeCount] = length;
    
    return ++unicodeCount;
}

-(int)getUnicode:(unsigned int **)u length:(int *)length forCid:(unsigned int)cid {
    
    if(cid < cidFirst || cid > cidLast)
        return 0;
    
    int pos = cid-cidFirst;
    
    *u = unicodes[pos];
    *length = unicodeLengths[pos];
    
    return 1;
}

-(void)dealloc {
    
    int index;
    for(index = 0; index < unicodeCount; index++) {
        free(unicodes[index]);
    }
    free(unicodes);
   
    free(unicodeLengths);
    
    [super dealloc];
}

@end

@implementation MFUnicodeCluster

-(NSString *)description {
    NSString * desc = @"[";
    
    for(MFUnicodeRange * range in ranges) {
        desc = [desc stringByAppendingString:[range description]];
    }
    
    desc = [desc stringByAppendingString:@"]"];
    
    return desc;
}

-(int)getUnicode:(unsigned int **)unicode length:(int *)length forCid:(unsigned int)cid {
    
    int found = 0;
    NSUInteger count = [ranges count];
    NSUInteger index;
    MFUnicodeRange * range = NULL;
    
    for(index = 0; index < count && (!found); index++) {
        
        range = [ranges objectAtIndex:index];
        found = [range getUnicode:unicode length:length forCid:cid];
    }
    
    return found;
}

-(void)addRange:(MFUnicodeRange *)range {
    
    [ranges addObject:range];
}

-(id)init {
    if((self = [super init])) {
        
        ranges = [[NSMutableArray alloc]init];
        
    }
    return self;
}

-(void)dealloc {
    
    [ranges release],ranges = nil;
    [super dealloc];
}

@end
