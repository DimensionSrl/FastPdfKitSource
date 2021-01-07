 //
//  MFDeferredContentLayerWrapper.m
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/17/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFDeferredContentLayerWrapper.h"
#import "MFDeferredRenderOperation.h"
#import "MFDocumentManager_private.h"
#import "PrivateStuff.h"
#import "FPKBaseDocumentViewController_private.h"
#import "MFDeferredPageOperation.h"
#import "FPKPageRenderingData.h"
#import "FPKSharedSettings_Private.h"
#import <pthread.h>

@interface MFDeferredContentLayerWrapper() <MFDeferredRenderOperationDelegate, MFDeferredPageOperationDelegate>

@end

 NSString * const FPKPageDescriptionSize = @"FPKPageDescriptionSize";
 NSString * const FPKPageDescriptionPage = @"FPKPageDescriptionPage";
 NSString * const FPKPageDescriptionLeft = @"FPKPageDescriptionLeft";
 NSString * const FPKPageDescriptionRight = @"FPKPageDescriptionRight";
 NSString * const FPKPageDescriptionLegacy = @"FPKPageDescriptionLegacy";
 NSString * const FPKPageDescriptionMode = @"FPKPageDescriptionMode";
 NSString * const FPKPageDescriptionShadow = @"FPKPageDescriptionShadow";
 NSString * const FPKPageDescriptionPadding = @"FPKPageDescriptionPadding";

@implementation MFDeferredContentLayerWrapper

@synthesize delegate;
@synthesize pendingOperation, pendingDataName, pendingOperationExtra;
@synthesize layer;
@synthesize position;
@synthesize savedFrame;
@synthesize isInFocus;
@synthesize name;
@synthesize leftDescription, rightDescription;
@synthesize pendingTOpL, pendingTOpR;
@synthesize leftData, rightData;
@synthesize leftLayer, rightLayer;
@synthesize data;
@synthesize settings;
@synthesize offset;

#define FPK_KEY_RENDERINFO_SIZE @"size"
#define FPK_KEY_RENDERINFO_PRIORITY @"priority"


+(NSDictionary *)renderInfoWithSize:(CGSize)size andPriority:(NSUInteger)priority {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:size],FPK_KEY_RENDERINFO_SIZE,[NSNumber numberWithUnsignedInteger:priority],FPK_KEY_RENDERINFO_PRIORITY, nil];
}


+(NSDictionary *)descriptionWithSize:(CGSize)size page:(NSUInteger)page mode:(NSUInteger)mode {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:size], FPKPageDescriptionSize,
            [NSNumber numberWithUnsignedInt:(unsigned int)page], FPKPageDescriptionPage,
            [NSNumber numberWithUnsignedInt:(unsigned int)mode], FPKPageDescriptionMode,
            nil];
}

+(NSDictionary *)descriptionWithSize:(CGSize)size leftPage:(NSUInteger)leftPage rightPage:(NSUInteger)rightPage legacy:(BOOL)legacy mode:(NSUInteger)mode shadow:(BOOL)shadow padding:(float)padding {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:size], FPKPageDescriptionSize,
            [NSNumber numberWithUnsignedInt:(unsigned int)leftPage], FPKPageDescriptionLeft,
            [NSNumber numberWithUnsignedInt:(unsigned int)rightPage], FPKPageDescriptionRight,
            [NSNumber numberWithBool:legacy], FPKPageDescriptionLegacy,
            [NSNumber numberWithBool:shadow], FPKPageDescriptionShadow,
            [NSNumber numberWithFloat:padding], FPKPageDescriptionPadding,
            [NSNumber numberWithUnsignedInteger:mode], FPKPageDescriptionMode,
            nil];
}

#pragma mark - MFDeferredPageOperationDelegate

-(void)pageOperation:(MFDeferredPageOperation *)operation didCompleteWithData:(FPKPageRenderingData *)opData
{
    [self handlePageData:opData];
}

-(NSString *)thumbsCacheDirectoryForPageOperation:(MFDeferredPageOperation *)operation
{
    return [delegate thumbsCacheDirectory];
}

-(NSString *)imagesCacheDirectoryForPageOperation:(MFDeferredPageOperation *)operation
{
    return [delegate imagesCacheDirectory];
}

#pragma mark - MFDeferredRenderOperationDelegate

