//
//  MFOverlayView.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 3/23/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFOverlayView.h"
#import "MFOverlayDrawable.h"
#import "MFTiledViewData.h"
#import "Stuff.h"
#import "FPKOverlayViewHolder.h"
#import "FPKPrivateOverlayWrapper.h"
#import "PrivateStuff.h"
#import "MFOverlayDrawable.h"
#import "MFOverlayTouchable.h"
#import "FPKChildViewControllersWrapper.h"
#import "FPKDrawablesHelper.h"

/**
 * YES if overlays'rect is in PDF coordinates (origin bottom left).
 * NO for rects in UI coordinate (origin top right).
 */
static const BOOL FPKFlipCoordinatesForOverlayViews = YES;

@interface MFOverlayView()

@property (nonatomic, strong) NSArray * leftOverlays;
@property (nonatomic, strong) NSArray * rightOverlays;

@property (nonatomic, strong) NSArray * leftChildViewControllers;
@property (nonatomic, strong) NSArray * rightChildViewControllers;

@property (nonatomic, strong) NSArray * leftPrivateOverlays;
@property (nonatomic, strong) NSArray * rightPrivateOverlays;

/** 
 * Left page drawables.
 */
@property (nonatomic,strong) NSArray * leftDrawables;

/**
 * Right page drawables.
 */
@property (nonatomic,strong) NSArray * rightDrawables;

@end

@implementation MFOverlayView

@synthesize delegate;

-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page
{
    if(self.mode == MFDocumentModeDouble) {
        
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
                                             FPKFlipCoordinatesForOverlayViews);
            
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
                                             FPKFlipCoordinatesForOverlayViews);
            
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
                                        FPKFlipCoordinatesForOverlayViews);
        
        return CGRectApplyAffineTransform(rect, transform);
    }
    
    return CGRectNull;
}


-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page {
    
    if(self.mode == MFDocumentModeDouble) {
        
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGRectApplyAffineTransform(rect, viewToPageTransform);
            
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGRectApplyAffineTransform(rect, viewToPageTransform);
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
                                        FPKFlipCoordinatesForOverlayViews);
        
        CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
        return CGRectApplyAffineTransform(rect, viewToPageTransform);
    }
    
    return CGRectNull;
}

-(CGPoint)convertPoint:(CGPoint)point fromViewToPage:(NSUInteger)page {
    if(self.mode == MFDocumentModeDouble) {
        
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            
            return CGPointApplyAffineTransform(point, viewToPageTransform);
            
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
            return CGPointApplyAffineTransform(point, viewToPageTransform);
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
                                        FPKFlipCoordinatesForOverlayViews);
        
        CGAffineTransform viewToPageTransform = CGAffineTransformInvert(transform);
        return CGPointApplyAffineTransform(point, viewToPageTransform);
    }
    
    return CGPointZero;
}

-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page {
    
    if(self.mode == MFDocumentModeDouble) {
        
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            return CGPointApplyAffineTransform(point, transform);
            
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
                                             FPKFlipCoordinatesForOverlayViews);
            
            return CGPointApplyAffineTransform(point, transform);
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
                                        FPKFlipCoordinatesForOverlayViews);
        
        return CGPointApplyAffineTransform(point, transform);
    }
    
    return CGPointZero;
}

#pragma mark -

-(void)setNeedsOverlay {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(needsOverlay)
                                               object:nil];
    
    [self performSelector:@selector(needsOverlay)
               withObject:nil
               afterDelay:0];
}

-(void)setIsInFocus:(BOOL)inFocusOrNot {
    if(_isInFocus!=inFocusOrNot) {
        _isInFocus = inFocusOrNot;
        [self needsOverlay];
        [self needsDrawables];
    }
}

-(void)reloadOverlays {
    
    [self needsDrawables];
    [self needsOverlay];
}

-(void)needsDrawables {
    
#if DEBUG
    NSLog(@"needsDrawables (%d, %lu)", self.isInFocus, (unsigned long)self.leftPageMetrics.page);
#endif

    if(self.isInFocus && self.leftPageMetrics && ![self.leftPageMetrics isEqual:[FPKPageMetrics zeroMetrics]]) {
        
        NSArray * overlays = [self.drawablesHelper overlayView:self overlayViewsForPage:self.leftPageMetrics.page];
        
        self.leftDrawables = overlays;
        
    } else {
        
        self.leftDrawables = nil;
    }
    
    if(self.isInFocus && self.rightPageMetrics && ![self.rightPageMetrics isEqual:[FPKPageMetrics zeroMetrics]]) {
        
        NSArray * overlays = [self.drawablesHelper overlayView:self overlayViewsForPage:self.rightPageMetrics.page];
        
        self.rightDrawables = overlays;
        
    } else {
        
        self.rightDrawables = nil;
    }
    
    [super setNeedsLayout];
}

