//
//  MFDeferredThumbnailOperation.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "FPKOperationsSharedData.h"
#import "FPKThumbnailCache.h"

@class MFDocumentManager;
@class FPKPageRenderingData;
@class MFDocumentViewController;

@protocol MFDeferredThumbnailOperationDelegate <NSObject>

-(void)handlePageData:(FPKPageRenderingData *)data;
-(MFDocumentViewController *)delegate;
@end

@interface MFDeferredThumbnailOperation : NSOperation

@property (nonatomic, strong) NSString * thumbsCacheDirectory;
@property (nonatomic, weak) id<MFDeferredThumbnailOperationDelegate> delegate;
@property (nonatomic, readwrite) CGSize size;
@property (readwrite) NSUInteger page;
@property (nonatomic, strong) MFDocumentManager * document;
@property (weak, readwrite, nonatomic) FPKOperationsSharedData * sharedData;
@property (nonatomic, strong) FPKThumbnailCache * cache;

@end