-(void)renderOperation:(MFDeferredRenderOperation *)operation didCompleteWithData:(MFPageDataOldEngine *)opData
{
    [self updateContentWithData:opData];
}

-(MFDocumentManager *)documentForRenderOperation:(MFDeferredRenderOperation *)operation
{
    return [delegate document];
}

#pragma mark -

-(void)updateContentWithData:(MFPageDataOldEngine *)someData {
	
    @autoreleasepool {
        
         // Retain data to prevent deallocation
        
        if([[someData operationId]isEqualToNumber:pendingDataName]) {
            
            [layer setContents:(id)[someData image]];
            self.data = someData;
            
        }
        
    }

}

-(void)updateLeftLayer {
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPagesRendering(NULL, NULL, &layerFrame, NULL, parentLayerFrame, self.leftData.data.metrics.cropbox, CGRectZero, self.leftData.data.metrics.angle, 0, [delegate padding], NO);
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];


    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    leftLayer.frame = layerFrame;
    
    if(self.settings.showShadow) {
        leftLayer.shadowColor = [UIColor blackColor].CGColor;
        leftLayer.shadowOffset = CGSizeMake(0, 5);
        leftLayer.shadowOpacity = 0.25;
        leftLayer.shadowPath = shadowPath;
    }

    [CATransaction commit];
}

-(void)updateRightLayer {
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPagesRendering(NULL, NULL, NULL, &layerFrame, parentLayerFrame, CGRectZero, self.rightData.data.metrics.cropbox, 0, self.rightData.data.metrics.angle, [delegate padding], NO);
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];

        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        rightLayer.frame = layerFrame;
    
    if(self.settings.showShadow) {
        rightLayer.shadowColor = [UIColor blackColor].CGColor;
        rightLayer.shadowOffset = CGSizeMake(MIN(5, self.settings.padding),5);
        rightLayer.shadowOpacity = 0.25;
        rightLayer.shadowPath = shadowPath;
    }

        [CATransaction commit];
}

-(void)updateLayer {
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPageRendering(NULL, &layerFrame, parentLayerFrame, self.leftData.data.metrics.cropbox, self.leftData.data.metrics.angle, [delegate padding], NO);
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];

        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        leftLayer.frame = layerFrame;
    
    if(self.settings.showShadow) {
        leftLayer.shadowColor = [UIColor blackColor].CGColor;
        leftLayer.shadowOffset = CGSizeMake(MIN(5, self.settings.padding),5);
        leftLayer.shadowOpacity = 0.25;
        leftLayer.shadowPath = shadowPath;
    }

        [CATransaction commit];
    
   }

-(void)setLeftImage:(FPKPageRenderingData *)newData {
    
    self.leftData = newData;
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPagesRendering(NULL, NULL, &layerFrame, NULL, parentLayerFrame, newData.data.metrics.cropbox, CGRectZero, newData.data.metrics.angle, 0, [delegate padding], NO);
    
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    leftLayer.frame = layerFrame;
    leftLayer.contents = (id)[newData ui_image].CGImage;
    
    if(self.settings.showShadow) {
        leftLayer.shadowColor = [UIColor blackColor].CGColor;
        leftLayer.shadowOffset = CGSizeMake(0, 5);
        leftLayer.shadowOpacity = 0.25;
        leftLayer.shadowPath = shadowPath;
    }
    [CATransaction setCompletionBlock:^{
        newData.ui_image = nil;
    }];
    [CATransaction commit];

    // self.leftData.ui_image = nil;
}

-(void)setImage:(FPKPageRenderingData *)newData {
    
    self.leftData = newData;
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPageRendering(NULL, &layerFrame, parentLayerFrame, newData.data.metrics.cropbox, newData.data.metrics.angle, [delegate padding], NO);
  
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    leftLayer.frame = layerFrame;
    leftLayer.contents = (id)[newData ui_image].CGImage;
    
    if(self.settings.showShadow) {
        
        leftLayer.shadowColor = [UIColor blackColor].CGColor;
        leftLayer.shadowOffset = CGSizeMake(MIN(5, self.settings.padding),5);
        leftLayer.shadowOpacity = 0.25;
        leftLayer.shadowPath = shadowPath;
    }
    [CATransaction setCompletionBlock:^{
        newData.ui_image = nil;
    }];
    [CATransaction commit];
   
    // self.leftData.ui_image = nil;
}