-(void)setNeedsLayout {
    
    [super setNeedsLayout];
}

/**
 Collect the overlay views from multiple sources and invoke setNeddsLayout.
 */
-(void)needsOverlay {
    
    if(self.isInFocus && self.leftPageMetrics && ![self.leftPageMetrics isEqual:[FPKPageMetrics zeroMetrics]]) {
        
        NSArray * overlays = [[self.dataSource overlayView:self
                                       overlayViewsForPage:self.leftPageMetrics.page] copy];
        self.leftOverlays = overlays;
        
        NSArray * privateOverlays = [[self.privateDataSource overlayView:self overlayViewsForPage:self.leftPageMetrics.page]copy];
        self.leftPrivateOverlays = privateOverlays;
        self.leftChildViewControllers = [[self.childViewControllersHelper childViewControllersForPage:self.leftPageMetrics.page]copy];
        
    } else {
    
        self.leftOverlays = nil;
        self.leftPrivateOverlays = nil;
        self.leftChildViewControllers = nil;
    }
    
    if(self.isInFocus && self.rightPageMetrics && ![self.rightPageMetrics isEqual:[FPKPageMetrics zeroMetrics]]) {
        
        NSArray * overlays = [[self.dataSource overlayView:self
                                       overlayViewsForPage:self.rightPageMetrics.page] copy];
        self.rightOverlays = overlays;
        
        NSArray * privateOverlays = [[self.privateDataSource overlayView:self
                                                     overlayViewsForPage:self.rightPageMetrics.page]copy];
        self.rightPrivateOverlays = privateOverlays;
        self.rightChildViewControllers = [[self.childViewControllersHelper childViewControllersForPage:self.rightPageMetrics.page]copy];
    
    } else {
        
        self.rightOverlays = nil;
        self.rightPrivateOverlays = nil;
        self.rightChildViewControllers = nil;
    }
    
    [self setNeedsLayout];
}

-(void)setRightChildViewControllers:(NSArray *)rightChildViewControllers {
    
    if(_rightChildViewControllers!=rightChildViewControllers) {
    
        [self removeChildViewControllers:_rightChildViewControllers];
        _rightChildViewControllers = rightChildViewControllers;
        [self addChildViewControllers:_rightChildViewControllers];
    }
}

-(void)addChildViewControllers:(NSArray *)controllers {
    
    for(FPKChildViewControllersWrapper * wrapper in controllers) {
        
        [self.childViewControllersHelper.documentViewController addChildViewController:wrapper.controller];
        [wrapper willAddOverlayView:wrapper.controller.view pageView:self.pageView];
        [self addSubview:wrapper.controller.view];
        [wrapper didAddOverlayView:wrapper.controller.view pageView:self.pageView];
        [wrapper.controller didMoveToParentViewController:self.childViewControllersHelper.documentViewController];
    }
}

-(void)removeChildViewControllers:(NSArray *)controllers {
    
    for(FPKChildViewControllersWrapper * wrapper in controllers) {
        
        [wrapper.controller willMoveToParentViewController:nil];
        [wrapper willRemoveOverlayView:wrapper.controller.view pageView:self.pageView];
        [wrapper.controller.view removeFromSuperview];
        [wrapper didRemoveOverlayView:wrapper.controller.view pageView:self.pageView];
        [wrapper.controller removeFromParentViewController];
    }
}

-(void)setLeftChildViewControllers:(NSArray *)leftChildViewControllers {
    
    if(_leftChildViewControllers!=leftChildViewControllers) {
        
        [self removeChildViewControllers:_leftChildViewControllers];
        _leftChildViewControllers = leftChildViewControllers;
        [self addChildViewControllers:_leftChildViewControllers];
    }
}

