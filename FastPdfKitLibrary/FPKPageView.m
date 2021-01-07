//
//  FPKDetailView2.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import "FPKPageView.h"
#import "PrivateStuff.h"
#import "FPKTiledView.h"
#import "MFOverlayView.h"
#import "MFDocumentManager_private.h"
#import "MFLinkAnnotation.h"
#import "MFRemoteLinkAnnotation.h"
#import "MFURIAnnotation.h"

static const NSTimeInterval FPKPageFocusDelay = 0.25f;

@interface FPKPageView() <UIScrollViewDelegate, FPKTiledViewDelegate, FPKTiledViewDataSource>

@property (nonatomic, strong) FPKPageData * leftPageMetrics;
@property (nonatomic, strong) FPKPageData * rightPageMetrics;

@property (nonatomic, weak) NSOperation * leftOperation;
@property (nonatomic, weak) NSOperation * rightOperation;

#if DEBUG
@property (nonatomic, weak) UIView * testView;
#endif

@end

@implementation FPKPageView

-(void)reloadOverlays {    
    [self.overlayView reloadOverlays];
}

-(void)focusOut {
    
    [_scrollView setZoomScale:1.0 animated:NO]; // Reset the scrollview zoom (and offset?)
    
    _tiledView.isInFocus = NO;
    _overlayView.isInFocus = NO;
    
    [self setNeedsLayout];
}

-(void)focusIn {
    
    _scrollView.maximumZoomScale = [self.delegate maxZoomScaleForPageView:self];
    
//#if DEBUG
//    //TODO: restore zoom and content offset
//    [_scrollView setZoomScale:2.0 animated:NO];
//    [_scrollView setContentOffset:CGPointMake(500,700) animated:NO];
//#endif
    
    _tiledView.isInFocus = YES;
    _overlayView.isInFocus = YES;
    
    [self setNeedsLayout];
}

-(void)setChildViewControllersHelper:(FPKChildViewControllersHelper *)childViewControllersHelper {
    
    if(_childViewControllersHelper != childViewControllersHelper) {
    
        _childViewControllersHelper = childViewControllersHelper;
        self.overlayView.childViewControllersHelper = childViewControllersHelper;
    }
}

-(void)setThumbnailDataStore:(id<FPKThumbnailDataStore>)thumbnailStore {
    
    if(_thumbnailDataStore != thumbnailStore) {
        
        _thumbnailDataStore = thumbnailStore;
        self.backgroundView.thumbnailDataStore = thumbnailStore;
    }
}

-(void)setThumbnailCache:(FPKThumbnailCache *)thumbnailCache {
    
    if(_thumbnailCache != thumbnailCache) {
        
        _thumbnailCache = thumbnailCache;
        self.backgroundView.cache = _thumbnailCache;
    }
}

-(void)setInFocus:(BOOL)inFocusOrNot {
    if(_inFocus!=inFocusOrNot) {
        _inFocus = inFocusOrNot;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(focusIn) object:nil];
        if(_inFocus) {
            [self performSelector:@selector(focusIn) withObject:nil afterDelay:FPKPageFocusDelay];
        } else {
            [self focusOut];
        }
    }
}

/**
 * Changes page mode. If different from the one currently set, page mode change
 * will be forwarded to the backgroundView, tiledView and overlayView.
 * This will trigger -layoutSubviews.
 */
-(void)setPageMode:(MFDocumentMode)pageMode {
    if(_pageMode != pageMode) {
        _pageMode = pageMode;
        
        self.backgroundView.mode = _pageMode;
        self.tiledView.mode = _pageMode;
        self.overlayView.mode = _pageMode;
        
        [self setNeedsLayout];
    }
}

/**
 * Set right page metrics for this receiver. If the metrics changed sicne last
 * time, it will also update the metrics on the tiledView and the overlayView.
 */
-(void)setRightPageMetrics:(FPKPageData *)rightPageMetrics {
    if(_rightPageMetrics!=rightPageMetrics) {
        _rightPageMetrics = rightPageMetrics;
        self.tiledView.rightPageMetrics = _rightPageMetrics;
        self.overlayView.rightPageMetrics = _rightPageMetrics;
    }
}

/**
 * Set left page metrics for this receiver. If the metrics changed sicne last
 * time, it will also update the metrics on the tiledView and the overlayView.
 */