-(void)setRightImage:(FPKPageRenderingData *)newData {
    
    self.rightData = newData;
    
    CGSize parentLayerFrame = self.layer.frame.size;
    CGRect layerFrame;
    
    transformAndBoxForPagesRendering(NULL, NULL, NULL, &layerFrame, parentLayerFrame, CGRectZero, newData.data.metrics.cropbox, 0, newData.data.metrics.angle, [delegate padding], NO);
    
    CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    rightLayer.frame = layerFrame;
    rightLayer.contents = (id)[newData ui_image].CGImage;
    
    if(self.settings.showShadow) {
        rightLayer.shadowColor = [UIColor blackColor].CGColor;
        rightLayer.shadowOffset = CGSizeMake(MIN(5, self.settings.padding), 5);
        rightLayer.shadowOpacity = 0.25;
        rightLayer.shadowPath = shadowPath;
    }
    [CATransaction setCompletionBlock:^{
        newData.ui_image = nil;
    }];
    [CATransaction commit];
    
    // self.rightData.ui_image = nil;
}

+(NSString *)thumbnailNameForPage:(NSUInteger)page {
    return [NSString stringWithFormat:@"thumb_%lu.thumb",(unsigned long)page];
}

+(NSString *)thumbnailImagePathForPage:(NSUInteger)page cacheFolderPath:(NSString *)documentId {
    
    NSString * tmbName = [[self class]thumbnailNameForPage:page];
    
    return [documentId stringByAppendingPathComponent:tmbName];
}

-(void)loadThumbnail:(NSNumber *)pageValue {
    
    @autoreleasepool {
    
    NSUInteger page = [pageValue unsignedIntValue];
    
    NSString * fallbackThumbPath = [[self class]thumbnailImagePathForPage:page cacheFolderPath:[delegate thumbsCacheDirectory]];
        
    if(![[NSFileManager defaultManager] fileExistsAtPath:fallbackThumbPath]) {
        return;
    }
        
        FPKPageMetrics * metrics = [[delegate document] pageMetricsForPage:page];
        
        CGDataProviderRef provider = CGDataProviderCreateWithFilename([fallbackThumbPath cStringUsingEncoding:NSUTF8StringEncoding]);
        CGImageRef fallbackThumbSrcImage = CGImageCreateWithPNGDataProvider(provider, NULL, YES, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        CGFloat height = CGImageGetHeight(fallbackThumbSrcImage);
        CGFloat width = CGImageGetWidth(fallbackThumbSrcImage);
        
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(ctx, 0, (CGImageGetHeight(fallbackThumbSrcImage)));
        CGContextScaleCTM(ctx, 1, -1);
        
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), fallbackThumbSrcImage);
        
        CGImageRef fallbackThumbDstImage = CGBitmapContextCreateImage(ctx);
        
        UIGraphicsEndImageContext();
        
        UIImage * fallbackThumbFinalImage = [[UIImage alloc]initWithCGImage:fallbackThumbDstImage];
        
        CGImageRelease(fallbackThumbDstImage);
        CGImageRelease(fallbackThumbSrcImage);
        
        FPKPageRenderingData * fallbackThumbdata = [FPKPageRenderingData dataWithPage:page metrics:metrics];
        [fallbackThumbdata setUi_image:fallbackThumbFinalImage];
        [fallbackThumbdata setThumb:YES];
        
        [self handlePageData:fallbackThumbdata];

    }
}

-(void)handlePageDataInternal:(FPKPageRenderingData *)pageData {

        NSUInteger page = pageData.data.page;
        
        if([pageData isThumb]) {
            
            // NSLog(@"Handling thumb");
            
            if(page == rightPage) {
                
                if(rightHRDone) {
                    
                    return;
                }
                
                [self performSelectorOnMainThread:@selector(setRightImage:) withObject:pageData waitUntilDone:NO];
                
            } else if (page == leftPage) {
                
                if(leftHRDone) {
                    
                    return;
                }
                
                if([delegate mode] == MFDocumentModeDouble) {
                    
                    [self performSelectorOnMainThread:@selector(setLeftImage:) withObject:pageData waitUntilDone:NO];
                    
                } else {
                    
                    [self performSelectorOnMainThread:@selector(setImage:) withObject:pageData waitUntilDone:NO];
                }
            } else {
                
                NSLog(@"Wrong thumb %lu (l %lu r %lu)", (unsigned long)page, (unsigned long)leftPage, (unsigned long)rightPage);
            }
            
        } else {
            
            if(page == rightPage) {
                
                [pendingTOpR cancel];
                rightHRDone = YES;
                
                [self performSelectorOnMainThread:@selector(setRightImage:) withObject:pageData waitUntilDone:NO];
                
            } else if (page == leftPage) {
                
                [pendingTOpL cancel];
                leftHRDone = YES;
                
                if([delegate mode] ==  MFDocumentModeDouble) {
                    [self performSelectorOnMainThread:@selector(setLeftImage:) withObject:pageData waitUntilDone:NO];
                } else {
                    [self performSelectorOnMainThread:@selector(setImage:) withObject:pageData waitUntilDone:NO];
                }
                
            } else {
                
                NSLog(@"Wrong page %lu (l %lu r %lu)", (unsigned long)page, (unsigned long)leftPage, (unsigned long)rightPage);
            }
            
        }
    

}

