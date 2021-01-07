//
//  MFDeferredContentLayerWrapper.h
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/17/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "MFDeferredThumbnailOperation.h"
#import "FPKOperationCenter.h"

@class MFDocumentViewController;
@class FPKPageRenderingData;
@class MFPageDataOldEngine;
@class FPKSharedSettings;

extern NSString * const FPKPageDescriptionSize;

extern  NSString * const FPKPageDescriptionPage;

extern  NSString * const FPKPageDescriptionLeft;
extern  NSString * const FPKPageDescriptionRight;
extern  NSString * const FPKPageDescriptionLegacy;
extern  NSString * const FPKPageDescriptionMode;
extern  NSString * const FPKPageDescriptionShadow;
extern  NSString * const FPKPageDescriptionPadding;


@interface MFDeferredContentLayerWrapper : NSObject<MFDeferredThumbnailOperationDelegate> {

	CALayer * layer;
    
	NSInteger position;
    
	MFDocumentViewController *__weak delegate;
	
	NSOperation * pendingOperation;
    NSOperation * pendignOperationExtra;
	
	NSNumber * pendingDataName;
	
    NSInteger operationId;	
    
	CGRect savedFrame;
    
    NSString * name;
    
    CALayer * leftLayer;
    CALayer * rightLayer;
    NSUInteger leftPage;
    NSUInteger rightPage;
    CGImageRef leftImage;
    CGImageRef rightImage;
    
    NSOperation * pendingTOpL;
    NSOperation * pendingTOpR;
    
    BOOL leftHRDone;
    BOOL rightHRDone;
    
    FPKSharedSettings *settings;
    
    NSInteger offset;
    
    pthread_mutex_t mutex;
}

-(void)updateWithContentInfo:(NSDictionary *)info;

+(NSDictionary *)renderInfoWithSize:(CGSize)size andPriority:(NSUInteger)priority;

@property (nonatomic, strong) FPKOperationCenter * operationCenter;

@property (copy) NSNumber * pendingDataName;
@property (strong) CALayer * layer;
@property (strong) NSOperation * pendingOperation;
@property (strong) NSOperation * pendingOperationExtra;
@property (nonatomic, strong) NSDictionary * leftDescription;
@property (nonatomic, strong) NSDictionary * rightDescription;
@property (nonatomic, strong) FPKPageRenderingData * leftData;
@property (nonatomic, strong) FPKPageRenderingData * rightData;
@property (nonatomic, strong) MFPageDataOldEngine * data;
@property (nonatomic, strong) CALayer * leftLayer;
@property (nonatomic, strong) CALayer * rightLayer;
@property (nonatomic, strong) NSOperation * pendingTOpL;
@property (nonatomic, strong) NSOperation * pendingTOpR;
@property NSInteger position;
@property CGRect savedFrame;
@property BOOL isInFocus;
@property (nonatomic,copy) NSString * name;
@property (weak) MFDocumentViewController * delegate;
@property (strong, nonatomic) FPKSharedSettings *settings;
@property (nonatomic, readwrite) NSInteger offset;
@end