-(void)setLeftPageMetrics:(FPKPageData *)leftPageMetrics {
    if(_leftPageMetrics!=leftPageMetrics) {
        _leftPageMetrics = leftPageMetrics;
        self.tiledView.leftPageMetrics = _leftPageMetrics;
        self.overlayView.leftPageMetrics = _leftPageMetrics;
    }
}

-(void)setLeftPage:(NSUInteger)leftPage
{
    if(_leftPage!=leftPage) {
        
        _leftPage = leftPage;
        
        [self.leftOperation cancel];
        
        self.backgroundView.leftPage = _leftPage;
        
        if(self.leftPageMetrics.page != _leftPage) {
            
            self.leftPageMetrics = [self.metricsCache metricsWithPage:_leftPage];
            
            if(!self.leftPageMetrics) {
                
                self.leftPageMetrics = [FPKPageData zeroData];
                
                if(_leftPage > 0) {
                    self.leftOperation = [self enqueueMetricsOperationForPage:_leftPage];
                }
            }
        }
        [self setNeedsLayout];
    }
}

-(void)setRightPage:(NSUInteger)leftPage
{
    if(_rightPage!=leftPage) {
        
        _rightPage = leftPage;
        
        [self.rightOperation cancel];
        
        self.backgroundView.rightPage = _rightPage;
        
        if(self.rightPageMetrics.page != _rightPage) {
            
            self.rightPageMetrics = [self.metricsCache metricsWithPage:_rightPage];
            
            if(!self.rightPageMetrics) {
                
                self.rightPageMetrics = [FPKPageData zeroData];
                
                if(_rightPage > 0) {
                    self.rightOperation = [self enqueueMetricsOperationForPage:_rightPage];
                }
            }
        }
        
        [self setNeedsLayout];
    }
}

-(NSOperation *)enqueueMetricsOperationForPage:(NSUInteger)page {
    
    FPKMetricsOperation * operation = [FPKMetricsOperation operationWithPage:page
                                                                    document:self.document
                                                                    delegate:self];
    operation.metricsCache = self.metricsCache;
    [self.operationCenter.operationQueueB addOperation:operation];
    
    return operation;
}

#pragma mark - MFTiledViewDataSource, MFTiledViewDelegate

-(MFDocumentManager *)documentForTiledView:(FPKTiledView *)tiledView {
    return self.document;
}

-(CGFloat)zoomLevelForTiledView:(FPKTiledView *)tiledView {
    return self.scrollView.zoomScale;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    //TODO: save zoom rect
    CGPoint offset = self.scrollView.contentOffset;
    FPKPageZoom * zoom = [FPKPageZoom new];
    zoom.rect = CGRectMake(offset.x, offset.y, 0, 0);
    [self.pageZoomCache setPageZoom:zoom page:self.leftPage];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    //TODO: save zoom rect
    CGPoint offset = self.scrollView.contentOffset;
    FPKPageZoom * zoom = [FPKPageZoom new];
    zoom.rect = CGRectMake(offset.x, offset.y, 0, 0);
    [self.pageZoomCache setPageZoom:zoom page:self.leftPage];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    //TODO: save zoom when decelerate = false
    if(!decelerate) {
    CGPoint offset = self.scrollView.contentOffset;
    FPKPageZoom * zoom = [FPKPageZoom new];
    zoom.rect = CGRectMake(offset.x, offset.y, 0, 0);
    [self.pageZoomCache setPageZoom:zoom page:self.leftPage];
    }
}

#pragma mark - FPKOverlayViewDelegate

-(void)setPrivateOverlayViewHelper:(FPKPrivateOverlayViewHelper *)privateOverlayViewHelper {
    if(_privateOverlayViewHelper != privateOverlayViewHelper) {
        _privateOverlayViewHelper = privateOverlayViewHelper;
        self.overlayView.privateDataSource = _privateOverlayViewHelper;
    }
}

-(void)setOverlayViewHelper:(FPKOverlayViewHelper *)overlayViewHelper {
    if(_overlayViewHelper != overlayViewHelper) {
        _overlayViewHelper = overlayViewHelper;
        self.overlayView.delegate = _overlayViewHelper;
        self.overlayView.dataSource = _overlayViewHelper;
    }
}

