//
//  FPKDrawablesHelper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import "FPKDrawablesHelper.h"
#import "MFOverlayDrawable.h"
#import "MFOverlayTouchable.h"
#import "FPKBaseDocumentViewController_private.h"
#import "FPKDrawableOverlayView.h"
#import "MFDocumentManager_private.h"

@implementation FPKDrawablesHelper

-(FlipContainer *)touchablesForPage:(NSUInteger)page {
    return [self.documentViewController touchablesForPage:page];
}

-(FlipContainer *)drawablesForPage:(NSUInteger)page {
    return nil;
}

-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page {
    
    // 1. Get drawables as usual
    FlipContainer * drawables = [self.documentViewController drawablesForPage:page];
    
    // 2. If no drawables, then no overlay view
    if([drawables count] == 0) {
        return @[];
    }
    
    // 3. Get the wrapper for the page. Create one if it doesn't exist
    FPKOverlayViewHolder * wrapper = [self.cache objectForKey:@(page)];
    if(!wrapper) {
        
        FPKDrawableOverlayView * view = [FPKDrawableOverlayView new];
        
        FPKPageMetrics * metrics = [self.documentViewController.document pageMetricsForPage:page];
        view.metrics = metrics;
        
        wrapper = [FPKOverlayViewHolder new];
        wrapper.view = view;
        wrapper.rect = CGRectMake(0, 0, metrics.cropbox.size.width, metrics.cropbox.size.height);
        
        [self.cache setObject:wrapper forKey:@(page)];
    }

    // 4. Set the drawables for the page
    FPKDrawableOverlayView * view = (FPKDrawableOverlayView *)wrapper.view;
    view.uiCoordinatesDrwables.drawables = drawables.ui;
    view.pdfCoordinatesDrawables.drawables = drawables.pdf;
    
    // 5. Return the wrapper
    return @[wrapper];
}

-(void)removeAllObjects {
    [self.cache removeAllObjects];
}

-(instancetype)init {
    self = [super init];
    if(self) {
        self.cache = [NSCache new];
        self.cache.countLimit = 2;
        self.cachedObjects = [NSMutableArray new];
    }
    return self;
}

#pragma mark - NSCacheDelegate

-(void)cache:(NSCache *)cache willEvictObject:(id)obj {
    /* Nothing to do */
    [self.cachedObjects removeObject:obj];
}

#pragma mark - FPKOverlayViewDataSource_Private

-(void)overlayView:(MFOverlayView *)overlayView didAddOverlayView:(FPKOverlayViewHolder *)view {
    // Deliberately empty
}

-(void)overlayView:(MFOverlayView *)overlayView didRemoveOverlayView:(FPKOverlayViewHolder *)view {
    if([self.cachedObjects containsObject:view]) {
        view.view.layer.contents = nil; // Free up memory as soon as the view is removed
    }
}

-(void)overlayView:(MFOverlayView *)overlayView willRemoveOverlayView:(FPKOverlayViewHolder *)view {
    // Deliberately empty
}

-(void)overlayView:(MFOverlayView *)overlayView willAddOverlayView:(FPKOverlayViewHolder *)view {
    // Deliberately empty
}

@end
