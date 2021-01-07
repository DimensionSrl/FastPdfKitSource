//
//  FPKEmbeddedConfigProvider.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 12/02/15.
//
//

#import "FPKEmbeddedConfigProvider.h"
#import "FPKConfigAnnotation.h"
#import "FPKBaseDocumentViewController_private.h"

@interface FPKEmbeddedConfigProvider()

@property (nonatomic,copy) NSNumber * savedMaxZoomScale;
@property (nonatomic,copy) NSNumber * savedEdgeFlipWidth;
@property (nonatomic,weak) MFDocumentViewController * controller;
@end

@implementation FPKEmbeddedConfigProvider
@synthesize view = _view;

+(FPKEmbeddedConfigProvider *)providerForAnnotation:(FPKConfigAnnotation *)annotation
                                         delegate:(MFDocumentViewController *)controller
{
    FPKEmbeddedConfigProvider * provider = [FPKEmbeddedConfigProvider new];
    provider.maxZoomScale = annotation.maxZoomScale;
    provider.edgeFlipWidth = annotation.edgeFlipMargin;
    return provider;
}

-(void)didRemoveOverlayView:(UIView *)view pageView:(FPKPageView *)pageView  {
    if(self.savedMaxZoomScale) {
        pageView.scrollView.maximumZoomScale = self.savedMaxZoomScale.floatValue;
    }
    
    if(self.savedEdgeFlipWidth) {
        self.controller.edgeFlipWidth = self.savedEdgeFlipWidth.floatValue;
    }
}

-(void)willAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView {
    if(self.maxZoomScale) {
        pageView.scrollView.maximumZoomScale = self.maxZoomScale.floatValue;
    }
    if(self.edgeFlipWidth) {
        self.savedEdgeFlipWidth = @(self.controller.edgeFlipWidth);
        self.controller.edgeFlipWidth = self.edgeFlipWidth.floatValue;
    }
}

-(UIView *)view {
    if(!_view) {
        UIView * view = [[UIView alloc]initWithFrame:CGRectZero];
        self.view = view;
    }
    return _view;
}

@end