-(void)setDrawablesHelper:(FPKDrawablesHelper *)drawablesHelper {
    if(_drawablesHelper !=drawablesHelper) {
        _drawablesHelper = drawablesHelper;
        self.overlayView.drawablesHelper = _drawablesHelper;
    }
}

#pragma mark - MFPageMetricsOperation

-(void)operation:(FPKMetricsOperation *)operation didCompleteWithMetrics:(FPKPageData *)metrics
{
    if(metrics.page == self.leftPage) {
        
        self.leftPageMetrics = metrics;
        [self setNeedsLayout];
        
    } else if (metrics.page == self.rightPage) {
        
        self.rightPageMetrics = metrics;
        [self setNeedsLayout];
    }
}

#pragma mark - FPKBackgroundViewDelegate

-(MFDocumentManager *)documentForBackgroundView:(FPKBackgroundView *)view
{
    return self.document;
}

-(FPKOperationsSharedData *)sharedDataForBackgroundView:(FPKBackgroundView *)view {
    return [self.delegate sharedDataForPageView:self];
}

-(NSString *)thumbnailsDirectoryForBackgroundView:(FPKBackgroundView *)view {
    return [self.delegate thumbnailsDirectoryForPageView:self];
}

-(NSString *)imagesDirectoryForBackgroundView:(FPKBackgroundView *)view {
    return [self.delegate imagesDirectoryForPageView:self];
}

#pragma mark - UIScrollViewDelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomView;
}

-(void)setOperationCenter:(FPKOperationCenter *)operationCenter {
    if(_operationCenter!=operationCenter) {
        _operationCenter = operationCenter;
        self.backgroundView.operationCenter = _operationCenter;
    }
}

#pragma mark - UIGestureRecognizer actions

-(BOOL)flip:(CGPoint)point {
    
    if(![self.delegate pageViewShouldEdgeFlip:self])
        return NO;
    
    CGFloat edgeFlipAreaWidth = [self.delegate edgeFlipWidthForPageView:self];
    
    CGFloat width = self.bounds.size.width;
    
    if(point.x < width * edgeFlipAreaWidth) {
    
        [self.delegate pageViewWantsToFlipLeft:self];
        
        return YES;
    }
    else if(point.x > width * (1 - edgeFlipAreaWidth)) {
        
        [self.delegate pageViewWantsToFlipRight:self];
        
        return YES;
    }
    
    return NO;
}

/*!
 Test the touch location agains the touchables.
 
 @param uiPoint Point in a origin on the bottom left coordinate space.
 @param pdfPoint Point in a origin on the upper left coordinate space.
 @param page The page.
 
 return BOOL true if the event has been consumed, otherwise false.
 
 */
-(BOOL)touchableHitTestUI:(CGPoint)uiPoint pdfPoint:(CGPoint)pdfPoint page:(NSUInteger)page {
    
    FlipContainer * container = [self.drawablesHelper touchablesForPage:page];
    
    NSArray * touchables = container.ui;
    for(id<MFOverlayTouchable> touchable in touchables) {
        if([touchable containsPoint:uiPoint]) {
            [self.delegate pageView:self didReceiveTapOnTouchable:touchable page:page];
            return YES;
        }
    }
    
    NSArray * flipped = container.pdf;
    for(id<MFOverlayTouchable> touchable in flipped) {
        if([touchable containsPoint:pdfPoint]) {
            [self.delegate pageView:self didReceiveTapOnTouchable:touchable page:page];
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Conversion

-(CGPoint)convertPoint:(CGPoint)point fromOverlayviewToPage:(NSUInteger)page {
    
    // Convert first the point in content view space, then in page space.
    
    CGPoint pointInContentView = point;
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
        return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
    }
    
    return CGPointZero;
}

-(CGPoint)convertPoint:(CGPoint)point toOverlayviewFromPage:(NSUInteger)page {
   
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
            
            return pointInContent;
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
            return pointInContent;
        }
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
        return pointInContent;
    }
    
    return CGPointZero;
}

-(CGRect)convertRect:(CGRect)rect fromOverlayviewToPage:(NSUInteger)page {
    // Convert first in contentvie coordinates, then on page coordinates.
    
    CGRect rectInContentView = rect;
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
        return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
    }
    
    return CGRectNull;
}

