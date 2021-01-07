//
//  MFCIDCluster.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFCIDCluster.h"

#define DEF_CIDS_SIZE 10

@implementation MFCIDRange

@synthesize length;

-(id)init {
    
    if((self = [super init])) {
        
        sequenceFirst = 0;
        sequenceLast = 0;
        cid = 0;
        
    }
    return self;
}

-(int)getCid:(unsigned int *)cid forSequence:(unsigned int)sequence {
    return 0;
}

-(int)isSequenceInRange:(unsigned int)sequence {
    if(sequence < sequenceFirst || sequence > sequenceLast)
        return 0;
    return 1;
}

@end

@implementation MFCIDRangeSingle

-(NSString *)description {
    
    return [NSString stringWithFormat:@"[<%X> %X]", sequenceFirst, cid];
}


-(id)initWithSequence:(unsigned int)sequence andCid:(unsigned int)c {
    
    if((self = [super init])) {
        
        sequenceFirst = sequence;
        sequenceLast = sequence;
        cid = c;
    }
    return self;
}

-(int)getCid:(unsigned int *)c forSequence:(unsigned int)sequence {
    
    if(sequence < sequenceFirst || sequence > sequenceLast)
        return 0;
    *c = cid;
    return 1;
}

@end

@implementation MFCIDRangeSequential

-(id)initWithFirstSequence:(unsigned int)fSeq lastSequence:(unsigned int)lSeq andCid:(unsigned int)c {
    if((self = [super init])) {
        sequenceFirst = fSeq;
        sequenceLast = lSeq;
        cid = c;
    }
    return self;
}


-(NSString *)description {
    
    return [NSString stringWithFormat:@"[<%X %X> %X]", sequenceFirst, sequenceLast, cid];
}

-(int)getCid:(unsigned int *)c forSequence:(unsigned int)sequence {
    
    if(sequence < sequenceFirst || sequence > sequenceLast)
        return 0;
    
    int offset = sequence - sequenceFirst; // Ranges from 0 to sequenceLast - sequenceFirst
    *c = cid + offset;
    
    return 1;
}

@end

@implementation MFCIDRangeMulti


-(NSString *)description {
    
    NSString * desc = [NSString stringWithFormat:@"[<%X %X>", sequenceFirst, sequenceLast];
    
    int i;
    for(i = 0; i < cids_len; i++) {
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@" %X", cids[i]]];
    }
    
    desc = [desc stringByAppendingString:@"]"];
    
    return desc;
}

-(id)initWithFirstSequence:(unsigned int)fSeq {
    
    if((self = [super init])) {
    
        sequenceLast = sequenceFirst = fSeq;
        
        cids = calloc(DEF_CIDS_SIZE,sizeof(unsigned int));
        cids_max = DEF_CIDS_SIZE;
        cids_len = 0;
    }
    return self;
}

-(int)addCid:(unsigned int)c {
    
    if(cids_len == cids_max) {
        
        unsigned int * tmp = calloc(cids_max + DEF_CIDS_SIZE, sizeof(unsigned int));
        memcpy(tmp,cids,cids_len);
        
        cids_max+=DEF_CIDS_SIZE;
        free(cids);
        cids = tmp;
    }
    
    cids[cids_len] = c;
    cids_len++;
    sequenceLast++;
    
    return cids_len;
}

-(int)getCid:(unsigned int *)c forSequence:(unsigned int)sequence {
    
    if(sequence < sequenceFirst || sequence > sequenceLast)
        return 0;
    
    *c = cids[sequence - sequenceFirst];
    return 1;
}

-(void)dealloc {
    
    if(cids)
        free(cids),cids = NULL;
    
    [super dealloc];
}

@end

@implementation MFCIDCluster

-(NSString *)description {
    
    NSString * desc = @"[";
    
    for(MFCIDRange * range in ranges) {
        desc = [desc stringByAppendingString:[range description]];
    }
    
    desc = [desc stringByAppendingString:@"]"];
    
    return desc;
}

-(id)init {
    
    if((self = [super init])) {
        
        ranges = [[NSMutableArray alloc]init];
        
    }
    return self;
}

-(void)addRange:(MFCIDRange *)range {
    [ranges addObject:range];
}

-(int)getCid:(unsigned int *)cid forSequence:(unsigned int)sequence ofLength:(int)length {
    
    int found = 0;
    for(MFCIDRange * range in ranges) {
        
        if(range.length!=length)
            continue;
        
        if((found = [range getCid:cid forSequence:sequence]))
            break;
    }
    return found;
}

-(void)dealloc {
    
    [ranges release],ranges = nil;
    
    [super dealloc];
}

@end