-(void)setLeftPrivateOverlays:(NSArray *)leftPrivateOverlays {
    
    if(![_leftPrivateOverlays isEqual:leftPrivateOverlays]) {
        
        [self removeOverlayViews:_leftPrivateOverlays];
        _leftPrivateOverlays = leftPrivateOverlays;
        [self addOverlayViews:_leftPrivateOverlays];
    }
}

-(void)setRightPrivateOverlays:(NSArray *)rightPrivateOverlays {
    
    if(![_rightPrivateOverlays isEqual:rightPrivateOverlays]) {
        
        [self removeOverlayViews:_rightPrivateOverlays];
        _rightPrivateOverlays = rightPrivateOverlays;
        [self addOverlayViews:_rightPrivateOverlays];
    }
}

-(void)setLeftDrawables:(NSArray *)leftDrawables {
    
    if(_leftDrawables!=leftDrawables) {
        [self removeOverlayViews:_leftDrawables];
        _leftDrawables = leftDrawables;
        [self addOverlayViews:_leftDrawables];
    }
}

-(void)setRightDrawables:(NSArray *)rightDrawables {
    
    if(_rightDrawables!=rightDrawables) {
        [self removeOverlayViews:_rightDrawables];
        _rightDrawables = rightDrawables;
        [self addOverlayViews:_rightDrawables];    }
}

-(void)setLeftOverlays:(NSArray *)leftOverlays {
    
    if(![_leftOverlays isEqual:leftOverlays]) {
        
        [self removeOverlayViews:_leftOverlays];
        _leftOverlays = leftOverlays;
        [self addOverlayViews:_leftOverlays];
    }
}

-(void)setRightOverlays:(NSArray *)rightOverlays {
    
    if(![_rightOverlays isEqual:rightOverlays]) {
        
        [self removeOverlayViews:_rightOverlays];
        _rightOverlays = rightOverlays;
        [self addOverlayViews:_rightOverlays];
    }
}

-(void)setLeftPageMetrics:(FPKPageData*)leftPageMetrics {
    if(![_leftPageMetrics isEqual:leftPageMetrics]) {
        _leftPageMetrics = leftPageMetrics;
        [self needsOverlay];
        [self needsDrawables];
    }
}

-(void)setRightPageMetrics:(FPKPageData *)rightPageMetrics {
    if(![_rightPageMetrics isEqual:rightPageMetrics]) {
        _rightPageMetrics = rightPageMetrics;
        [self needsOverlay];
        [self needsDrawables];
    }
}

-(void)removeOverlayViews:(NSArray *)views {
    
    for(FPKOverlayViewHolder * wrapper in views) {

        [wrapper.owner overlayView:self willRemoveOverlayView:wrapper];
        [wrapper.view removeFromSuperview];
        [wrapper.owner overlayView:self didRemoveOverlayView:wrapper];
    }
}

-(void)addAndSendToBackOverlayViews:(NSArray *)views {
    
    for(FPKOverlayViewHolder * wrapper in views) {
        
        [wrapper.owner overlayView:self willAddOverlayView:wrapper];
        [self addSubview:wrapper.view];
        [self sendSubviewToBack:wrapper.view];
        [wrapper.owner overlayView:self didAddOverlayView:wrapper];
    }
}

-(void)addOverlayViews:(NSArray *)views {
    
    for(FPKOverlayViewHolder * wrapper in views) {
        
        [wrapper.owner overlayView:self willAddOverlayView:wrapper];
        [self addSubview:wrapper.view];
        [wrapper.owner overlayView:self didAddOverlayView:wrapper];
    }
}

