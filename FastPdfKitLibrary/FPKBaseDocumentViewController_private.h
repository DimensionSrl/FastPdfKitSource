//
//  MFDocumentViewController_private.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 6/3/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFDocumentViewController.h"
#import "FPKPageView.h"
#import "TVThumbnailScrollView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FPKSharedSettings_Private.h"
#import "FPKOperationsSharedData.h"
#import "circular_buffer.h"
#import "FPKDetailView.h"
#import "FPKChildViewControllersWrapper.h"
#import "FPKPageZoomCache.h"

#define PAGE_NUM_LABEL_TEXT(x,y) [NSString stringWithFormat:@"Page %d of %d",(x),(y)]
#define PAGE_NUM_LABEL_TEXT_PHONE(x,y) [NSString stringWithFormat:@"%d / %d",(x),(y)]

#import "FPKOverlayViewHelper.h"
#import "FPKPrivateOverlayViewHelper.h"
#import "FPKOperationCenter.h"
#import "FPKDrawablesHelper.h"

@class FlipContainer;

// Private stuff
@interface MFDocumentViewController() <TVThumbnailScrollViewDelegate,FPKPageViewDelegate, FPKOverlayViewDataSource_Private> {
    
    
    BOOL _thumbsViewVisible;

    pthread_mutex_t _optionsMutex;

    BOOL _visitPage;
    CircularBuffer _visitedPages;
    
    NSInteger _nextBias, _prevBias, _wrapperCount;           // Wrappers info.
    
    // Internal status
    MFDocumentDirection _currentDirection;
    BOOL _autoMode;
    MFDocumentMode _currentMode;
    MFDocumentAutoMode _currentAutoMode;
    
    MFDocumentLead _currentLead;
    NSUInteger _currentPage;

    CGSize _currentSize;
    
    CGFloat _defaultPageFlipWidth;
    
    BOOL _firstLoad;
    int _loads;
    
    BOOL _pageControlUsed;
    BOOL _pageButtonUsed;
    BOOL _autoZoom;
    
    NSInteger _currentPosition;              // Currently displayed position.
    NSUInteger _currentOrientation;          // Current orientation as intended by the application.
    NSUInteger _currentNumberOfPositions;    // Current number of "screens".
    
    NSInteger _currentDetailPosition;        // Current position of the detail view.
    
    NSInteger _maxNumberOfPages;
}

-(FlipContainer *)drawablesForPage:(NSUInteger)page;
-(FlipContainer *)touchablesForPage:(NSUInteger)page;

@property (nonatomic,strong) FPKOperationCenter * operationCenter;

@property (nonatomic, strong) NSPointerArray * delegates;

@property (nonatomic, strong) NSMutableSet * overlayDataSources; // Drawables and touchables data sources

@property (nonatomic, strong) NSMutableDictionary * overlayViewDataSources; // Overlay views data sources

@property (nonatomic, strong) UISlider * pageSlider;
@property (nonatomic, strong) UILabel * pageSliderLabel;
@property (nonatomic, strong) TVThumbnailScrollView * thumbnailScrollView;
@property (nonatomic, readwrite, strong) FPKOperationsSharedData * operationsSharedData;
@property (nonatomic, strong) FPKOverlayViewHelper * overlayViewHelper;
@property (nonatomic, strong) FPKPrivateOverlayViewHelper * privateOverlayViewHelper;
@property (nonatomic, strong) FPKThumbnailCache * thumbnailCache;
@property (nonatomic, strong) FPKPageZoomCache * pageZoomCache;
@property (nonatomic,strong) FPKDrawablesHelper * drawablesHelper;
@property (nonatomic,strong) FPKChildViewControllersHelper  * childViewControllersHelper;

@property (nonatomic,weak) UIView * toolbarBarButtonItemCustomView;

-(void)goToPage:(NSUInteger)page;

// TODO: all of this should go replaced with a common call to hide -> change status -> show (as in willRotate/didRotate)
-(void)changePageMode;
-(void)changePageLead;
-(void)changePageDirection;

