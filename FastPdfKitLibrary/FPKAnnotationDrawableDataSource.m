//
//  FPKAnnotationDrawable.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 06/10/15.
//
//

#import "FPKAnnotationDrawableDataSource.h"
#import "MFDocumentManager_private.h"
#import "MFLinkAnnotation.h"
@interface FPKAnnotationDrawable : NSObject <MFOverlayDrawable>

@property (nonatomic, readwrite) CGRect rect;
@property (nonatomic, copy) UIColor * color;

@end

@implementation FPKAnnotationDrawable

-(void)drawInContext:(CGContextRef)context {
    
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextFillRect(context, self.rect);
}

@end

@implementation FPKAnnotationDrawableDataSource

+(UIColor *)color {
    static UIColor * color;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.25];
    });
    return color;
}

-(NSArray *)documentViewController:(MFDocumentViewController *)dvc drawablesForPage:(NSUInteger)page pdfCoordinates:(BOOL *)flip {
    
    *flip = YES;
    
    NSArray * annotations = [self.documentManager linkAndURIAnnotationsForPageNumber:page];
    
    NSMutableArray * drawables = [NSMutableArray new];
    for(MFLinkAnnotation * annotation in annotations) {
        
        FPKAnnotationDrawable * drawable = [FPKAnnotationDrawable new];
        drawable.rect = annotation.rect;
        drawable.color = [FPKAnnotationDrawableDataSource color];
        [drawables addObject:drawable];
    }
    
    return drawables;
}

@end