-(void)setMode:(MFDocumentMode)mode {
    if(_mode!=mode) {
        _mode = mode;
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

#pragma mark - UIView

-(void)layoutSubviews {
    
#if DEBUG
    // NSLog(@"%@",self);
#endif
    
    [super layoutSubviews];
    
    if(self.mode == MFDocumentModeDouble) {
        
        // Double mode
        
        if(self.leftPageMetrics && (![self.leftPageMetrics isEmpty])) {
            
            const CGFloat pageHeight = self.leftPageMetrics.metrics.cropbox.size.height;
            CGRect bounds = self.bounds;
            CGRect pdfFrame = CGRectZero;
            CGAffineTransform pdfTransform = CGAffineTransformIdentity;
            transformAndBoxForPagesRendering(&pdfTransform,
                                             NULL,
                                             &pdfFrame,
                                             NULL,
                                             bounds.size,
                                             self.leftPageMetrics.metrics.cropbox,
                                             CGRectZero,
                                             self.leftPageMetrics.metrics.angle,
                                             0,
                                             self.settings.padding,
                                             FPKFlipCoordinatesForOverlayViews);
            
            for(FPKOverlayViewHolder * overlay in self.leftOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.pdfCoordinates ? overlay.rect : FPKReversedAnnotationRect(overlay.rect, pageHeight), pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.leftPrivateOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.leftChildViewControllers) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.leftDrawables) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
        }
        
        if(self.rightPageMetrics && (![self.rightPageMetrics isEmpty])) {
            
            CGRect bounds = self.bounds;
            const CGFloat pageHeight = self.rightPageMetrics.metrics.cropbox.size.height;
            
            CGRect pdfFrame = CGRectZero;
            CGAffineTransform pdfTransform = CGAffineTransformIdentity;
            transformAndBoxForPagesRendering(NULL,
                                             &pdfTransform,
                                             NULL,
                                             &pdfFrame,
                                             bounds.size,
                                             CGRectZero,
                                             self.rightPageMetrics.metrics.cropbox,
                                             0,
                                             self.rightPageMetrics.metrics.angle,
                                             self.settings.padding,
                                             FPKFlipCoordinatesForOverlayViews);
            
            for(FPKOverlayViewHolder * overlay in self.rightOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.pdfCoordinates ? overlay.rect : FPKReversedAnnotationRect(overlay.rect, pageHeight), pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.rightPrivateOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.rightChildViewControllers) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.rightDrawables) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
        }
        
    } else if (self.mode == MFDocumentModeSingle || self.mode==MFDocumentModeOverflow) {
        
        // Single or overflow mode
        
        if(self.leftPageMetrics||(![self.leftPageMetrics isEmpty])) {
            
            CGRect bounds = self.bounds; // Occasionalmente è zero. Perchè.
            const CGFloat pageHeight = self.leftPageMetrics.metrics.cropbox.size.height;
            CGRect pdfFrame = CGRectZero;
            CGAffineTransform pdfTransform = CGAffineTransformIdentity;
            transformAndBoxForPageRendering(&pdfTransform,
                                            &pdfFrame,
                                            bounds.size,
                                            self.leftPageMetrics.metrics.cropbox,
                                            self.leftPageMetrics.metrics.angle,
                                            self.settings.padding,
                                            FPKFlipCoordinatesForOverlayViews);
            
#if DEBUG
            NSLog(@"Overlays %@", self.leftOverlays);
#endif
            
            for(FPKOverlayViewHolder * overlay in self.leftOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.pdfCoordinates ? overlay.rect : FPKReversedAnnotationRect(overlay.rect, pageHeight), pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.leftPrivateOverlays) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
            for(FPKOverlayViewHolder * overlay in self.leftChildViewControllers) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
            
#if DEBUG
            NSLog(@"Drawables %@", self.leftDrawables);
#endif
            for(FPKOverlayViewHolder * overlay in self.leftDrawables) {
                CGRect transformedFrame = CGRectIntegral(CGRectApplyAffineTransform(overlay.rect, pdfTransform));
                overlay.view.frame = transformedFrame;
            }
        }
    }
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.opaque = NO;
    }
    return self;
}

-(NSString *)description {

        return [NSString stringWithFormat:@"MFOverlayView<%p>{"
                "mode:%lu\n,"
                "leftPageMetrics:%@\n,"
                "rightPageMetrics:%@\n,"

                "leftOverlays.count:%lu\n"
                "rightOverlays.count:%lu\n"
                                "leftPrivateOverlays.count:%lu\n"
                                "rightPrivateOverlays.count:%lu\n"
                                "focused:%@\n",
                self,
                (unsigned long)_mode,
                _leftPageMetrics,
                _rightPageMetrics,
                (unsigned long)_leftOverlays.count,
                (unsigned long)_rightOverlays.count,
                (unsigned long)_leftPrivateOverlays.count,
                (unsigned long)_rightPrivateOverlays.count,
                (_isInFocus ? @"true" : @"false")
                ];
}

- (void)dealloc
{
#if FPK_DEALLOC
    NSLog(@"%@ - dealloc:",NSStringFromClass([self class]));
#endif
    
    delegate = nil;
    self.pageView = nil;
}

@end
