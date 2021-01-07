//
//  FPKZoomCache.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 11/03/15.
//
//

#import "FPKPageZoomCache.h"

@implementation FPKPageZoom

@end

@implementation FPKPageZoomCache

-(instancetype)init {
    self = [super init];
    if(self) {
        self.cache = [NSMutableDictionary new];
    }
    return self;
}

-(FPKPageZoom *)pageZoomForPage:(NSUInteger)page {
    return [self.cache objectForKey:@(page)];
}

-(void)setPageZoom:(FPKPageZoom *)zoom page:(NSUInteger)page {
    [self.cache setObject:zoom forKey:@(page)];
}

-(void)setpageZoom:(CGRect)rect page:(NSUInteger)page {
    FPKPageZoom * zoom = [FPKPageZoom new];
    zoom.rect = rect;
    [self.cache setObject:zoom forKey:@(page)];
}

@end
