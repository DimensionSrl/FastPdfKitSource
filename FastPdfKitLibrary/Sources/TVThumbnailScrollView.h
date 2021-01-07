//
//  TVThumbnailView.h
//  ThumbnailView
//
//  Created by Nicolò Tosi on 10/14/11.
//  Copyright (c) 2011 MobFarm S.a.s.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFDocumentManager.h"
#import "TVThumbnailView.h"
#import "FPKOperationsSharedData.h"
#import "FPKThumbnailCache.h"
#import "FPKThumbnailDataStore.h"

@class TVThumbnailScrollView;

enum TVThumbnailScrollViewOrientation {
    TVThumbnailScrollViewOrientationHorizontal = 0,
    TVThumbnailScrollViewOrientationVertical
};
typedef NSUInteger TVThumbnailScrollViewOrientation;

enum TVThumbnailScrollViewDirection {
    TVThumbnailScrollViewDirectionForward = 0,
    TVThumbnailScrollViewDirectionBacward = 1
};
typedef NSUInteger TVThumbnailScrollViewDirection;

@protocol TVThumbnailScrollViewDelegate

-(void)thumbnailScrollView:(TVThumbnailScrollView *)scrollView didSelectPage:(NSUInteger)page;
-(NSString *)thumbsCacheDirectory;

@optional
-(NSString *)thumbnailScrollView:(TVThumbnailScrollView *)scrollView thumbnailTitleForPage:(NSUInteger)page;

@end

@interface TVThumbnailScrollView : UIView <UIScrollViewDelegate, TVThumbnailViewDelegate> {
    
    NSUInteger thumbnailCount;
    
    NSUInteger page;
    NSUInteger pagesCount;
    
    NSArray * thumbnailViews;
    
    CGSize thumbnailSize;
    CGFloat padding;
    
    id<NSObject, TVThumbnailScrollViewDelegate> __weak delegate;
   
    NSUInteger currentThumbnailPosition;
    BOOL backgroundWorkStillGoingOn;
    BOOL shouldContinueBackgrounWork;
    BOOL fast;
    
    MFDocumentManager * document;
    
    NSString * cacheFolderPath;
    
    FPKOperationsSharedData * sharedData;
}

@property (nonatomic,strong) FPKThumbnailCache * cache;
@property (nonatomic,strong) id<FPKThumbnailDataStore> thumbnailDataStore;

@property (nonatomic,readwrite) NSUInteger pagesCount;

@property (nonatomic,readwrite) CGSize thumbnailSize;
@property (nonatomic,readwrite) CGFloat padding;

@property (nonatomic,weak) id<TVThumbnailScrollViewDelegate> delegate;
@property (nonatomic, readwrite, strong) FPKOperationsSharedData * sharedData;
@property (nonatomic,strong) MFDocumentManager * document;

@property (nonatomic, readwrite) TVThumbnailScrollViewOrientation orientation;
@property (readwrite, nonatomic) TVThumbnailScrollViewDirection direction;

-(void)setPage:(NSUInteger)page animated:(BOOL)animated;
-(NSUInteger)page;

-(void)start;
-(void)stop;
-(void)slowdown;
-(void)speedup;

@end