// Focus managemente
-(void)focusOn;
-(void)focusOnRect:(CGRect)rect ofPage:(NSUInteger)page withZoomLevel:(float)level;
// -(void)unfocusFrom:(MFDeferredContentLayerWrapper *)target;

// Private getters and setters (no properties, pffft)
-(void)setCurrentPage:(NSUInteger)newPage;
-(void)setCurrentLead:(MFDocumentLead)newLead;
-(void)setCurrentMode:(MFDocumentMode)newMode;
-(void)setCurrentDirection:(MFDocumentDirection)newDirection;
-(MFDocumentLead)currentLead;
-(MFDocumentMode)currentMode;
-(MFDocumentDirection)currentDirection;

-(BOOL)isPageOnScreen:(NSUInteger)page;

#pragma mark - Proxy for FPKOverlayViewDataSource_Private

/*!
 Return an array of FPKOverlayWrapper.
 */
-(NSArray *)overlayViewsForPage:(NSUInteger)page;

/*!
 Return the CGRect for the UIView associated to the FPKOverlayWrapper.
 */
-(CGRect)collectRectForOverlayView:(FPKOverlayViewHolder *)ov page:(NSUInteger)page;

-(void)willRemoveOverlayView:(FPKOverlayViewHolder *)ov;
-(void)didRemoveOverlayView:(FPKOverlayViewHolder *)ov;
-(void)willAddOverlayView:(FPKOverlayViewHolder *)ov;
-(void)didAddOverlayView:(FPKOverlayViewHolder *)ov;

#pragma mark -

-(void)didEndZoomAtScale:(float)level;

-(BOOL)didReceiveDoubleTapOnAnnotationRect:(CGRect)rect withUri:(NSString *)uri onPage:(NSUInteger)page;
-(void)didReceiveTapOnTouchable:(id<MFOverlayTouchable>)touchable;
-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect withUri:(NSString *)uri onPage:(NSUInteger)page;
-(void)didReceiveURIRequest:(NSString*)uri;
-(void)didReceiveTapOnPage:(NSUInteger)page atPoint:(CGPoint)point;
-(void)willFollowLinkToPage:(NSUInteger)page;
-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect destination:(NSString *)destinationName file:(NSString *)fileName;
-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect page:(NSUInteger)pageNumber file:(NSString *)fileName;

-(Class<MFAudioPlayerViewProtocol>)classForAudioPlayerView;
-(BOOL)doesHaveToAutoplayVideo:(NSString*)videoUri;
-(BOOL)doesHaveToAutoplayAudio:(NSString*)audioUri;
-(BOOL)doesHaveToLoopVideo:(NSString*)videoUri;

-(CGRect)frameForLayer:(NSInteger)pos withBuffering:(BOOL)buffering;

-(void)hideAllLayers;
-(void)showAllLayers;

-(void)removeLayerFromDetail;

// Old user interaction.
@property (readwrite) BOOL savedUserInteractionEnabled;

// Wrappers.
@property (strong) NSArray *wrappers;

// Splashscreen.
@property (nonatomic, strong) UIImageView *splashImageView;
// @property (readwrite) BOOL showSplash;
@property (nonatomic, readwrite) BOOL overflowEnabled;

@property (nonatomic, strong) UIScrollView * pagedScrollView;

@property (nonatomic, readwrite) int fpk_preview_count;
@property (nonatomic, readwrite) int fpk_preview_next_bias;
@property (nonatomic, readwrite) int fpk_preview_prev_bias;

@property (nonatomic, copy) NSString * imagesCacheDirectory;
@property (nonatomic, copy) NSString * thumbsCacheDirectory;

@property (nonatomic, strong) MPMoviePlayerController * moviePlayerController;
@property (nonatomic, readwrite) FPKEncryptionAlgorithm encryptionAlgorithm;

@property (nonatomic, weak) FPKPageView * current;

@end

