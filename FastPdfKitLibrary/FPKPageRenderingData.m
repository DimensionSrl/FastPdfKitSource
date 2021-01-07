//
//  MFPageData.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FPKPageRenderingData.h"
#import <QuartzCore/QuartzCore.h>

@implementation FPKPageData

+(FPKPageData  *)zeroData {
    static FPKPageData * zero = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zero = [FPKPageData new];
        zero.page = 0;
        zero.metrics = [FPKPageMetrics zeroMetrics];
    });
    return zero;
}

+(FPKPageData *)dataWithPage:(NSUInteger)page metrics:(FPKPageMetrics *)metrics {
    FPKPageData * data = [FPKPageData new];
    data.page = page;
    data.metrics = metrics;
    return data;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%p> {page:%lu\n,\nmetrics: %@\n}", self, (unsigned long)_page, _metrics.description];
}

-(BOOL)isEmpty {
    return [self isEqual:[FPKPageData zeroData]];
}

-(NSUInteger)hash {
    NSUInteger hash = 17;
    hash = hash * 31 + _page;
    hash = hash * 31 + _metrics.hash;
    return hash;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else if (![other isKindOfClass:[FPKPageData class]]){
        return NO;
    }
    FPKPageData * otherData = (FPKPageData *)other;
    return _page == otherData.page && [_metrics isEqual:otherData.metrics];
}

@end

@interface FPKPageRenderingData()
@property (nonatomic, strong) FPKPageData * data;
@end

@implementation FPKPageRenderingData

-(BOOL)isEmpty {
    return [self isEqual:[FPKPageRenderingData zeroData]];
}

@synthesize ui_image;
@synthesize thumb;
@synthesize  description;

+(FPKPageRenderingData *)zeroData {
    static FPKPageRenderingData * zeroData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zeroData = [[FPKPageRenderingData alloc]init];
        zeroData.data = [FPKPageData zeroData];
        zeroData.ui_image = nil;
        zeroData.thumb = FALSE;
    });
    return zeroData;
}

+(FPKPageRenderingData *)dataWithData:(FPKPageData *)data {
    FPKPageRenderingData * prd = [FPKPageRenderingData new];
    prd.data = data;
    return prd;
}

+(FPKPageRenderingData *)dataWithPage:(NSUInteger)page metrics:(FPKPageMetrics *)metrics {
    FPKPageRenderingData * data = [FPKPageRenderingData new];
    data.data = [FPKPageData dataWithPage:page metrics:metrics];
    return data;
}

@end

@implementation MFPageDataOldEngine

@synthesize left, right;
@synthesize legacy, shadow;
@synthesize mode;
@synthesize padding;
@synthesize angle, cropbox, size;
@synthesize operationId;
-(BOOL)isEqualToPageData:(MFPageDataOldEngine *)other {
    
    if(self.left!=other.left)
        return NO;
    if(self.right!=other.right)
        return NO;
    if(self.mode!=other.mode)
        return NO;
    if(!CGSizeEqualToSize(self.size, other.size))
        return NO;
    if(fabs(self.padding - other.padding) > FLT_MIN)
        return NO;
    return (self.shadow==other.shadow && self.legacy == other.legacy);
}


-(void)setImage:(CGImageRef)newImage {
    if(image!=newImage) {
        CGImageRelease(image);
        image = CGImageRetain(newImage);
    }
}

-(CGImageRef)image {
    return image;
}

-(void)dealloc {
    
    CGImageRelease(image);
}
@end
