//
//  FPKDetailView2.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import <UIKit/UIKit.h>
#import "FPKMetricsOperation.h"
#import "MFDeferredPageOperation.h"
#import "Stuff.h"
#import "FPKBackgroundView.h"
#import "FPKPageMetricsCache.h"
#import "FPKOverlayViewDataSource.h"
#import "MFOverlayView.h"
#import "FPKOverlayViewHelper.h"
#import "FPKPrivateOverlayViewHelper.h"
#import "FPKThumbnailCache.h"
#import "FPKOperationCenter.h"
#import "FPKDrawablesHelper.h"
#import "FPKChildViewControllersHelper.h"
#import "FPKPageZoomCache.h"

@class FPKTiledView;
@protocol FPKPageViewDelegate;

@interface FPKPageView : UIView <FPKMetricsOperationDelegate, FPKBackgroundViewDelegate>

@property (nonatomic, weak) UIScrollView * scrollView;
@property (nonatomic, weak) FPKBackgroundView * backgroundView;
@property (nonatomic, weak) FPKTiledView * tiledView;
@property (nonatomic, weak) MFOverlayView * overlayView;
@property (nonatomic, weak) UIView * zoomView;

@property (nonatomic, readwrite) NSUInteger leftPage;
@property (nonatomic, readwrite) NSUInteger rightPage;
@property (nonatomic, readwrite) MFDocumentMode pageMode;
@property (nonatomic, readwrite, getter=isInFocus) BOOL inFocus;

@property (nonatomic, readwrite) NSInteger position;
@property (nonatomic, readwrite) NSInteger offset;

@property (nonatomic, strong) MFDocumentManager * document;
@property (nonatomic, strong) FPKPageMetricsCache * metricsCache;
@property (nonatomic, strong) FPKOverlayViewHelper * overlayViewHelper;
@property (nonatomic, strong) FPKPrivateOverlayViewHelper * privateOverlayViewHelper;

@property (nonatomic, weak) id<FPKPageViewDelegate> delegate;

@property (nonatomic,strong) FPKThumbnailCache * thumbnailCache;
@property (strong, nonatomic) id<FPKThumbnailDataStore> thumbnailDataStore;

@property (nonatomic,strong) FPKOperationCenter * operationCenter;
@property (nonatomic,strong) FPKDrawablesHelper * drawablesHelper;
@property (nonatomic,strong) FPKChildViewControllersHelper * childViewControllersHelper;
@property (nonatomic,strong) FPKPageZoomCache * pageZoomCache;

@property (nonatomic,weak) FPKSharedSettings * settings;

-(void)reloadOverlays;

-(CGPoint)convertPoint:(CGPoint)point fromViewToPage:(NSUInteger)page;
-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page;

-(CGPoint)convertPoint:(CGPoint)point fromOverlayviewToPage:(NSUInteger)page;
-(CGPoint)convertPoint:(CGPoint)point toOverlayviewFromPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect fromOverlayviewToPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect toOverlayviewFromPage:(NSUInteger)page;


/*!
 Return the page number containing the view location.
 
 @param location The location in the view.
 @return NSUInteger The page at the location.
 
 */
-(NSUInteger)pageAtLocation:(CGPoint)location;

@end

@protocol FPKPageViewDelegate

-(BOOL)pageViewShouldEdgeFlip:(FPKPageView *)pageView;
-(BOOL)pageViewShouldZoomOnDoubleTap:(FPKPageView *)pageView;
-(FPKSharedSettings *)sharedSettingsForPageView:(FPKPageView *)pageView;
-(FPKOperationsSharedData *)sharedDataForPageView:(FPKPageView *)pageView;
-(CGFloat)maxZoomScaleForPageView:(FPKPageView *)pageView;
-(void)pageView:(FPKPageView *)pageView didReceiveTapOnTouchable:(id<MFOverlayTouchable>)touchable page:(NSUInteger)page;

/*!
 This method is called by PageView when the user tap on a link to a page on a 
 different file.
 
 @param pageView The PageView.
 @param page The page requested.
 @param file The file with the page.
 
 @return BOOL If the request should be considered handled or not.
 */
-(BOOL)pageView:(FPKPageView *)pageView wantsPage:(NSUInteger)page file:(NSString *)file annotationRect:(CGRect)rect;

/*!
 This method is called by PageView when the user tap on a link to a named destination
 on a different file.
 
 @param pageView The PageView.
 @param destination The named destination.
 @param file The file name with the destination.
 
 @return BOOL If the request should be considered handled or not.
 */
-(BOOL)pageView:(FPKPageView *)pageView wantsDestination:(NSString *)destination file:(NSString *)file annotationRect:(CGRect)rect;


/*!
 This method is called by PageView when the user tap on a link to a page on the
 same document.
 
 @param pageView The PageView.
 @param page The requested page.
 
 @return BOOL true if the request should be considered handled, otherwise false.
 */
-(BOOL)pageView:(FPKPageView *)pageView wantsPage:(NSUInteger)page;


-(void)pageViewWantsToFlipLeft:(FPKPageView *)pageView;
-(void)pageViewWantsToFlipRight:(FPKPageView *)pageView;
-(NSString *)thumbnailsDirectoryForPageView:(FPKPageView *)pageView;
-(NSString *)imagesDirectoryForPageView:(FPKPageView *)pageView;
-(BOOL)documentInteractionEnabledForPageView:(FPKPageView *)pageView;
-(CGFloat)edgeFlipWidthForPageView:(FPKPageView *)pageView;
-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapOnAnnotationRect:(CGRect)rect uri:(NSString *)uri page:(NSUInteger)page;
-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapAtPoint:(CGPoint)point page:(NSUInteger)page;
-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapAtPoint :(CGPoint)point;

@end
