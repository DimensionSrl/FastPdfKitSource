//
//  FPKInteractiveOverlayWrapper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import "FPKPrivateOverlayWrapper.h"

@implementation FPKPrivateOverlayWrapper

-(void)willAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView {
    // Deliberately empty
}

-(void)didAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView  {
    // Deliberately empty
}

-(void)willRemoveOverlayView:(UIView *)view pageView:(FPKPageView *)pageView  {
    // Deliberately empty
}

-(void)didRemoveOverlayView:(UIView *)view pageView:(FPKPageView *)pageView  {
    // Deliberately empty
}

#pragma mark - FPKOverlayViewDelegate_Private

-(void)overlayView:(MFOverlayView *)overlayView willAddOverlayView:(FPKOverlayViewHolder *)view {
    [self willAddOverlayView:view.view pageView:overlayView.pageView];
}

-(void)overlayView:(MFOverlayView *)overlayView didAddOverlayView:(FPKOverlayViewHolder *)view {
    [self didAddOverlayView:view.view pageView:overlayView.pageView];
}

-(void)overlayView:(MFOverlayView *)overlayView willRemoveOverlayView:(FPKOverlayViewHolder *)view {
    [self willRemoveOverlayView:view.view pageView:overlayView.pageView];
}

-(void)overlayView:(MFOverlayView *)overlayView didRemoveOverlayView:(FPKOverlayViewHolder *)view {
    [self didRemoveOverlayView:view.view pageView:overlayView.pageView];
}

#pragma mark - NSObject

-(instancetype)init {
    self = [super init];
    if(self) {
        self.delegate = self;
    }
    return self;
}

@end
