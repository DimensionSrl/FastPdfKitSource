//
//  FPKZoomCache.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 11/03/15.
//
//

#import <Foundation/Foundation.h>

@interface FPKPageZoom : NSObject
@property (nonatomic,readwrite) CGRect rect;
@end

@interface FPKPageZoomCache : NSObject

@property (nonatomic,strong) NSMutableDictionary * cache;

-(FPKPageZoom *)pageZoomForPage:(NSUInteger)page;
-(void)setPageZoom:(FPKPageZoom *)zoom page:(NSUInteger)page;
-(void)setpageZoom:(CGRect)rect page:(NSUInteger)page;

@end
