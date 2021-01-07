//
//  FPKCalcsCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 09/12/14.
//
//

#import "FPKCalcsCache.h"

@implementation FPKCalcsCache

+(FPKCalcsCache *)defaultCache {
    static FPKCalcsCache * cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [FPKCalcsCache new];
    });
    return cache;
}

@end
