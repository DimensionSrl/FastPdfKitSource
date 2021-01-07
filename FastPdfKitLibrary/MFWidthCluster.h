//
//  MFWidthCluster.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFWidthRange : NSObject {

    unsigned int cidFirst;
    unsigned int cidLast;
}

-(int)isCidInRange:(unsigned int)cid;
-(int)getWidth:(CGFloat *) width forCid:(unsigned int)cid;
-(CGFloat)averageWidth;

@end

@interface MFWidthRangeSingle : MFWidthRange {
    
    CGFloat width;
}
-(id)initWithFirstCid:(unsigned int)fCid lastCid:(unsigned int)lCid andWidth:(CGFloat)w;

@end

@interface MFWidthRangeMulti : MFWidthRange {

    int widths_len;
    int widths_max;
    CGFloat * widths;
}
-(id)initWithFirstCid:(unsigned int)fCid andCount:(int)count;
-(int)addWidth:(CGFloat)width;

@end

@interface MFWidthCluster : NSObject {
    
    NSMutableArray * ranges;
    
}

-(void)addRange:(MFWidthRange *)range;
-(int)getWidth:(CGFloat *)width forCid:(unsigned int)cid;
-(float)averageWidth;

@end
