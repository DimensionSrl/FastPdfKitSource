//
//  MFOverlayView.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 3/23/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFTiledViewData.h"
#import "FPKPageRenderingData.h"
#import "Stuff.h"
#import "FPKChildViewControllersHelper.h"
#import "FPKSharedSettings_Private.h"

@class FPKPageView;
@class FPKDrawablesHelper;
@class FPKOverlayViewHolder;
@protocol FPKOverlayViewDataSource_Private;
@protocol FPKOverlayViewDelegate_Private;

@interface MFOverlayView : UIView

@property (nonatomic,weak) id<FPKOverlayViewDelegate_Private>delegate;
@property (nonatomic,weak) id<FPKOverlayViewDataSource_Private>dataSource;

@property (nonatomic,weak) id<FPKOverlayViewDataSource_Private>privateDataSource;

@property (nonatomic, weak) FPKPageView * pageView;

@property (nonatomic,strong) FPKPageData * leftPageMetrics;
@property (nonatomic,strong) FPKPageData * rightPageMetrics;
@property (nonatomic,readwrite) MFDocumentAutoMode mode;
@property (nonatomic,readwrite) BOOL isInFocus;
@property (nonatomic,strong) FPKDrawablesHelper * drawablesHelper;
@property (nonatomic,strong) FPKChildViewControllersHelper * childViewControllersHelper;
@property (nonatomic,weak) FPKSharedSettings * settings;

-(void)reloadOverlays;

@end

@protocol FPKOverlayViewDataSource_Private

/**
 * Returns an NSArray of FPKOverlayViewWrapper objects
 */
-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page;

@end

@protocol FPKOverlayViewDelegate_Private

-(void)overlayView:(MFOverlayView *)overlayView didAddOverlayView:(FPKOverlayViewHolder *)view;
-(void)overlayView:(MFOverlayView *)overlayView willAddOverlayView:(FPKOverlayViewHolder *)view;
-(void)overlayView:(MFOverlayView *)overlayView didRemoveOverlayView:(FPKOverlayViewHolder *)view;
-(void)overlayView:(MFOverlayView *)overlayView willRemoveOverlayView:(FPKOverlayViewHolder *)view;

@end