-(CGRect)convertRect:(CGRect)rect toOverlayviewFromPage:(NSUInteger)page {
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            return CGRectApplyAffineTransform(rect, transform);
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            return CGRectApplyAffineTransform(rect, transform);
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        return CGRectApplyAffineTransform(rect, transform);
    }
    
    return CGRectNull;
}

-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page
{
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGRect rectInContent = CGRectApplyAffineTransform(rect, transform);
            
            return [self convertRect:rectInContent fromView:self.zoomView];
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGRect rectInContent = CGRectApplyAffineTransform(rect, transform);
            
            return [self convertRect:rectInContent fromView:self.zoomView];
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        CGRect rectInContent  = CGRectApplyAffineTransform(rect, transform);
        
        return [self convertRect:rectInContent fromView:self.zoomView];
    }
    
    return CGRectNull;
}

-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page {
    
    // Convert first in contentvie coordinates, then on page coordinates.
    
    CGRect rectInContentView = [self.zoomView convertRect:rect fromView:self];
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
                        return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPageRendering(&transform,
                                            &frame,
                                            self.bounds.size,
                                            self.leftPageMetrics.metrics.cropbox,
                                            self.leftPageMetrics.metrics.angle,
                                            self.settings.padding,
                                            YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGRectApplyAffineTransform(rectInContentView, viewToPageTransform);
    }
    
    return CGRectNull;
}

-(NSUInteger)pageAtLocation:(CGPoint)location {
    
    CGPoint locationInContentView = [self.zoomView convertPoint:location fromView:self];
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            if(CGRectContainsPoint(frame, locationInContentView)) {
                return self.leftPageMetrics.page;
            }
        }
        
        if(self.rightPageMetrics) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            if(CGRectContainsPoint(frame, locationInContentView)) {
                return self.rightPageMetrics.page;
            }
        }
        
    } else if(self.leftPageMetrics) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        if(CGRectContainsPoint(frame, locationInContentView)) {
            return self.leftPageMetrics.page;
        }
    }
    
    return 0;
}

-(CGPoint)convertPoint:(CGPoint)point fromViewToPage:(NSUInteger)page {
    
    // Convert first the point in content view space, then in page space.
    
    CGPoint pointInContentView = [self.zoomView convertPoint:point fromView:self];
    
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                                                                              self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                                                                              self.settings.padding,
                                             YES);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
        }
        
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                                                                         self.settings.padding,
                                        YES);
        
        CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
        return CGPointApplyAffineTransform(pointInContentView, viewToPageTransform);
    }
    
    return CGPointZero;
}

-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page {
    if(self.pageMode == MFDocumentModeDouble) {
        
        if(self.leftPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(&transform,
                                             NULL,
                                             &frame,
                                             NULL,
                                             self.bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             YES);
            
            CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
            
            return [self convertPoint:pointInContent fromView:self.zoomView];
            
        } else if(self.rightPageMetrics.page == page) {
            
            CGAffineTransform transform;
            CGRect frame;
            
            transformAndBoxForPagesRendering(NULL,
                                             &transform,
                                             NULL,
                                             &frame,
                                             self.bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             YES);
            
            CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
            return [self convertPoint:pointInContent fromView:self.zoomView];
        }
    } else if(self.leftPageMetrics.page == page) {
        
        CGAffineTransform transform;
        CGRect frame;
        
        transformAndBoxForPageRendering(&transform,
                                        &frame,
                                        self.bounds.size,
                                        self.leftPageMetrics.metrics.cropbox,
                                        self.leftPageMetrics.metrics.angle,
                                        self.settings.padding,
                                        YES);
        
        CGPoint pointInContent = CGPointApplyAffineTransform(point, transform);
        return [self convertPoint:pointInContent fromView:self.zoomView];
    }
    
    return CGPointZero;
}

/**
 * @return true if some annotation has processed the touch
 */
