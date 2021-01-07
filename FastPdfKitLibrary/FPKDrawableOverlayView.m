//
//  FPKDrawableOverlayView.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/05/15.
//
//

#import "FPKDrawableOverlayView.h"
#import "MFOverlayDrawable.h"
#import "PrivateStuff.h"

@interface FPKDrawableOverlayView() <UIGestureRecognizerDelegate>

@property(readwrite, nonatomic) CGAffineTransform drawingTransform;
@property(readwrite, nonatomic) CGSize viewBoundsSize;
@property(readwrite, nonatomic) CGSize pageFrameSize;

@end

@implementation FPKDrawableOverlayView

-(FPKDrawablesBunch *)uiCoordinatesDrwables {
    if(!_uiCoordinatesDrwables) {
        _uiCoordinatesDrwables = [FPKDrawablesBunch new];
        _uiCoordinatesDrwables.drawer = [FPKDrawablesBunchDrawerBase new];
    }
    return _uiCoordinatesDrwables;
}

-(FPKDrawablesBunch *)pdfCoordinatesDrawables {
    if(!_pdfCoordinatesDrawables) {
        _pdfCoordinatesDrawables = [FPKDrawablesBunch new];
        _pdfCoordinatesDrawables.drawer = [FPKDrawablesBunchDrawerPDFCoordinates new];
    }
    return _pdfCoordinatesDrawables;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit {
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.25];
}

-(instancetype)init {
    self = [super init];
    if(self) {
        [self commonInit];
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    /* Left empty to allow drawLayer:inContext: to be called. */
}

+(NSDictionary *)attributes {
    static NSDictionary * attributes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attributes = @{
                       NSFontAttributeName:[UIFont systemFontOfSize:14.0]
                       };
    });
    return attributes;
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    
    /* Remember that origin is in the upper left.
     * Rotation is CW and when you flip the coordinates it change to CCW.
     */
    CGRect boundingBox = CGContextGetClipBoundingBox(ctx);
    
    if(CGRectIsEmpty(self.metrics.cropbox)) {
        return;
    }
    
    CGContextClearRect(ctx, boundingBox);
    
    CGAffineTransform transform;
    
    CGContextSaveGState(ctx);
    transformAndBoxForPageRendering(&transform, NULL,boundingBox.size,self.metrics. cropbox,self.metrics.angle,0,YES);
    CGContextConcatCTM(ctx, transform);
    [_pdfCoordinatesDrawables drawInContext:ctx];
    CGContextRestoreGState(ctx);
    
    CGContextSaveGState(ctx);
    transformAndBoxForPageRendering(&transform, NULL,boundingBox.size,self.metrics.cropbox, self.metrics.angle,0,NO);
    CGContextConcatCTM(ctx, transform);
    [_uiCoordinatesDrwables drawInContext:ctx];
    CGContextRestoreGState(ctx);
}

@end
