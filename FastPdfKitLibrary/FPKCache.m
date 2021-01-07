//
//  FPKCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import "FPKCache.h"

@interface FPKCache() <NSCacheDelegate>

@end

@implementation FPKCache
@synthesize cache = _cache;

-(instancetype)init {
    self = [super init];
    if(self) {
        _cache = [NSCache new];
        pthread_rwlock_init(&_lock, NULL);
    }
    return self;
}

-(void)dealloc {
    pthread_rwlock_destroy(&_lock);
}

@end
