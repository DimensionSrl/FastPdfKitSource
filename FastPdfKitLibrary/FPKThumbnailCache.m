//
//  FPKThumbnailCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import "FPKThumbnailCache.h"

@implementation FPKThumbnailCache

+(FPKThumbnailCache *)cacheWithCostLimit:(NSUInteger)costLimit
{
    FPKThumbnailCache * cache = [FPKThumbnailCache new];
    cache.cache.name = @"thumbnails";
    cache.cache.totalCostLimit = FPKCacheSize2M;
    return cache;
}

-(NSData *)thumbnailDataForPage:(NSUInteger)page {
    
    id key = @(page);
    NSData * data = nil;
    
    pthread_rwlock_rdlock(&_lock);
    data =[_cache objectForKey:key];
    pthread_rwlock_unlock(&_lock);
    return data;
}

-(void)addThumbnailData:(NSData *)data page:(NSUInteger)page {
    
    if(data) {
    id key = @(page);
    
    pthread_rwlock_wrlock(&_lock);
    [_cache setObject:data forKey:key cost:data.length];
    pthread_rwlock_unlock(&_lock);
    }
}

@end
