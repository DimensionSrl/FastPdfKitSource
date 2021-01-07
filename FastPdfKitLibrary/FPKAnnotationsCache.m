//
//  FPKAnnotationCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#import "FPKAnnotationsCache.h"
#import <pthread/pthread.h>

typedef struct fpk_annotation_cache_entry {
    int16_t count;
} fpk_annotation_cache_entry;

typedef struct fpk_annotation_cache_block {
    fpk_annotation_cache_entry * entries;
    size_t count;
} fpk_annotation_cache_block;

int16_t fpk_annotation_cache_uncached = 0xffff;

void fpk_annotation_cache_block_init(fpk_annotation_cache_block * block, size_t count) {
    block -> count = count;
    size_t size = count * sizeof(fpk_annotation_cache_entry);
    block -> entries = malloc(size);
    memset(block->entries, 0xff, size);
}

void fpk_annotation_cache_block_destroy(fpk_annotation_cache_block * block) {
    if(block->entries) {
        free(block->entries),block->entries = NULL;
    }
    block->count = 0;
}

fpk_annotation_cache_block * fpk_annotation_cache_block_new(int count) {
    fpk_annotation_cache_block * block = malloc(sizeof(fpk_annotation_cache_block));
    fpk_annotation_cache_block_init(block,count);
    return block;
}

typedef struct fpk_annotation_cache {
    fpk_annotation_cache_block ** blocks;
    size_t blocks_count;
    size_t blocks_size;
} fpk_annotation_cache;

void fpk_annotation_cache_init(fpk_annotation_cache * cache, int block_size) {
    cache -> blocks_size = block_size;
    cache -> blocks_count = 1;
    cache -> blocks = malloc(sizeof(fpk_annotation_cache_block*));
    cache -> blocks[0] = fpk_annotation_cache_block_new(block_size);
}

fpk_annotation_cache * fpk_annotation_cache_new(int block_size) {
    fpk_annotation_cache * cache = malloc(sizeof(fpk_annotation_cache));
    fpk_annotation_cache_init(cache, block_size);
    return cache;
}

void fpk_annotation_cache_destroy(fpk_annotation_cache * cache) {
    size_t i;
    if(cache->blocks) {
    for(i = 0; i < cache->blocks_count; i++) {
        fpk_annotation_cache_block_destroy(*(cache->blocks+i));
    }
        free(cache->blocks), cache->blocks = NULL;
    }
    cache->blocks_count = 0;
    cache->blocks_size = 0;
}

void fpk_annotation_cache_grow(fpk_annotation_cache * cache, size_t index) {
    size_t blocks_size = cache->blocks_size;
    size_t blocks_count = cache->blocks_count;
    size_t required_blocks = index/blocks_size + 1;
    if(required_blocks > blocks_count) {
        size_t new_blocks_count = (required_blocks - blocks_count);
        size_t size = (new_blocks_count * sizeof(fpk_annotation_cache_block *));
        fpk_annotation_cache_block ** new_blocks = malloc(size);
        memcpy(new_blocks, cache->blocks, size);
        size_t i;
        for(i = blocks_count; blocks_count < new_blocks_count; i++) {
            new_blocks[i] = fpk_annotation_cache_block_new(blocks_size);
        }
        
        // Free the old block and assign the new ones.
        free(cache->blocks);
        cache->blocks = new_blocks;
        cache->blocks_count = new_blocks_count;
    }
}

fpk_annotation_cache_entry * fpk_annotation_cache_get_entry(fpk_annotation_cache * cache, size_t index) {
    if(!(index < cache ->blocks_size * cache -> blocks_count)) {
        fpk_annotation_cache_grow(cache, index);
    }
    size_t block_index = index/cache->blocks_size;
    size_t block_offset = index % cache->blocks_size;
    return &(cache->blocks[block_index]->entries[block_offset]);
}

int16_t fpk_annotation_cache_get_annotation_count(fpk_annotation_cache * cache, size_t index) {
    fpk_annotation_cache_entry * entry = fpk_annotation_cache_get_entry(cache, index);
    return entry->count;
}

void fpk_annotation_cache_set_annotation_count(fpk_annotation_cache * cache, int16_t count, size_t index) {
    fpk_annotation_cache_entry * entry = fpk_annotation_cache_get_entry(cache, index);
    entry->count = count;
}

@interface FPKAnnotationsCache() {
    pthread_rwlock_t _lock;
}
@property (nonatomic,strong) NSMutableDictionary * cache;
@end


@implementation FPKAnnotationsCache

-(void)dealloc {
    pthread_rwlock_destroy(&_lock);
}

-(instancetype)init {
    self = [super init];
    if(self) {
        _cache = [NSMutableDictionary new];
        pthread_rwlock_init(&_lock, NULL);
    }
    return self;
}

+(NSArray *)emptyAnnotations {
    static NSArray * empty = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        empty = [NSArray new];
    });
    return empty;
}

-(void)addAnnotationsCount:(NSUInteger)count page:(NSUInteger)page {
    id key = @(page);
    NSNumber * entry = @(count);
    pthread_rwlock_wrlock(&_lock);
    [_cache setObject:entry forKey:key];
    pthread_rwlock_unlock(&_lock);
}

-(NSInteger)annotationsCountForPage:(NSUInteger)page {
    id key = @(page);
    
    NSNumber * entry = nil;
    
    pthread_rwlock_rdlock(&_lock);
    
    entry = [_cache objectForKey:key];
    
    pthread_rwlock_unlock(&_lock);
    
    if(entry)
        return entry.unsignedIntegerValue;
    
    return NSNotFound;
}

@end
