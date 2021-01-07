//
//  FPKDetailView.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MFTiledViewData.h"
#import "MFDocumentViewController.h"
#import "FPKTiledView.h"
#import "MFScrollDetailView.h"
#import "FlipContainer.h"

@protocol FPKDrawablesDataSource_Private <NSObject>

-(FlipContainer *)drawablesForPage:(NSUInteger)page;
-(FlipContainer *)touchablesForPage:(NSUInteger)page;

@end

@protocol FPKDrawablesDelegate_Private <NSObject>

@end

@interface FPKDetailView : UIView <UIScrollViewDelegate> {
    
    MFDocumentViewController * __weak delegate;
	
	NSInteger viewPosition;
	NSInteger pageMode;
	NSInteger pageLead;
	NSInteger leftPage;
	NSInteger rightPage;
	NSInteger pageDirection;
	
	MFScrollDetailView * scrollDetailView;
	UIView * intermediateView; // Not necessary on iOS5.
    
	UIView * containerView;
	UIView * previewView;
	FPKTiledView * tiledView;
    FPKRenderInfo renderInfo;
    
    NSArray * leftOverlayViews;
    NSArray * rightOverlayViews;
    
    UIView * overlayView;
	
	BOOL overlayEnabled;
	
	BOOL zoomed;
	float zoomLevel;
	CGPoint zoomOffset;
	
	BOOL pendingZoom;
	CGRect pendingZoomRect;
	NSUInteger pendingZoomPage;
	float pendingZoomLevel;
    
    BOOL pendingOverlay;
    BOOL onSight;
    BOOL pendingOverlayViews;
    CGFloat edgeFlipWidth;

    long unsigned int counter;
    
}

-(id)initWithFrame:(CGRect)frame delegate:(MFDocumentViewController *)delegate;

-(void)isOnSight;
-(void)isOutOfSight:(BOOL)animated;
-(void)emptyCache;

@property (nonatomic,assign) CGFloat edgeFlipWidth;
@property (readonly) long unsigned int counter;
@property (readwrite) BOOL overlayEnabled;
@property (readwrite) BOOL pendingOverlay;
@property (readwrite) BOOL pendingZoom;
@property (readwrite) BOOL pendingOverlayViews;

@property (nonatomic,strong) UIView * intermediateView;
@property (nonatomic,strong) MFScrollDetailView * scrollDetailView;
@property (nonatomic,strong) UIView * previewView;
@property (nonatomic,strong) FPKTiledView * tiledView;
@property (nonatomic,strong) UIView * containerView;

@property (weak, nonatomic) MFDocumentViewController * delegate;
@property (weak, nonatomic) id<FPKDrawablesDataSource_Private> drawablesDataSource;
@property (readwrite, nonatomic) FPKRenderInfo renderInfo;

@property (strong) UIView * overlayView;

@property (nonatomic) NSInteger viewPosition;
@property (nonatomic) NSInteger pageMode;
@property (nonatomic) NSInteger leftPage;
@property (nonatomic) NSInteger rightPage;
@property (nonatomic) NSInteger pageLead;
@property (nonatomic) NSInteger pageDirection;

@property (readonly) float zoomScale;
@property (readonly) CGPoint zoomOffset;
@property (readonly) CGRect zoomRect;

@property (strong, nonatomic) FPKSharedSettings * settings;

-(BOOL) showShadow;
-(CGFloat) padding;
-(void)invalidateRenderInfo;
-(float)zoomLevelForAnnotationRect:(CGRect)rect ofPage:(NSUInteger)page;

-(void)reloadOverlay;
-(void)performZoomOnRect:(CGRect)rect ofPage:(NSUInteger)page withZoomLevel:(float)aZoomLevel;
-(void)setZoomOnUnfocus;
-(void)singleTapMethod;
-(void)doubleTapMethod:(NSArray *)touch;
-(void)setZoomLevel;
-(void)setPosition:(NSInteger)aPosition;
-(void)resetContents;

-(CGPoint)convertPoint:(CGPoint)point fromViewtoPage:(NSUInteger)page;
-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page;

-(CGRect)convertRect:(CGRect)rect toOverlayFromPage:(NSUInteger)page;
-(CGRect)convertRect:(CGRect)rect fromOverlayToPage:(NSUInteger)page;
-(CGPoint)convertPoint:(CGPoint)point toOverlayFromPage:(NSUInteger)page;
-(CGPoint)convertPoint:(CGPoint)point fromOverlayToPage:(NSUInteger)page;

-(BOOL)gesturesDisabled;


-(NSArray *)touchablesForPage:(NSUInteger)page;
-(NSArray *)drawablesForPage:(NSUInteger)page;

@end
