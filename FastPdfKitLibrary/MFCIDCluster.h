//
//  MFCIDCluster.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFCIDRange : NSObject {

    unsigned int sequenceFirst;
    unsigned int sequenceLast;
    unsigned int cid;
    int length;
}

-(int)isSequenceInRange:(unsigned int)sequence;
-(int)getCid:(unsigned int *)cid forSequence:(unsigned int)sequence;
@property (readwrite) int length;
@end


@interface MFCIDRangeSingle : MFCIDRange {

}

-(id)initWithSequence:(unsigned int)sequence andCid:(unsigned int)cid;

@end


@interface MFCIDRangeSequential : MFCIDRange {

}

-(id)initWithFirstSequence:(unsigned int)sequence lastSequence:(unsigned int)lSeq andCid:(unsigned int)cid;

@end


@interface MFCIDRangeMulti : MFCIDRange {

    unsigned int *cids;
    int cids_len;
    int cids_max;
}

-(id)initWithFirstSequence:(unsigned int)fSeq;
-(int)addCid:(unsigned int)cid;

@end


@interface MFCIDCluster : NSObject {
    
    NSMutableArray * ranges;
    
}
-(void)addRange:(MFCIDRange *)range;
-(int)getCid:(unsigned int *)cid forSequence:(unsigned int)sequence ofLength:(int)length;

@end
