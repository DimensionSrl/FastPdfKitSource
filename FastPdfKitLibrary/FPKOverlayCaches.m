//
//  FPKOverlayCaches.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 02/09/15.
//
//

#import "FPKOverlayCaches.h"

@implementation FPKOverlayCaches

-(instancetype)init {
    self = [super init];
    if(self) {
        self.caches = [NSMutableDictionary new];
    }
    return self;
}

-(void)setCache:(id)cache name:(NSString *)name {
    [self.caches setValue:cache forKey:name];
}

-(id)cacheForName:(NSString *)name {
    return [self.caches valueForKey:name];
}

-(void)removeAllObjects {
    for (id object in _caches) {
        [object removeAllObjects];
    }
}

@end