-(void)handlePageData:(FPKPageRenderingData *)pageData {

    [self performSelectorOnMainThread:@selector(handlePageDataInternal:) withObject:pageData waitUntilDone:NO];
    
}

-(void)updateWithContentInfoNew:(NSDictionary *)i {
    
    static NSInteger sharedOperationId;
    
    NSDictionary * info = i;
    
    // [self setPendingOperation:nil];
    
    [pendingOperation cancel]; // If there's one, operation will be cancelled
    [pendingOperationExtra cancel];
    [pendingTOpL cancel];
    [pendingTOpR cancel];
    
    // CGSize size = [[info valueForKey:FPK_KEY_RENDERINFO_SIZE] CGSizeValue];
    NSUInteger priority = [[info valueForKey:FPK_KEY_RENDERINFO_PRIORITY] unsignedIntValue];
    
	//[layer setContents:nil]; // Clean up the layer...
	
    leftHRDone = NO;
    rightHRDone = NO;
    
	NSInteger targetLeftPage;
	NSInteger targetRightPage;
    
	MFDeferredPageOperation * deferredOp = nil;
    
    operationId = sharedOperationId++;
    
	if([delegate currentMode] == MFDocumentModeSingle || [delegate currentMode] == MFDocumentModeOverflow) {
		
		targetLeftPage = leftPageForPosition(position, MFDocumentModeSingle, [delegate currentLead], [delegate currentDirection], [[delegate document]numberOfPages]);
		
        pthread_mutex_lock(&mutex);
        
        if(self.rightData && (self.rightData.data.page == targetLeftPage)) {
            
            // Flip!!!
            
            FPKPageRenderingData * tmpData = self.rightData;
            self.rightData = self.leftData;
            self.leftData = tmpData;
            
            CALayer * tmpLayer = self.rightLayer;
            self.rightLayer = self.leftLayer;
            self.leftLayer = tmpLayer;
        }
        
        // NSDictionary * description = [MFDeferredContentLayerWrapper descriptionWithSize:CGSizeZero page:lPage mode:[delegate currentMode]];

        if(self.leftData && self.leftData.data.page == targetLeftPage) {
            
            // Just update the position
            
            if([delegate currentMode] == MFDocumentModeSingle) {
            
                [self updateLayer];
            
            } else if ([delegate currentMode] == MFDocumentModeOverflow) {
                
                [self updateLayer];
            }
            
            [CATransaction begin];
            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
            
            rightLayer.frame = CGRectZero;
            rightLayer.contents = nil;
            rightLayer.shadowColor = NULL;
            rightLayer.shadowPath = NULL;
            
            [CATransaction commit];
             rightPage = 0;
             self.rightData = nil;
            
        } else {
            
            // Actual content is different, clear the layer
            
            [CATransaction begin];
            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
            
            leftLayer.frame = CGRectZero;
            leftLayer.contents = nil;
            leftLayer.shadowColor = NULL;
            leftLayer.shadowPath = NULL;
            
            rightLayer.frame = CGRectZero;
            rightLayer.contents = nil;
            rightLayer.shadowColor = NULL;
            rightLayer.shadowPath = NULL;
            
            [CATransaction commit];
            
            leftPage = targetLeftPage;
            rightPage = 0;
            self.rightData = nil;
            self.leftData = nil;
            
            MFDeferredThumbnailOperation * tOp = nil;
            
            tOp = [[MFDeferredThumbnailOperation alloc]init];
            [tOp setDocument:[delegate document]];
            [tOp setThumbsCacheDirectory:[delegate thumbsCacheDirectory]];
            [tOp setPage:leftPage];
            [tOp setDelegate:self];
            [tOp setSize:CGSizeMake(90, 120)];
            
            self.pendingTOpL = tOp;
            
            [self.operationCenter.operationQueueB addOperation:tOp];
            
            deferredOp = [[MFDeferredPageOperation alloc]init];
            deferredOp.page = targetLeftPage;
            deferredOp.delegate = self;
            deferredOp.document = [delegate document];
            deferredOp.sharedData = [delegate operationsSharedData];
            deferredOp.settings = [delegate settings];
            
            if(priority > 0) {
                [deferredOp setQueuePriority:NSOperationQueuePriorityHigh];
            } else {
                [deferredOp setQueuePriority:NSOperationQueuePriorityNormal];
            }
            
            self.pendingOperation = deferredOp;
            
            [self.operationCenter.operationQueueA addOperation:deferredOp];
            
            
#if FPK_DEBUG_FRAMES
            NSLog(@"Going to update layer with %d %d on size %@ (%d)",leftPage,rightPage,NSStringFromCGSize(size),[opId intValue]);
#endif
        }
        
        pthread_mutex_unlock(&mutex);
        
	} else if ([delegate currentMode] == MFDocumentModeDouble) {
		
        MFDeferredThumbnailOperation * tOp = nil;
        // NSDictionary * description = nil;
        
        // Left page
        
        targetLeftPage = leftPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
        
                pthread_mutex_lock(&mutex);
        
        if(self.leftData && self.leftData.data.page == targetLeftPage) {
            
            // Just update the position
            
            [self updateLeftLayer];
            
        } else  {
            
            [CATransaction begin];
            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
            
            leftLayer.contents = nil;
            leftLayer.frame = CGRectZero;
            leftLayer.shadowColor = NULL;
            leftLayer.shadowPath = NULL;
            
            [CATransaction commit];
            
            leftPage = targetLeftPage;
            self.leftData = nil;
            
            // Thumbnail
            
            tOp = [[MFDeferredThumbnailOperation alloc]init];
            [tOp setDocument:[delegate document]];
            [tOp setThumbsCacheDirectory:[delegate thumbsCacheDirectory]];
            [tOp setPage:leftPage];
            [tOp setDelegate:self];
            [tOp setSize:CGSizeMake(90, 120)];
            
            self.pendingTOpL = tOp;
            
                        [self.operationCenter.operationQueueB addOperation:tOp];
            
            // Full
            
            deferredOp = [[MFDeferredPageOperation alloc]init];
            deferredOp.page = targetLeftPage;
            deferredOp.delegate = self;
            deferredOp.document = [delegate document];
            //deferredOp.description = description;
            deferredOp.sharedData = [delegate operationsSharedData];
            
            //[self performSelectorInBackground:@selector(loadThumbnail:) withObject:[NSNumber numberWithUnsignedInt:leftPage]];
            
            if(priority > 0) {
                [deferredOp setQueuePriority:NSOperationQueuePriorityHigh];
            } else {
                [deferredOp setQueuePriority:NSOperationQueuePriorityNormal];
            }
            
            self.pendingOperation = deferredOp;
                        [self.operationCenter.operationQueueA addOperation:deferredOp];
            
        }
        
        
        // Right page
        
        targetRightPage = rightPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
        
        if(self.rightData && self.rightData.data.page == targetRightPage) {
            
            // Just update the position
            
            [self updateRightLayer];
            
        } else  {
            
            [CATransaction begin];
            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
            
            rightLayer.contents = nil;
            rightLayer.frame = CGRectZero;
            rightLayer.shadowColor = NULL;
            rightLayer.shadowPath = NULL;
            
            [CATransaction commit];
            
            rightPage = targetRightPage;
            self.rightData = nil;
            
            // Thumbnail
            
            tOp = [[MFDeferredThumbnailOperation alloc]init];
            [tOp setDocument:[delegate document]];
            [tOp setThumbsCacheDirectory:[delegate thumbsCacheDirectory]];
            [tOp setPage:rightPage];
            [tOp setDelegate:self];
            [tOp setSize:CGSizeMake(90, 120)];
            
            self.pendingTOpR = tOp;
            
            [self.operationCenter.operationQueueB addOperation:tOp];

            // Full
            
            deferredOp = [[MFDeferredPageOperation alloc]init];
            deferredOp.page = targetRightPage;
            deferredOp.delegate = self;
            deferredOp.document = [delegate document];
            //deferredOp.description = description;
            deferredOp.sharedData = [delegate operationsSharedData];
            
            //[self performSelectorInBackground:@selector(loadThumbnail:) withObject:[NSNumber numberWithUnsignedInt:rightPage]];
            
            if(priority > 0) {
                [deferredOp setQueuePriority:NSOperationQueuePriorityHigh];
            } else {
                [deferredOp setQueuePriority:NSOperationQueuePriorityNormal];
            }
            
            self.pendingOperationExtra = deferredOp;
                        [self.operationCenter.operationQueueA addOperation:deferredOp];
            
        }
        
        pthread_mutex_unlock(&mutex);
        
	} else {
		
#if DEBUG
		NSLog(@"%@ : Unknow page mode",NSStringFromClass([self class]));
#endif
        
        pthread_mutex_lock(&mutex);

        self.leftData = nil;
        self.rightData = nil;
        
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        leftLayer.contents = nil;
        leftLayer.frame = CGRectZero;
        leftLayer.shadowColor = NULL;
        leftLayer.shadowPath = NULL;
        rightLayer.contents = nil;
        rightLayer.frame = CGRectZero;
        rightLayer.shadowColor = NULL;
        rightLayer.shadowPath = NULL;
        
        [CATransaction commit];
        
        pthread_mutex_unlock(&mutex);
	}
    
}


