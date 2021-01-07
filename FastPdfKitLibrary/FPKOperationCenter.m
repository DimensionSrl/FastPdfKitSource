//
//  FPKOperationCenter.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import "FPKOperationCenter.h"

@interface FPKOperationCenter()

@property (nonatomic, readwrite, strong) NSOperationQueue * operationQueueA;
@property (nonatomic, readwrite, strong) NSOperationQueue * operationQueueB;

@end


@implementation FPKOperationCenter

-(instancetype)init {
    self = [super init];
    if(self) {
        
        NSOperationQueue * queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        self.operationQueueA = queue;
        
        queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        self.operationQueueB = queue;
        
    }
    return self;
}

-(void)cancelQueueAOperations {
    [_operationQueueA cancelAllOperations];
}

-(void)cancelQueueBOperations {
    [_operationQueueB cancelAllOperations];
}


-(void)cancelAllOperations {
    [_operationQueueA cancelAllOperations];
    [_operationQueueB cancelAllOperations];
}

-(void)dealloc {
    [_operationQueueA cancelAllOperations];
    [_operationQueueB cancelAllOperations];
    [_operationQueueA waitUntilAllOperationsAreFinished];
    [_operationQueueB waitUntilAllOperationsAreFinished];
}

@end
