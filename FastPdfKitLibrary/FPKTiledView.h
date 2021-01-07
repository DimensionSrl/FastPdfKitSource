//
//  MFTiledView2.h
//  FastPDF
//
//  Created by Nicolò Tosi on 4/29/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stuff.h"
#import "MFDocumentManager.h"
#import "MFTiledViewData.h"
#import <QuartzCore/QuartzCore.h>
#import "FPKPageRenderingData.h"

@protocol FPKTiledViewDataSource;
@protocol FPKTiledViewDelegate;

@class FPKDetailView;
@class FPKSharedSettings;

@interface FPKTiledView : UIView

@property (readwrite) BOOL invalid;

@property (weak, nonatomic) id<FPKTiledViewDataSource> dataSource;
@property (weak, nonatomic) id<FPKTiledViewDelegate> delegate;

@property (nonatomic, readwrite) MFDocumentMode mode;
@property (nonatomic, readwrite) BOOL isInFocus;

@property (nonatomic, strong) FPKPageData * leftPageMetrics;
@property (nonatomic, strong) FPKPageData * rightPageMetrics;
@property (nonatomic, weak) FPKSharedSettings * settings;
@end

@protocol FPKTiledViewDelegate <NSObject>

-(CGFloat)zoomLevelForTiledView:(FPKTiledView *)tiledView;

@end

@protocol FPKTiledViewDataSource <NSObject>

-(MFDocumentManager *)documentForTiledView:(FPKTiledView *)tiledView;
@end

