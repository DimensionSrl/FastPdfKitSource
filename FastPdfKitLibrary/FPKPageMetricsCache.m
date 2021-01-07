//
//  FPKPageMetricsCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 26/11/14.
//
//

#import "FPKPageMetricsCache.h"

@implementation FPKPageMetricsCache

-(void)addMetrics:(FPKPageData *)metrics {
    
    id key = @(metrics.page);
    
    pthread_rwlock_wrlock(&_lock);
    [_cache setObject:metrics forKey:key];
    pthread_rwlock_unlock(&_lock);
}

-(FPKPageData *)metricsWithPage:(NSUInteger)page {
    
    id key = @(page);
    FPKPageData * metrics = nil;
    
    pthread_rwlock_rdlock(&_lock);
    metrics =  [_cache objectForKey:key];
    pthread_rwlock_unlock(&_lock);
    
    return metrics;
}

@end
