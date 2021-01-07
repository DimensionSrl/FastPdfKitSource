//
//  FPKThumbnailCache.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FPKCache.h"

@interface FPKThumbnailCache : FPKCache

-(NSData *)thumbnailDataForPage:(NSUInteger)page;
-(void)addThumbnailData:(NSData *)data page:(NSUInteger)page;

+(FPKThumbnailCache *)cacheWithCostLimit:(NSUInteger)costLimit;

@end
