//
//  MFWidthCluster.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFWidthCluster.h"

#define DEF_WIDTHS_SIZE 10

@implementation MFWidthRange

-(id)init {
    
    if((self = [super init])) {
        cidLast = 0;
        cidFirst = 0;
    }
    return self;
}

-(int)getWidth:(CGFloat *)width forCid:(unsigned int)cid {
    *width = 0;
    return 0;
}

-(int)isCidInRange:(unsigned int)cid {
    if(cid < cidFirst || cid > cidLast)
        return 0;
    return 1;
}

-(CGFloat)averageWidth {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end

@implementation MFWidthRangeSingle

-(id)initWithFirstCid:(unsigned int)fCid lastCid:(unsigned int)lCid andWidth:(CGFloat)w {
    if((self = [super init])) {
        
        cidLast = lCid;
        cidFirst = fCid;
        width = w;
        
    }
    return self;
}

-(int)getWidth:(CGFloat *)w forCid:(unsigned int)cid {
    
    if(cid < cidFirst || cid > cidLast) 
        return 0;
    
    *w = width;
    
    return 1;
}

-(CGFloat)averageWidth {
    return width;
}

@end

@implementation MFWidthRangeMulti

-(id)initWithFirstCid:(unsigned int)fCid andCount:(int)count {
    if((self = [super init])) {
        
        cidFirst = fCid;
        cidLast = cidFirst + count - 1;
        
        widths = calloc(count, sizeof(CGFloat));
        widths_len = 0;
        widths_max = count;
    }
    return self;
}

-(CGFloat)averageWidth {
    
    CGFloat acc = 0.0;
    int i;
    int notNulls = 0;
    for(i = 0; i < widths_len; i++) {
        CGFloat tmp = widths[i];
        if(tmp > 0.0)
        {
        acc+=widths[i];
            notNulls++;
        }
    }
    
    return acc/(CGFloat)notNulls;
}

-(int)getWidth:(CGFloat *)width forCid:(unsigned int)cid {
    
    if(cid < cidFirst || cid > cidLast)
        return 0;
    
    int offset = cid - cidFirst;
    *width = widths[offset];
    
    return 1;
}

-(int)addWidth:(CGFloat)width {
    
    if(widths_len == widths_max) {
        
        CGFloat * tmp = calloc(widths_max+DEF_WIDTHS_SIZE, sizeof(CGFloat));
        memcpy(tmp,widths,widths_len);
        
        free(widths);
        widths = tmp;
        widths_max+=DEF_WIDTHS_SIZE;
    }
    
    widths[widths_len]=width;
    widths_len++;
    
    return widths_len;
}

-(void)dealloc {
    
    if(widths)
        free(widths),widths = NULL;
    
    [super dealloc];
}

@end

@implementation MFWidthCluster

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

-(void)addRange:(MFWidthRange *)range {
    
    [ranges addObject:range];
}

-(int)getWidth:(CGFloat *)width forCid:(unsigned int)cid {
    
    int found = 0;
    
    for(MFWidthRange * range in ranges) {
        
        if((found = [range getWidth:width forCid:cid]))
            break;
    }
    
    return found;
}

-(float)averageWidth {
    
    float acc = 0.0f;
    int notNulls = 0;
    
    for(MFWidthRange * range in ranges)
    {
        float tmp = [range averageWidth];
        if(tmp > 0.0)
        {
            acc+=tmp;
            notNulls++;
        }
    }
    return (acc/(float)notNulls);
}

@end