-(void)updateWithContentInfo:(NSDictionary *)i {
    
    static NSInteger sharedOperationId;

    NSDictionary * info = i;
    
    CGSize size = [[info valueForKey:FPK_KEY_RENDERINFO_SIZE] CGSizeValue];
    NSUInteger priority = [[info valueForKey:FPK_KEY_RENDERINFO_PRIORITY] unsignedIntValue];
    
    [pendingOperation cancel]; // If there's one, operation will be cancelled
	[self setPendingOperation:nil];
	
	[layer setContents:nil]; // Clean up the layer...
	
	NSInteger leftPageNumber;
	NSInteger rightPageNumber;
	MFDeferredRenderOperation * deferredOp = nil;
    operationId = sharedOperationId++;
    NSNumber * opId = [NSNumber numberWithInteger:operationId];
    
	if([delegate currentMode] == MFDocumentModeSingle || [delegate currentMode] == MFDocumentModeOverflow) {
		
		leftPageNumber = leftPageForPosition(position, MFDocumentModeSingle, [delegate currentLead], [delegate currentDirection], [[delegate document]numberOfPages]);
        rightPageNumber = 0;
        
        MFPageDataOldEngine * tmpData = [[MFPageDataOldEngine alloc]init];
        tmpData.mode = [delegate currentMode];
        tmpData.left = leftPageNumber;
        tmpData.right = rightPageNumber;
        tmpData.legacy = self.settings.legacyModeEnabled;
        tmpData.shadow = [settings showShadow];
        tmpData.padding = [delegate padding];
        tmpData.size = size;
        tmpData.operationId = opId;
        
        if(![tmpData isEqualToPageData:self.data]) {
            
            deferredOp = [[MFDeferredRenderOperation alloc]initWithTarget:self leftPage:leftPageNumber rightPage:0 document:[delegate document] imagSize:size operationNumber:opId];
            deferredOp.legacy = self.settings.legacyModeEnabled;
            deferredOp.mode = MFDeferredRenderModePageSingle;
            deferredOp.showShadow = [settings showShadow];
            deferredOp.padding = [delegate padding];
            deferredOp.data = tmpData;
        }
        
        
        
#if FPK_DEBUG_FRAMES
        NSLog(@"Going to update layer with %d %d on size %@ (%d)",leftPage,rightPage,NSStringFromCGSize(size),[opId intValue]);
#endif
        
	} else if ([delegate currentMode] == MFDocumentModeDouble) {
		
		leftPageNumber = leftPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
		
		rightPageNumber = rightPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
		
        MFPageDataOldEngine * tmpData = [[MFPageDataOldEngine alloc]init];
        tmpData.mode = [delegate currentMode];
        tmpData.left = leftPageNumber;
        tmpData.right = rightPageNumber;
        tmpData.legacy = self.settings.legacyModeEnabled;
        tmpData.shadow = [settings showShadow];
        tmpData.padding = [delegate padding];
        tmpData.size = size;
        tmpData.operationId = opId;
        
        if(![tmpData isEqualToPageData:self.data]) {
            
            deferredOp = [[MFDeferredRenderOperation alloc]initWithTarget:self leftPage:leftPageNumber rightPage:rightPageNumber document:[delegate document] imagSize:size operationNumber:opId];
            deferredOp.legacy = self.settings.legacyModeEnabled;
            deferredOp.mode = MFDeferredRenderModePageDouble;
            deferredOp.showShadow = [settings showShadow];
            deferredOp.padding = [delegate padding];
            deferredOp.data = tmpData;
        }
        
	} else {
		
#if DEBUG
		NSLog(@"%@ : Unknow page mode",NSStringFromClass([self class]));
#endif
		
	}
    
    if(deferredOp) {
        
        if(priority > 0) {
            [deferredOp setQueuePriority:NSOperationQueuePriorityHigh];
        } else {
            [deferredOp setQueuePriority:NSOperationQueuePriorityNormal];
        }
        
        [self setPendingDataName:opId];
        [self setPendingOperation:deferredOp];
        [self.operationCenter.operationQueueA addOperation:deferredOp];
    }
    
}

