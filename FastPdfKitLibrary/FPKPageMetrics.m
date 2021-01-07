//
//  FPKPageMetrics.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import "FPKPageMetrics.h"
#import <malloc/malloc.h>
#import "PrivateStuff.h"
#import <pthread/pthread.h>

@interface FPKPageMetrics()
@property (nonnull, readwrite) id<FPKTransformCache> single;
@property (nonnull, readwrite) id<FPKTransformCache> doubleLeft;
@property (nonnull, readwrite) id<FPKTransformCache> doubleRight;
@end

@implementation FPKPageMetrics

-(BOOL)isEmpty {
    return [self isEqual:[FPKPageMetrics zeroMetrics]];
}

-(BOOL)isEqual:(id)object {
    if(self == object) {
        return true;
    }
    if(object == nil) {
        return false;
    }
    if(![object isKindOfClass:[FPKPageMetrics class]]) {
        return false;
    }
    
    FPKPageMetrics * other = (FPKPageMetrics *)object;
    if(_angle!=other.angle) {
        return false;
    }
    
    CGFloat otherValue = other.cropbox.size.width;
    if((*(NSUInteger *)&_cropbox.size.width)!=(*(NSUInteger *)&otherValue)) {
        return false;
    }
    
    otherValue = other.cropbox.size.height;
    if((*(NSUInteger *)&_cropbox.size.height)!=(*(NSUInteger *)&otherValue)) {
        return false;
    }
    
    otherValue = other.cropbox.origin.x;
    if((*(NSUInteger *)&_cropbox.origin.x)!=(*(NSUInteger *)&otherValue)) {
        return false;
    }
    
    otherValue = other.cropbox.origin.y;
    if((*(NSUInteger *)&_cropbox.origin.y)!=(*(NSUInteger *)&otherValue)) {
        return false;
    }
    
    return true;
}

-(instancetype)initWithMetrics:(FPKPageMetrics *)other {
    self = [super init];
    if(self) {
        _cropbox = other.cropbox;
        _angle = other.angle;
    }
    return self;
}

-(instancetype)initWithCropbox:(CGRect)cropbox angle:(int)angle {
    self = [super init];
    if(self) {
        _cropbox = cropbox;
        _angle = angle;
    }
    return self;
}

-(NSUInteger)hash {
    NSUInteger hash = 31;
    hash = (hash * 17) + _angle;
    hash = hash * 17 + (*(NSUInteger *)&_cropbox.size.width);
    hash = hash * 17 + (*(NSUInteger *)&_cropbox.size.height);
    hash = hash * 17 + (*(NSUInteger *)&_cropbox.origin.x);
    hash = hash * 17 + (*(NSUInteger *)&_cropbox.origin.y);
    return hash;
}

+(FPKPageMetrics *)zeroMetrics {
    static FPKPageMetrics * zeroMetrics = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zeroMetrics = [[FPKPageMetrics alloc]initWithCropbox:CGRectZero angle:0];
        FPKTransformCacheZero * cache = [FPKTransformCacheZero new];
        zeroMetrics.single = cache;
        zeroMetrics.doubleLeft = cache;
        zeroMetrics.doubleRight = cache;
    });
    return zeroMetrics;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"FPKPageMetrics <%p>{angle:%d,\ncropbox:%@}",self,_angle, NSStringFromCGRect(_cropbox)];
}

@end

#pragma mark -

@implementation FPKTransformCacheZero

-(FPKTransformData *)transformDataWithContainerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    return [FPKTransformData zeroData];
}

@end

#pragma mark -

@interface FPKPageMetricsFactory()

@property (nonnull, readonly) NSMutableDictionary * metrics;

@end

@implementation FPKPageMetricsFactory

-(instancetype)init {
    self = [super init];
    if(self) {
        _metrics = [NSMutableDictionary new];
    }
    return self;
}

+(NSUInteger)calculateKeyWithCropbox:(CGRect)cropbox angle:(int)angle {
    NSUInteger hash = 31;
    hash = (hash * 17) + angle;
    hash = hash * 17 + (*(NSUInteger *)&cropbox.size.width);
    hash = hash * 17 + (*(NSUInteger *)&cropbox.size.height);
    hash = hash * 17 + (*(NSUInteger *)&cropbox.origin.x);
    hash = hash * 17 + (*(NSUInteger *)&cropbox.origin.y);
    return hash;
}