-(BOOL)annotationHitTest:(CGPoint)point page:(NSUInteger)page {
    
    NSArray * linkAnnotations = [self.document linkAndURIAnnotationsForPageNumber:page];
    
    // URI annotation are handled only if no other annotation is found at the
    // same location.
    // We store the URI annotation and handle it outside the loop only if no
    // other annotation is found.
    MFURIAnnotation * deferredURIAnnotation = nil;
    
    for(MFAnnotation * annotation in linkAnnotations) {
        
        if(CGRectContainsPoint(annotation.rect, point)) {
            
            if([annotation isKindOfClass:[MFLinkAnnotation class]]) {
                
                MFLinkAnnotation * linkAnnotation = (MFLinkAnnotation *)annotation;
                
                [self.delegate pageView:self
                              wantsPage:linkAnnotation.destinationPage];
                
                return YES;
                
            } else if([annotation isKindOfClass:[MFURIAnnotation class]]) {
                
                MFURIAnnotation *uriAnnotation = (MFURIAnnotation *)annotation;
                
                deferredURIAnnotation = uriAnnotation;
                
             } else if ([annotation isKindOfClass:[MFRemoteLinkAnnotation class]]) {
                
                MFRemoteLinkAnnotation *remoteAnnotation = (MFRemoteLinkAnnotation *)annotation;
                
                if(remoteAnnotation.destination.length > 0) {
                    
                    [self.delegate pageView:self
                           wantsDestination:remoteAnnotation.description
                                       file:remoteAnnotation.document
                             annotationRect:remoteAnnotation.rect];
                    
                    return YES;
                    
                } else if (remoteAnnotation.page > 0) {
                    
                    [self.delegate pageView:self
                                  wantsPage:remoteAnnotation.page
                                       file:remoteAnnotation.document
                             annotationRect:remoteAnnotation.rect];
                    
                    return YES;
                }
            }
        }
    }
    
    if(deferredURIAnnotation) {
        
        return [self.delegate pageView:self didReceiveTapOnAnnotationRect:deferredURIAnnotation.rect uri:deferredURIAnnotation.uri page:page];
    }
    
    return NO;
}

-(void)actionTap:(UITapGestureRecognizer *)recognizer {
    
#if DEBUG
    NSLog(@"Zoomview %@ %@", NSStringFromCGRect(_zoomView.bounds), NSStringFromCGPoint(_zoomView.center));
#endif
    
    CGPoint point = [recognizer locationInView:self];
    if([self flip:point]) {
        return;
    }
    
    [self.delegate pageView:self didReceiveTapAtPoint:point]; // Always called, even with interaction disabled
    
    if([self.delegate documentInteractionEnabledForPageView:self]) {
        
        CGPoint touchLocation = [recognizer locationInView:self.overlayView]; // Punto nella "content" view
        
        if(self.pageMode == MFDocumentModeDouble) {
            
            BOOL leftEvent = NO;
            
            if(self.leftPageMetrics) {
                
                NSUInteger page = self.leftPageMetrics.page;
                CGAffineTransform pdfToViewTransform; // Trasformazione da pdf a view
                CGRect pageFrameInView; // Frame della pagina nella view
                
                transformAndBoxForPagesRendering(&pdfToViewTransform,
                                                 NULL,
                                                 &pageFrameInView,
                                                 NULL,
                                                 self.bounds.size,
                                                 self.leftPageMetrics.metrics.cropbox,
                                                 CGRectZero,
                                                 self.leftPageMetrics.metrics.angle,
                                                 0,
                                                 self.settings.padding,
                                                 YES);
                
                CGAffineTransform viewToPdfTransform = CGAffineTransformInvert(pdfToViewTransform);
                
                // If the touch is outside of the page, we can safely ignore it
                if(CGRectContainsPoint(pageFrameInView, touchLocation)) {
                    
                    leftEvent = YES;
                    
                    // Convert content point to page point
                    CGPoint pdfPoint = CGPointApplyAffineTransform(touchLocation, viewToPdfTransform);
                    CGPoint uiPoint = CGPointMake(pdfPoint.x, self.leftPageMetrics.metrics.cropbox.size.height - pdfPoint.y);
                    
                    if([self touchableHitTestUI:uiPoint pdfPoint:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self annotationHitTest:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self.delegate pageView:self didReceiveTapAtPoint:pdfPoint page:page]) {
                        return;
                    }
                }
            }
            
            if(!leftEvent && self.rightPageMetrics) {
                
                NSUInteger page = self.rightPageMetrics.page;
                CGAffineTransform pdfToViewtransform;
                CGRect pdfFrameInView;
                
                transformAndBoxForPagesRendering(NULL,
                                                 &pdfToViewtransform,
                                                 NULL,
                                                 &pdfFrameInView,
                                                 self.bounds.size,
                                                 CGRectZero,
                                                 self.rightPageMetrics.metrics.cropbox,
                                                 0,
                                                 self.rightPageMetrics.metrics.angle,
                                                 self.settings.padding,
                                                 YES);
                
                CGAffineTransform viewToPdfTransform = CGAffineTransformInvert(pdfToViewtransform);
                
                if(CGRectContainsPoint(pdfFrameInView, touchLocation)) {
                    
                    // Convert point to page point
                    CGPoint pdfPoint = CGPointApplyAffineTransform(touchLocation, viewToPdfTransform);
                    CGPoint uiPoint = CGPointMake(pdfPoint.x, self.leftPageMetrics.metrics.cropbox.size.height - pdfPoint.y);
                    
                    if([self touchableHitTestUI:uiPoint pdfPoint:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self annotationHitTest:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self.delegate pageView:self didReceiveTapAtPoint:pdfPoint page:page]) {
                        return;
                    }
                }
            }
            
        } else if (self.pageMode == MFDocumentModeSingle||self.pageMode == MFDocumentModeOverflow) {
            
            if(self.leftPageMetrics) {
                
                NSUInteger page = self.leftPageMetrics.page;
                CGAffineTransform pdfToViewTransform;
                CGRect pdfFrameInView;
                
                transformAndBoxForPageRendering(&pdfToViewTransform,
                                                &pdfFrameInView,
                                                self.bounds.size,
                                                self.leftPageMetrics.metrics.cropbox,
                                                self.leftPageMetrics.metrics.angle,
                                                self.settings.padding,
                                                YES);
                
                CGAffineTransform viewToPdfTransform = CGAffineTransformInvert(pdfToViewTransform);
                
                if(CGRectContainsPoint(pdfFrameInView, touchLocation)) {
                    
                    CGPoint pdfPoint = CGPointApplyAffineTransform(touchLocation, viewToPdfTransform);
                    CGPoint uiPoint = CGPointMake(pdfPoint.x, self.leftPageMetrics.metrics.cropbox.size.height - pdfPoint.y);
                    
                    if([self touchableHitTestUI:uiPoint pdfPoint:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self annotationHitTest:pdfPoint page:page]) {
                        return;
                    }
                    
                    if([self.delegate pageView:self didReceiveTapAtPoint:pdfPoint page:page]) {
                        return;
                    }
                }
            }
        }
    }
}

