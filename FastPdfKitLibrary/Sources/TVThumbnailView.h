//
//  MFSliderDetailVIew.h
//  FastPdfKit Sample
//
//  Created by Nicolò Tosi on 7/7/11.
//  Copyright 2011 MobFarm S.a.s.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSData+Crypto.h"
#import "FPKOperationsSharedData.h"
#import "FPKThumbnailCache.h"

@class TVThumbnailScrollView;

@protocol TVThumbnailViewDelegate;

@interface TVThumbnailView : UIView
-(void)asynchronouslyLoadImageForPage:(NSUInteger)page;

@property (nonatomic,strong) FPKThumbnailCache * cache;

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) UIImage * thumbnailImage;
@property (nonatomic, weak) id<TVThumbnailViewDelegate> delegate;
@property (nonatomic, readwrite, strong) FPKOperationsSharedData * sharedData;
@property (nonatomic, readwrite) NSInteger position;

@end

@protocol TVThumbnailViewDelegate

-(NSData *)thumbnailView:(TVThumbnailView *)view dataForPage:(NSUInteger)page;
-(void)thumbnailViewTapped:(TVThumbnailView *)view position:(NSInteger)position;

@end

