//
//  FPKCache.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import <Foundation/Foundation.h>
#import <pthread/pthread.h>

static const NSUInteger FPKCacheSize1M = 1024 * 1024;
static const NSUInteger FPKCacheSize2M = 2 * FPKCacheSize1M;
static const NSUInteger FPKCacheSize3M = 3 * FPKCacheSize1M;
static const NSUInteger FPKCacheSize4M = 4 * FPKCacheSize1M;
static const NSUInteger FPKCacheSize5M = 5 * FPKCacheSize1M;

@interface FPKCache : NSObject {
    
    @protected
    pthread_rwlock_t _lock;
    NSCache * _cache;
}
@property (nonatomic, strong) NSCache * cache;
@end
