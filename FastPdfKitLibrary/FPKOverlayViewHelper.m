//
//  FPKOverlayViewHelper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 28/11/14.
//
//

#import "FPKOverlayViewHelper.h"
#import "FPKBaseDocumentViewController_private.h"

@interface FPKOverlayViewHelper()

@property (nonatomic, strong) NSMutableSet * cache;

@end

@implementation FPKOverlayViewHelper

-(instancetype)init {
    self = [super init];
    if(self) {
        self.cache = [NSMutableSet new];
    }
    return self;
}

-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page {
    
#if DEBUG
    NSLog(@"overlayView: %p overlayViewForPage: %lu", overlayView, (unsigned long)page);
#endif
    
    if(page == 0) {
        return @[];
    }

    NSArray * views = [self.documentViewController overlayViewsForPage:page];
    
    NSMutableArray * array = [NSMutableArray new];
    
    [views enumerateObjectsUsingBlock:^(FPKOverlayViewHolder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        CGRect rect = [self.documentViewController collectRectForOverlayView:obj page:page];
        
        // Scarto gli obj senza rettangolo...
        if(!CGRectIsNull(rect)) {
            obj.rect = rect;
            obj.owner = self;
            [array addObject:obj];
        }
    }];
    
    return array;
}

-(void)overlayView:(MFOverlayView *)overlayView didAddOverlayView:(FPKOverlayViewHolder *)view
{
    [self.documentViewController didAddOverlayView:view];
}

-(void)overlayView:(MFOverlayView *)overlayView didRemoveOverlayView:(FPKOverlayViewHolder *)view
{
    [self.documentViewController didRemoveOverlayView:view];
}

-(void)overlayView:(MFOverlayView *)overlayView willAddOverlayView:(FPKOverlayViewHolder *)view
{
    [self.documentViewController willAddOverlayView:view];
}

-(void)overlayView:(MFOverlayView *)overlayView willRemoveOverlayView:(FPKOverlayViewHolder *)view
{
    [self.documentViewController willRemoveOverlayView:view];
}

#pragma mark - Caching

-(FPKOverlayViewHolder *)dequeueOverlayWrapper {
    FPKOverlayViewHolder * wrapper = [_cache anyObject];
    if(wrapper) {
        [_cache removeObject:wrapper];
    } else {
        wrapper = [FPKOverlayViewHolder new];
        wrapper.owner = self;
    }
    return wrapper;
}

-(void)enqueueOverlayWrapper:(FPKOverlayViewHolder *)wrapper {
    
    wrapper.view = nil;
    wrapper.rect = CGRectZero;
    wrapper.dataSource = nil;
    
    if(_cache.count < 10) {
        [_cache addObject:wrapper];
    }
}

@end
