//
//  FPKPageMetricsCache.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 26/11/14.
//
//

#import <UIKit/UIKit.h>
#import "FPKPageRenderingData.h"
#import "FPKCache.h"

@interface FPKPageMetricsCache : FPKCache

-(FPKPageData *)metricsWithPage:(NSUInteger)page;
-(void)addMetrics:(FPKPageData *)metrics;

@property (nonatomic, readwrite) NSUInteger limit;

@end