-(void)actionDoubleTap:(UITapGestureRecognizer *)recognizer {
    
    if([self.delegate pageViewShouldZoomOnDoubleTap:self]) {
        
        if(self.scrollView.zoomScale > 1.0) {
            
            [self.scrollView setZoomScale:1.0 animated:YES];
            
        } else {
            
            CGPoint touchPoint = [recognizer locationInView:self.zoomView];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                
                CGRect fitZoomRect = CGRectMake(touchPoint.x - self.scrollView.contentSize.width/5, touchPoint.y - self.scrollView.contentSize.height/5, self.scrollView.contentSize.width/2.5, self.scrollView.contentSize.height/2.5);
                
                [self.scrollView zoomToRect:fitZoomRect animated:YES];
                
            } else {
                
                CGRect fitZoomRect = CGRectMake(touchPoint.x - self.scrollView.contentSize.width/8, touchPoint.y - self.scrollView.contentSize.height/8, self.scrollView.contentSize.width/4, self.scrollView.contentSize.height/4);
                
                [self.scrollView zoomToRect:fitZoomRect animated:YES];
            }
        }
    }
}

#pragma mark - UIView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        
        CGRect subviewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        UITapGestureRecognizer * doubleTapGestureRecognizer = [UITapGestureRecognizer new];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [doubleTapGestureRecognizer addTarget:self action:@selector(actionDoubleTap:)];
        [self addGestureRecognizer:doubleTapGestureRecognizer];
        
        UITapGestureRecognizer * tapGestureRecognizer = [UITapGestureRecognizer new];
        [tapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        [tapGestureRecognizer addTarget:self action:@selector(actionTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        // Zoom view (wrapper of background, tiled and overlay)
        UIView * zoomView = [[UIView alloc]initWithFrame:subviewFrame];
        zoomView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        zoomView.autoresizesSubviews = YES;
        zoomView.translatesAutoresizingMaskIntoConstraints = NO;
        self.zoomView = zoomView;
        
        // Scrollview
        UIScrollView * scrollView = [[UIScrollView alloc]initWithFrame:subviewFrame];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        scrollView.autoresizesSubviews = YES;
        scrollView.translatesAutoresizingMaskIntoConstraints = YES;
        [scrollView addSubview:zoomView];
        scrollView.delegate = self;
        scrollView.contentSize = subviewFrame.size;
        scrollView.maximumZoomScale = 8.0;
        self.scrollView = scrollView;
        
        // Background
        FPKBackgroundView * backgroundView = [[FPKBackgroundView alloc]initWithFrame:subviewFrame];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        backgroundView.translatesAutoresizingMaskIntoConstraints = YES;
        backgroundView.delegate = self;
        backgroundView.settings = self.settings;
        backgroundView.cache = self.thumbnailCache;
        backgroundView.thumbnailDataStore = self.thumbnailDataStore;
        backgroundView.operationCenter = self.operationCenter;
        [zoomView addSubview:backgroundView];
        self.backgroundView = backgroundView;
        
        // TiledView
        FPKTiledView * tiledView = [[FPKTiledView alloc]initWithFrame:subviewFrame];
        tiledView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        tiledView.translatesAutoresizingMaskIntoConstraints = YES;
        tiledView.settings = self.settings;
        [zoomView addSubview:tiledView];
        tiledView.delegate = self;
        tiledView.dataSource = self;
        self.tiledView = tiledView;
        
        // Overlay view
        MFOverlayView * overlayView = [[MFOverlayView alloc]initWithFrame:subviewFrame];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        overlayView.translatesAutoresizingMaskIntoConstraints = YES;
        self.overlayView = overlayView;
        overlayView.dataSource = self.overlayViewHelper;
        overlayView.delegate = self.overlayViewHelper;
        overlayView.privateDataSource = self.privateOverlayViewHelper;
        overlayView.drawablesHelper = self.drawablesHelper;
        overlayView.childViewControllersHelper = self.childViewControllersHelper;
        overlayView.settings = self.settings;
        
        [zoomView addSubview:overlayView];
        
        [self addSubview:scrollView];
    }
    return self;
}

-(void)setSettings:(FPKSharedSettings *)settings {
    _settings = settings;
    _overlayView.settings = settings;
    _tiledView.settings = settings;
    _backgroundView.settings = settings;
}

-(void)layoutSubviews {

#if DEBUG
    // NSLog(@"layoutSubviews %@",self);
#endif
    
    [super layoutSubviews]; // Does nothing
    
    CGRect bounds = self.bounds;
    
    self.scrollView.frame = bounds;
    self.zoomView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    if(self.pageMode == MFDocumentModeSingle) {
        
        if(self.leftPageMetrics) {
            
            self.scrollView.contentSize = bounds.size;
            
        } else {
            
            self.scrollView.contentSize = CGSizeZero;
        }
        
    } else if (self.pageMode == MFDocumentModeOverflow) {
        
        if(self.leftPageMetrics) {
            
            CGRect frame = frameForLayer(bounds.size, self.leftPageMetrics.metrics.cropbox, self.leftPageMetrics.metrics.angle, 0);
            self.scrollView.contentSize = frame.size;
            self.zoomView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
            
        } else {
            
            self.scrollView.contentSize = CGSizeZero;
        }
        
    } else if (self.pageMode == MFDocumentModeDouble) {
        
        if(nil!=self.leftPageMetrics && nil!=self.rightPageMetrics) {
            
            self.scrollView.contentSize = bounds.size;
            
        } else {
            
            self.scrollView.contentSize = CGSizeZero;
        }
    }
}

-(NSString *)description {
   return [NSString stringWithFormat:@"FPKPageView<%p>{leftPage:%lu,\n"
          "rightPage:%lu\n,"
          "mode:%lu\n,"
          "leftPageMetrics:%@\n,"
          "rightPageMetrics:%@\n,"
           "focused:%@\n}",
           self,
          (unsigned long)_leftPage,
          (unsigned long)_rightPage,
          (unsigned long)_pageMode,
          _leftPageMetrics,
          _rightPageMetrics,
           (_inFocus ? @"true" : @"false")
          ];
}

@end
