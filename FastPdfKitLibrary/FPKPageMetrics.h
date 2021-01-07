//
//  FPKPageMetrics.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import <Foundation/Foundation.h>

@protocol FPKMetrics
-(BOOL)isEmpty;
@end

@interface FPKTransformData : NSObject

@property (nonatomic, readonly) CGAffineTransform transform;
@property (nonatomic, readonly) CGRect frame;

+(nonnull FPKTransformData *)zeroData;

-(nullable instancetype)initWithTransform:(CGAffineTransform)transform frame:(CGRect)frame;

@end

@protocol FPKTransformCache
-(nullable FPKTransformData *)transformDataWithContainerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip;
@end

@interface FPKTransformCacheBase : NSObject <FPKTransformCache>
@property (nonatomic, readwrite) CGRect cropbox;
@property (nonatomic, readwrite) NSInteger rotation;
@end

@interface FPKTransformCacheSingle : FPKTransformCacheBase

@end

@interface FPKTransformCacheLeft : FPKTransformCacheBase

@end

@interface FPKTransformCacheRight : FPKTransformCacheBase

@end

@interface FPKTransformCacheZero : NSObject <FPKTransformCache>

@end

@interface FPKPageMetrics : NSObject <FPKMetrics>

@property (nonatomic, readonly) CGRect cropbox;
@property (nonatomic, readonly) int angle;

@property (nonnull, readonly) id<FPKTransformCache> single;
@property (nonnull, readonly) id<FPKTransformCache> doubleLeft;
@property (nonnull, readonly) id<FPKTransformCache> doubleRight;

-(nullable instancetype)initWithCropbox:(CGRect)cropbox angle:(int)angle;
-(nullable instancetype)initWithMetrics:(nullable FPKPageMetrics *)other;

+(nonnull FPKPageMetrics *)zeroMetrics;

@end

@interface FPKPageMetricsFactory : NSObject
-(nullable FPKPageMetrics *)metricsWithCropbox:(CGRect)box angle:(int)angle;
@end
