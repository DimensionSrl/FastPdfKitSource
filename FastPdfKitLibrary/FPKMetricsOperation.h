//
//  FPKMetricsOperation.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import <UIKit/UIKit.h>
#import "FPKPageRenderingData.h"
#import "MFDocumentManager.h"
#import "FPKDeferredOperation.h"
#import "FPKPageMetricsCache.h"

@protocol FPKMetricsOperationDelegate;

@interface FPKMetricsOperation : FPKDeferredOperation

@property (nonatomic,readwrite) NSUInteger page;
@property (weak, nonatomic) id<FPKMetricsOperationDelegate>delegate;
@property (nonatomic, strong) MFDocumentManager * document;
@property (nonatomic, strong) FPKPageMetricsCache * metricsCache;

+(FPKMetricsOperation *)operationWithPage:(NSUInteger)page document:(MFDocumentManager *)document delegate:(id<FPKMetricsOperationDelegate>)delegate;

@end

@protocol FPKMetricsOperationDelegate

-(void)operation:(FPKMetricsOperation *)operation didCompleteWithMetrics:(FPKPageData *)metrics;

@end
