//
//  FPKDeferredOperation.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 27/11/14.
//
//

#import <Foundation/Foundation.h>

@class FPKMetricsOperation;
@class MFDeferredThumbnailOperation;
@class MFDocumentManager;

static const NSOperationQueuePriority FPKOperationPriorityMetrics = NSOperationQueuePriorityHigh;
static const NSOperationQueuePriority FPKOperationPriorityImage = NSOperationQueuePriorityNormal;
static const NSOperationQueuePriority FPKOperationPriorityThumbnail = NSOperationQueuePriorityLow;

@interface FPKDeferredOperation : NSOperation

@end