-(void)updateWithContentOfSizeNew:(NSValue *)sizeValue {
	
    
	CGSize size = [sizeValue CGSizeValue];
	
	[pendingOperation cancel]; // If there's one, operation will be cancelled
	[self setPendingOperation:nil];
	
	[layer setContents:nil]; // Clean up the layer...
	
	NSInteger lPage;
	NSInteger rPage;
	MFDeferredRenderOperation * deferredOp = nil;
	NSNumber * opId = [NSNumber numberWithInteger:operationId++];
	
	if([delegate currentMode] == MFDocumentModeSingle || [delegate currentMode] == MFDocumentModeOverflow) {
		
		lPage = leftPageForPosition(position, MFDocumentModeSingle, [delegate currentLead], [delegate currentDirection], [[delegate document]numberOfPages]);
		
		deferredOp = [[MFDeferredRenderOperation alloc]initWithTarget:self leftPage:lPage rightPage:0 document:[delegate document] imagSize:size operationNumber:opId];
		deferredOp.legacy = self.settings.legacyModeEnabled;;
		deferredOp.mode = MFDeferredRenderModePageSingle;
		
#if FPK_DEBUG_FRAMES
        NSLog(@"Going to update layer with %d %d on size %@",leftPage,rightPage,NSStringFromCGSize(size));
#endif
        
	} else if ([delegate currentMode] == MFDocumentModeDouble) {
		
		lPage = leftPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
		
		rPage = rightPageForPosition(position, [delegate currentMode], [delegate currentLead], [delegate currentDirection],[[delegate document]numberOfPages]);
		
		deferredOp = [[MFDeferredRenderOperation alloc]initWithTarget:self leftPage:lPage rightPage:rPage document:[delegate document] imagSize:size operationNumber:opId];
		deferredOp.legacy = self.settings.legacyModeEnabled;
		deferredOp.mode = MFDeferredRenderModePageDouble;
        
		
	} else {
		
#if DEBUG
		NSLog(@"%@ : Unknow page mode",NSStringFromClass([self class]));
#endif
		
	}
    
    if(deferredOp) {
        
        deferredOp.showShadow = [settings showShadow];
        deferredOp.padding = [delegate padding];
        
        [self setPendingDataName:opId];
        [self setPendingOperation:deferredOp];
        [self.operationCenter.operationQueueA addOperation:deferredOp];
    }
}

-(id)init {
    self = [super init];
    if(self) {
        
        pthread_mutexattr_t attributes;
        pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&mutex, &attributes);
        pthread_mutexattr_destroy(&attributes);
        
    }
    return self;
}

-(void)dealloc {
	
	
#if FPK_DEALLOC	
	NSLog(@"%@ - dealloc",NSStringFromClass([self class]));
#endif
    
	delegate = nil;
    
    [pendingOperation cancel];
    
    [pendingOperationExtra cancel];
    
    [pendingTOpL cancel];
    
    [pendingTOpR cancel];
    
    pthread_mutex_destroy(&mutex);
	
}

@end
