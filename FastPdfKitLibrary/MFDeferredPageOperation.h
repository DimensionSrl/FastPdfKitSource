//
//  MFDeferredPageOperation.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPKOperationsSharedData.h"
#import "FPKPageRenderingData.h"
#import "FPKDeferredOperation.h"
#import "FPKThumbnailCache.h"
#import "FPKPageMetricsCache.h"
#import "FPKThumbnailDataStore.h"

@class MFDocumentManager;
@class MFDeferredContentLayerWrapper;
@class FPKSharedSettings;

@protocol MFDeferredPageOperationDelegate;

@interface MFDeferredPageOperation : FPKDeferredOperation

+(MFDeferredPageOperation *)operationWithPage:(NSUInteger)page document:(MFDocumentManager *)document delegate:(id<MFDeferredPageOperationDelegate>)delegate;

@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic, strong) MFDocumentManager* document;
@property (nonatomic, weak) id<MFDeferredPageOperationDelegate> delegate;
@property (nonatomic, copy) NSString* identifier;
@property (nonatomic, copy) NSString* imagesCacheDirectory;
@property (nonatomic, copy) NSString* thumbsCacheDirectory;
@property (strong, nonatomic) FPKOperationsSharedData * sharedData;
@property (strong, nonatomic) FPKSharedSettings * settings;
@property (strong, nonatomic) FPKThumbnailCache * cache;
@property (strong, nonatomic) id<FPKThumbnailDataStore> thumbnailDataStore;

@property (strong, nonatomic) FPKPageMetricsCache * metricsCache;
@end

@protocol MFDeferredPageOperationDelegate

/**
 * This method is invoked when the operation has completed.
 * @param operation The operation.
 * @param data The data crated by the operation.
 */
-(void)pageOperation:(MFDeferredPageOperation *)operation didCompleteWithData:(FPKPageRenderingData *)data;

@end
