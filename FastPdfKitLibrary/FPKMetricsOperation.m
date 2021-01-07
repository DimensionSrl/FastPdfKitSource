//
//  FPKMetricsOperation.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/14.
//
//

#import "FPKMetricsOperation.h"
#import "MFDocumentManager_private.h"

@implementation FPKMetricsOperation

+(FPKMetricsOperation *)operationWithPage:(NSUInteger)page document:(MFDocumentManager *)document delegate:(id<FPKMetricsOperationDelegate>)delegate {
    
    FPKMetricsOperation * operation = [[FPKMetricsOperation alloc]init];
    operation.page = page;
    operation.document = document;
    operation.delegate = delegate;
    operation.queuePriority = FPKOperationPriorityMetrics;
    
    return operation;
}

-(void)main
{
    @autoreleasepool {
        
    if(self.page == 0) {
        
        FPKPageData * dummyData = [FPKPageData zeroData];
        
        id __weak this = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate operation:this didCompleteWithMetrics:dummyData];
        });
        
        
        return;
    }
    
        FPKPageData * data = [self.metricsCache metricsWithPage:self.page];
        
        if(!data) {
            
            data = [FPKPageData new];
            data.metrics = [self.document pageMetricsForPage:self.page];
            data.page = self.page;
            
            [self.metricsCache addMetrics:data];
        }
    
    if(![self isCancelled]) {
        id __weak this = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate operation:this didCompleteWithMetrics:data];
        });
    }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