-(FPKPageMetrics *)metricsWithCropbox:(CGRect)box angle:(int)angle {

    NSNumber * key = @([FPKPageMetricsFactory calculateKeyWithCropbox:box angle:angle]);
    FPKPageMetrics * metric = [[self metrics] objectForKey:key];
    if(!metric) {
        metric = [[FPKPageMetrics alloc]initWithCropbox:box angle:angle];
        
#if DEBUG
        FPKTransformCacheSingle * single = [FPKTransformCacheSingle new];
        single.cropbox = box;
        single.rotation = angle;
        metric.single = single;
        
        FPKTransformCacheLeft * left = [FPKTransformCacheLeft new];
        left.cropbox = box;
        left.rotation = angle;
        metric.doubleLeft = left;
        
        FPKTransformCacheRight * right = [FPKTransformCacheRight new];
        right.cropbox = box;
        right.rotation = angle;
        metric.doubleRight = right;
#endif
        
        _metrics[key] = metric;
    }
    
    return metric;
}

@end

#pragma mark -

@interface FPKTransformData()

@property (nonatomic, readwrite) CGAffineTransform transform;
@property (nonatomic, readwrite) CGRect frame;
@end

@implementation FPKTransformData

-(instancetype)initWithTransform:(CGAffineTransform)transform frame:(CGRect)frame {
    self = [super init];
    if(self) {
        self.transform = transform;
        self.frame = frame;
    }
    return self;
}

+(FPKTransformData *)zeroData {
    static FPKTransformData * zero = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zero = [[FPKTransformData alloc]initWithTransform:CGAffineTransformIdentity frame:CGRectZero];
    });
    return zero;
}

@end

#pragma mark - Caches

@interface FPKTransformCacheBase() {
    pthread_rwlock_t _lock;
}
@property (nonatomic, strong) NSCache * cache;
@end

@implementation FPKTransformCacheBase

-(instancetype)init {
    self = [super init];
    if(self) {
        
        pthread_rwlock_init(&_lock, NULL);
        NSCache * cache = [NSCache new];
        cache.countLimit = 100;
        self.cache = cache;
    }
    return self;
}

-(void)dealloc {
    pthread_rwlock_destroy(&_lock);
}

-(id)keyForContainerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    NSUInteger hash = 17;
    hash = hash * 31 + *((NSUInteger *)&size.width);
    hash = hash * 31 + *((NSUInteger *)&size.height);
    hash = hash * 31 + *((NSUInteger *)&padding);
    hash = hash * 31 + (flip ? 1 : 0);
    return @(hash);
}

-(FPKTransformData *)createTransformDataWithCropbox:(CGRect)box rotation:(NSInteger)rotation containerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"You must implement this method in a subclass" userInfo:nil];
}

-(FPKTransformData *)transformDataWithContainerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    id key = [self keyForContainerSize:size padding:padding flip:flip];
    
    pthread_rwlock_rdlock(&_lock);
    FPKTransformData * data = [self.cache objectForKey:key];
    pthread_rwlock_unlock(&_lock);
    
    if(data) {
        return data;
    }
    
    data = [self createTransformDataWithCropbox:_cropbox rotation:_rotation containerSize:size padding:padding flip:flip];
    
    pthread_rwlock_wrlock(&_lock);
    [self.cache setObject:data forKey:key];
    pthread_rwlock_unlock(&_lock);
    
    return data;
}

@end

@implementation FPKTransformCacheSingle
-(FPKTransformData *)createTransformDataWithCropbox:(CGRect)box rotation:(NSInteger)rotation containerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect frame = CGRectZero;
    transformAndBoxForPageRendering(&transform, &frame,size,box,rotation,padding,flip);
    FPKTransformData * data = [[FPKTransformData alloc]initWithTransform:transform frame:frame];
    return data;
}
@end

@implementation FPKTransformCacheLeft
-(FPKTransformData *)createTransformDataWithCropbox:(CGRect)box rotation:(NSInteger)rotation containerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect frame = CGRectZero;
    transformAndBoxForPageRenderingLeft(&transform, &frame,size,box,rotation,padding,flip);
    FPKTransformData * data = [[FPKTransformData alloc]initWithTransform:transform frame:frame];
    return data;
}
@end

@implementation FPKTransformCacheRight
-(FPKTransformData *)createTransformDataWithCropbox:(CGRect)box rotation:(NSInteger)rotation containerSize:(CGSize)size padding:(CGFloat)padding flip:(BOOL)flip {
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect frame = CGRectZero;
    transformAndBoxForPageRenderingRight(&transform, &frame,size,box,rotation,padding,flip);
    FPKTransformData * data = [[FPKTransformData alloc]initWithTransform:transform frame:frame];
    return data;
}
@end
