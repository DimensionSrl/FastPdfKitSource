//
//  MFTiledView2.m
//  FastPDF
//
//  Created by Nicolò Tosi on 4/29/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "FPKTiledView.h"
#import "MFQuickTiledLayer.h"
#import "FPKDetailView.h"
#import "PrivateStuff.h"
#import "MFDocumentViewController.h"
#import "FPKSharedSettings_Private.h"
#import "MFOverlayDrawable.h"

@protocol FPKTiledViewDrawer <NSObject>

@end

@interface FPKTiledView()

@property (nonatomic,readwrite) CGSize baseTileSize;

@property (atomic,readwrite) NSUInteger counter;

@end

@implementation FPKTiledView
@synthesize invalid;
@synthesize baseTileSize;

-(void)setIsInFocus:(BOOL)inFocusOrNot {
    if(_isInFocus!=inFocusOrNot) {
        _isInFocus = inFocusOrNot;
        if(!_isInFocus) {
            [[self layer]setContents:nil];
        } else {
            self.counter++;
            [self setNeedsDisplay];
        }
    }
}

-(void)setMode:(MFDocumentMode)newMode
{
    if(newMode != _mode) {
        _mode = newMode;
        self.counter++;
        [self setNeedsDisplay];
    }
}

-(void)setLeftPageMetrics:(FPKPageData *)leftPageMetrics {
    if(![_leftPageMetrics isEqual:leftPageMetrics]) {
        _leftPageMetrics = leftPageMetrics;
        self.counter++;
        [self setNeedsDisplay];
    }
}

-(void)setRightPageMetrics:(FPKPageData *)rightPageMetrics {
    if(![_rightPageMetrics isEqual:rightPageMetrics]) {
        _rightPageMetrics = rightPageMetrics;
        self.counter++;
        [self setNeedsDisplay];
    }
}

-(void)didMoveToWindow
{
    self.contentScaleFactor = 1.0;
}

-(void)drawRect:(CGRect)rect
{
    /* Empty implementaton to allow -drawLayer:inContext: to be called */
}

