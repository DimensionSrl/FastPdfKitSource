//
//  FPKOperationCenter.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import <Foundation/Foundation.h>

@interface FPKOperationCenter : NSObject

@property (nonatomic, readonly, strong) NSOperationQueue * operationQueueA;
@property (nonatomic, readonly, strong) NSOperationQueue * operationQueueB;

-(void)cancelAllOperations;
-(void)cancelQueueAOperations;
-(void)cancelQueueBOperations;
@end
