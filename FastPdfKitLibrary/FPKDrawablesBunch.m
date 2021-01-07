//
//  FPKDrawablesBunch.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/11/15.
//
//

#import "FPKDrawablesBunch.h"
#import "MFOverlayDrawable.h"

@implementation FPKDrawablesBunchDrawerBase

-(void)drawDrawables:(NSArray *)drawable context:(CGContextRef)ctx {
    
    for(id<MFOverlayDrawable> d in drawable) {
        CGContextSaveGState(ctx);
        [d drawInContext:ctx];
        CGContextRestoreGState(ctx);
    }
}

@end

@implementation FPKDrawablesBunchDrawerPDFCoordinates

-(void)drawDrawables:(NSArray *)drawable context:(CGContextRef)ctx {
    
    for(id<MFOverlayDrawable> d in drawable) {
        CGContextSaveGState(ctx);
        [d drawInContext:ctx];
        CGContextRestoreGState(ctx);
    }
}

@end

@implementation FPKDrawablesBunch

-(id<FPKDrawablesBunchDrawer>)drawer {
    if(!_drawer) {
        _drawer = [FPKDrawablesBunchDrawerBase new];
    }
    return _drawer;
}

-(void)drawInContext:(CGContextRef)ctx {
    
    CGContextSaveGState(ctx);
    
    [self.drawer drawDrawables:self.drawables context:ctx];
    
    CGContextRestoreGState(ctx);
}

@end