-(void)drawLayer:(CALayer *)layer
       inContext:(CGContextRef)ctx
{
    // Temp variables.
    
    NSUInteger tick = self.counter;
    
    CGRect _leftRect, _rightRect;
    CGAffineTransform leftTransform, rightTransform;
    CGRect _leftCropbox, _rightCropbox;
    CGRect leftFrame, rightFrame;
    int _leftAngle, _rightAngle;
    
    CGRect clipbox = CGContextGetClipBoundingBox(ctx);
    
    CGContextClearRect(ctx, clipbox);
    
    if(!_settings.foregroundEnabled) {
        return;
    }
    
    NSInteger pageMode = self.mode;
    CGFloat padding = _settings.padding;
    CGSize contextSize = [self.layer bounds].size;
    float zoomLevel = [self.delegate zoomLevelForTiledView:self];
    
    MFDocumentManager * document = [self.dataSource documentForTiledView:self];
    
    if (pageMode == MFDocumentModeSingle || pageMode == MFDocumentModeOverflow) { // Single or overflow mode (same rendering, just different layer sizes).
        
        _leftAngle = self.leftPageMetrics.metrics.angle;
        _leftCropbox = self.leftPageMetrics.metrics.cropbox;
        
        CGRect _leftPageRect;
        CGAffineTransform _leftPageTransform;
        
        /* Si fa prima a ricalcolarlo ogni volta */
        transformAndBoxForPageRendering(&_leftPageTransform,
                                        &_leftPageRect,
                                        contextSize,
                                        _leftCropbox,
                                        _leftAngle,
                                        padding,
                                        YES);
        
        leftFrame = _leftPageRect;
        leftTransform = _leftPageTransform;
        
        if((self.counter == tick) && ((zoomLevel > 1.0)
           || (_settings.forceTiles == FPKForceTilesAlways)
           || ((_settings.forceTiles == FPKForceTilesOverflowOnly) && (pageMode == MFDocumentModeOverflow))
           || (_settings.legacyModeEnabled)))
        {
            CGContextSaveGState(ctx);
            
            CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(ctx, leftFrame);
            
            CGContextClipToRect(ctx, leftFrame);
            CGContextConcatCTM(ctx, leftTransform);
            
            [document drawPageNumber:self.leftPageMetrics.page onContext:ctx];
            
            CGContextRestoreGState(ctx);
        }
    }
    else if(pageMode == MFDocumentModeDouble)
    {
        // Double mode.
        _leftAngle = self.leftPageMetrics.metrics.angle;
        _leftCropbox = self.leftPageMetrics.metrics.cropbox;
        _rightAngle = self.rightPageMetrics.metrics.angle;
        _rightCropbox = self.rightPageMetrics.metrics.cropbox;
        
        transformAndBoxForPagesRendering(&leftTransform,
                                         &rightTransform,
                                         &_leftRect,
                                         &_rightRect,
                                         contextSize,
                                         _leftCropbox,
                                         _rightCropbox,
                                         _leftAngle,
                                         _rightAngle,
                                         padding,
                                         YES);
        
        leftFrame = _leftRect;
        leftTransform = leftTransform;
        
        rightFrame = _rightRect;
        rightTransform = rightTransform;
        
        // Left page first.
        
        if((self.counter == tick) && ((zoomLevel > 1.0)
           || (_settings.forceTiles == FPKForceTilesAlways)
           || (_settings.legacyModeEnabled)))
        {
            CGContextSaveGState(ctx);
            
            CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0); // White opaque page background.
            CGContextFillRect(ctx, leftFrame);
            CGContextClipToRect(ctx, leftFrame);
            CGContextConcatCTM(ctx, leftTransform);
            
            [document drawPageNumber:self.leftPageMetrics.page onContext:ctx];
            
            CGContextRestoreGState(ctx);
            
            // Then right page.
            
            CGContextSaveGState(ctx);
            
            CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(ctx, rightFrame);
            CGContextClipToRect(ctx, rightFrame);
            CGContextConcatCTM(ctx, rightTransform);
            
            [document drawPageNumber:self.rightPageMetrics.page onContext:ctx];
            
            CGContextRestoreGState(ctx);
        }
    }
}

+(Class)layerClass
{
    return [MFQuickTiledLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Get the underlying layer and set it up.
        CGSize size;
        CATiledLayer * layer = (CATiledLayer *)[self layer];
        
        //renderedTiles = [[NSMutableSet alloc]init];
        self.opaque = NO;
        
        CGFloat s = 1.0;
        if([UIScreen instancesRespondToSelector:@selector(scale)])
        {
            s = [[UIScreen mainScreen]scale];
        }
        
        if(fabs(s - 2.0) < FLT_EPSILON) // Retina
        {
            size = CGSizeApplyAffineTransform(frame.size, CGAffineTransformMakeScale(s, s));
            size = CGSizeMake(MAX(size.width,size.height),MIN(size.width,size.height));
            self.baseTileSize = size;
            [layer setTileSize:size]; // Capped at 1024 x 1024
            [layer setLevelsOfDetail:6]; // 0.5X, 1X, 2X, 4X, 8X, 16X
            [layer setLevelsOfDetailBias:4]; // 2X, 4X, 8X, 16X
        }
        else
        {
            size = CGSizeMake(MAX(frame.size.width,frame.size.height),MAX(frame.size.width,frame.size.height));
            self.baseTileSize = size;
            [layer setTileSize:size];
            [layer setLevelsOfDetail:6];
            [layer setLevelsOfDetailBias:4];
        }
    }
    
    return self;
}

- (void)dealloc {
    
#if FPK_DEALLOC
    
    NSLog(@"%@ - dealloc",NSStringFromClass([self class]));
#endif
    
    self.layer.delegate = nil;  // Nullifies the layer delegate.
    self.dataSource = nil;
    self.delegate = nil;
}

@end
