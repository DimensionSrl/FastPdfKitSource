//
//  MFDocumentManager_private.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 6/3/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFDocumentManager.h"
#import "FPKAnnotationsHelper.h"
#import "FPKAnnotationsCache.h"
#import "FPKAnnotationBuilder.h"
#import "FPKPageMetrics.h"

#import <pthread/pthread.h>

@interface MFDocumentManager() {
    pthread_rwlock_t _pageDataLock;
}

-(NSArray *)linkAndURIAnnotationsForPageNumber:(NSUInteger)pageNr;
-(NSArray *)videoAnnotationsForPageNumber:(NSUInteger)pageNr;
-(NSArray *)webAnnotationsForPageNumber:(NSUInteger)pageNr;
-(NSArray *)audioAnnotationsForPageNumber:(NSUInteger)pageNr;
-(NSArray *)remoteAudioAnnotationsForPageNumber:(NSUInteger)pageNr;
-(NSArray *)configAnnotationsForPageNumber:(NSUInteger)pageNr;

-(void)getCropbox:(CGRect *)cropbox 
      andRotation:(int *)rotation 
    forPageNumber:(NSInteger)pageNumber;

-(NSURL *)URLForLocalResource:(NSString *)resource;
+(NSURL *)URLForRemoteResource:(NSString *)resource;

@property (nonatomic, strong) FPKAnnotationsHelper * annotationsHelper;
@property (nonatomic, strong) FPKAnnotationsCache * annotationsCache;
@property (nonatomic, strong) FPKAnnotationBuilder * annotationBuilder;

/**
 * FPKPageMetric factory object.
 * It will ensure equal metrics are represented by the same object.
*/
@property (nonatomic, strong) FPKPageMetricsFactory * metricsFactory;

/**
 * Page number keyed FPKPageMetric cache.
 */
@property (nonatomic, strong) NSMutableDictionary * metricsCache;

-(FPKPageMetrics *)pageMetricsForPage:(NSUInteger)page;

@end