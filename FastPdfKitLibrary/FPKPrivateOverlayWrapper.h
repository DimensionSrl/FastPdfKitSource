//
//  FPKInteractiveOverlayWrapper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import "FPKOverlayViewHolder.h"
#import "MFOverlayView.h"
#import "FPKPageView.h"

@interface FPKPrivateOverlayWrapper : FPKOverlayViewHolder <FPKOverlayViewDelegate_Private>

-(void)willAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView;
-(void)didAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView;
-(void)willRemoveOverlayView:(UIView *)view pageView:(FPKPageView *)pageView;
-(void)didRemoveOverlayView:(UIView *)view pageView:(FPKPageView *)pageView;

//TODO: not used at the moment. The idea is to have interactive overlay define
// their own delegate, usually it being themselves.
@property (nonatomic,weak) id<FPKOverlayViewDelegate_Private>delegate;

@end
