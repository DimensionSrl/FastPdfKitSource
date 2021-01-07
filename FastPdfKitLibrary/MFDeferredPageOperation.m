//
//  MFDeferredPageOperation.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFDeferredPageOperation.h"
#import "MFDocumentManager.h"

#import "MFDocumentManager_private.h"
#import "MFDeferredContentLayerWrapper.h"
#import "NSData+Crypto.h"
#import "FPKSharedSettings.h"
#import "PrivateStuff.h"
#import "FPKImageUtils.h"
#import "fpktime.h"
#import "FPKSharedSettings_Private.h"

@interface ImageSaveInfo : NSObject
@property (nonatomic, readwrite) BOOL useJPEG;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, copy) NSString * path;
@end

@implementation ImageSaveInfo

@end

@implementation MFDeferredPageOperation

#define USE_JPEG 1

static BOOL checked = NO;
static CGFloat screenScale = 1.0;
static CGFloat screenDimension;
static NSData * cacheIV = NULL;

+(MFDeferredPageOperation *)operationWithPage:(NSUInteger)page
                                     document:(MFDocumentManager *)document
                                     delegate:(id<MFDeferredPageOperationDelegate>)delegate
{
    MFDeferredPageOperation * pageOperation = [[MFDeferredPageOperation alloc]init];
    
    pageOperation.page = page;
    pageOperation.delegate = delegate;
    pageOperation.document = document;
    pageOperation.queuePriority = FPKOperationPriorityImage;
    
    return pageOperation;
}

+(NSString *)thumbnailNameForPage:(NSUInteger)page {
    return [NSString stringWithFormat:@"thumb_%lu.thumb",(unsigned long)page];
}

+(NSString *)thumbnailImagePathForPage:(NSUInteger)page 
                       cacheFolderPath:(NSString *)documentId 
{
    NSString * tmbName = [[self class]thumbnailNameForPage:page];
    
    return [documentId stringByAppendingPathComponent:tmbName];
}

-(CGImageRef)newImageWithPage:(NSUInteger)pageNr
                      pixelScale:(CGFloat)pixelScale
                      imageScale:(FPKImageCacheScale)scaling
                 screenDimension:(CGFloat)screenDimension
                         cropbox:(CGRect)cropBox
                           angle:(CGFloat)rotationAngleDegs
{
    
    CGImageRef image = NULL;
	// BOOL cropRequired = NO;
    CGSize pixelSize = CGSizeZero;
    
    CGRect canvasRect = CGRectIntegral(cropBox);
    
    if(!(cropBox.size.width > 0.0 && cropBox.size.height > 0.0))
        return NULL;
    
    /* If 90 or 270 rotate the canvas to accomodate the rotated page that will be drawn unto it */

    if((fabs(rotationAngleDegs - M_PI_2) < FLT_EPSILON) 
       || (fabs(rotationAngleDegs - M_PI_2 * 3) < FLT_EPSILON)) 
    {
        canvasRect.size = CGSizeMake(canvasRect.size.height, canvasRect.size.width);
    }
    
//    // Why fabs instead of roundf or floorf (better)?
//    canvasRect.size.width = floorf(cropBox.size.width);
//    canvasRect.size.height = floorf(cropBox.size.height);
//    canvasRect.origin.x = floorf(cropBox.origin.x);
//    canvasRect.origin.y = floorf(cropBox.origin.y);
    
    /*
     iPad screen ratio 4/3 -> 1.333
     iPad screen ration 3/4 -> 0.75
     iPhone screen ratio 3/2 -> 1.5
     iPhone screen ration 2/3 -> 0.666
     */
    
    CGFloat oversize = 1.0 + self.settings.oversize;
    CGFloat pageDimensionBias = fmaxf(cropBox.size.width, cropBox.size.height);
    CGFloat contentScale = ((roundf((screenDimension/pageDimensionBias) * 1000.0))/1000.0) * oversize;
    
    CGFloat vScale, hScale;
    
    if(scaling == FPKImageCacheScaleStandard)
    {  // 1.0
        vScale = hScale = 1.0;
    }
    else if (scaling == FPKImageCacheScaleTrueToPixels)
    { // Equal to pixel scale
        
        vScale = hScale = pixelScale;
    }
    else if (scaling == FPKImageCacheScaleAnamorphic)
    { // Anamorphic
        
        vScale = pixelScale;
        hScale = pixelScale * 0.5;
    }
    else
    {
        vScale = hScale = 1.0;
    }
    
    vScale*=contentScale;
    hScale*=contentScale;
    
    pixelSize = CGSizeApplyAffineTransform(canvasRect.size, CGAffineTransformMakeScale(hScale, vScale));
    
    pixelSize.width = floorf(pixelSize.width);
    pixelSize.height = floorf(pixelSize.height);
    
    /* Ok, we can start drawing */
    
    UIGraphicsBeginImageContext(pixelSize);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
	CGContextSaveGState(ctx);
    
	//clipBox = CGContextGetClipBoundingBox(ctx);
    
    CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, 0, -pixelSize.height);
    
    //CGContextClearRect(ctx, clipBox); // No need?
    
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, pixelSize.width, pixelSize.height));
    
    CGContextScaleCTM(ctx, hScale, vScale); // We are now in the scaled coordinate system
	
    // CGContextConcatCTM(ctx, pageTransfrom);
    CGFloat lCenterX = 0.0;
    CGFloat lCenterY = 0.0;
    
    /* Realign frame to center */
    
    if(fabs(rotationAngleDegs) < FLT_EPSILON) // 0 deg
    {
        /* Origin is on the bottom left */
        
        lCenterX = lCenterY = 0.0;
    } 
    else if (fabs(rotationAngleDegs - M_PI_2) < FLT_EPSILON) // 90 deg
    {
        /* Origin is now on the bottom right and the new width is the old height */
        
        lCenterX = cropBox.size.height;
        lCenterY = 0.0;
    } 
    else if (fabs(rotationAngleDegs - M_PI) < FLT_EPSILON) // 180 deg
    {
        /* Origin is now on the upper left */
        
        lCenterX = cropBox.size.width;
        lCenterY = cropBox.size.height;
    } 
    else if (fabs(rotationAngleDegs - (M_PI_2 * 3)) < FLT_EPSILON) // 270 deg
    {
        /* Origin is in the top right and the new width is the old height */
        
        lCenterX = 0.0;
        lCenterY = cropBox.size.width;
    }
    
    CGContextTranslateCTM(ctx, lCenterX, lCenterY);

    CGContextRotateCTM(ctx, rotationAngleDegs);
    
    //CGContextClipToRect(ctx, CGRectMake(0, 0, cropBox.size.width, cropBox.size.height));
    
    CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
    
    [self.document drawPageNumber:pageNr onContext:ctx];
    
	CGContextRestoreGState(ctx);
	
    image = CGBitmapContextCreateImage(ctx);
    
    UIGraphicsEndImageContext();
    
	return image;	
}

-(void)saveImageToDisk:(ImageSaveInfo *)info
{    
    @autoreleasepool 
    {

        BOOL useJPEG = info.useJPEG;

        UIImage * image = info.image;
        NSString * path = info.path;
        
        NSFileManager * fileManager = [[NSFileManager alloc]init];
    
    NSData * data = nil;
    
    if(self.sharedData.password) {
        
        NSData * encryptedData = nil;
        
        if(useJPEG) {
            data = UIImageJPEGRepresentation(image, self.settings.compressionLevel);
        } else {
            data = UIImagePNGRepresentation(image);
        }
        
        NSError * error = nil;
        
        if(self.sharedData.algorithm == FPKEncryptionAlgorithmAES)
        {
            encryptedData = [NSData encryptedDataForData:data password:self.sharedData.key iv:cacheIV error:NULL];
        }
        else if(self.sharedData.algorithm == FPKEncryptionAlgorithmRC4)
        {
            encryptedData = [NSData RC4DataForData:data password:self.sharedData.key error:NULL];    
        }
        
        if(![fileManager createFileAtPath:path contents:encryptedData attributes:nil])
        {
            NSLog(@"Cannot save %@ %@",path,[error localizedDescription]);
        }
        
    } else {
        
        if(useJPEG) {
            data = UIImageJPEGRepresentation(image, self.settings.compressionLevel);
        } else {
            data = UIImagePNGRepresentation(image);
        }
        
        NSError * error = nil;
        
        if(![fileManager createFileAtPath:path contents:data attributes:nil]) {
            NSLog(@"Cannot save %@ %@",path,[error localizedDescription]);
        }

    }
        /* Cleanup */
    }
}

+(NSString *)imageCacheNameFormatForScale:(FPKImageCacheScale)scale
                                  useJPEG:(BOOL)useJPEG
{
    if(useJPEG)
    {
        if(scale == FPKImageCacheScaleStandard) {
            
            return @"%d_1_0.jpg";
            
        } else if (scale == FPKImageCacheScaleTrueToPixels) {
            
            return @"%d_t2p.jpg";          
            
        } else if (scale == FPKImageCacheScaleAnamorphic) {
            
            return @"%d_ana.jpg";
        }
    }
    else
    {
        if(scale == FPKImageCacheScaleStandard) 
        {
            return @"%d_1_0.png";
        } 
        else if (scale == FPKImageCacheScaleTrueToPixels) 
        {
            return @"%d_t2p.png";          
        } 
        else if (scale == FPKImageCacheScaleAnamorphic) 
        {
            return @"%d_ana.png";
        }
    }
    
    return nil;
}

+(void)initialize {
    
    // Initialized initialization vector for cache images
    
    unsigned char iv [] = "afc037dc031ad0ff";
    int iv_len = 16;
    
    if(!cacheIV) {
        cacheIV = [[NSData alloc]initWithBytes:iv length:iv_len];
    }
    
    if(!checked) {
        
        checked = YES;
        
        CGRect screenSize = [[UIScreen mainScreen]bounds];
        
        screenDimension = fmaxf(screenSize.size.width, screenSize.size.height);
        
        if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) 
        {
            screenScale = [[UIScreen mainScreen]scale];
            
            if(fabs(screenScale - 2.0) < FLT_EPSILON) {
                
                // iOS4+ retina
                screenScale = 2.0;
                
            } else {
                
                // iOS4+ non retina
                screenScale = 1.0;
            }
            
        } else {
            
            // Pre iOS4 non retina
            screenScale = 1.0;            
        }
        
#if DEBUG
        NSLog(@"Pixel scale on this device: %.3f", screenScale);
#endif
        
    }    
}


-(void)main
{
    @autoreleasepool
    {
        BOOL writeImageToDisk = NO;
        
        BOOL useJPEG = self.settings.useJPEG;
        FPKImageCacheScale imageScale = self.settings.cacheImageScale;
        
        if([self isCancelled] || (!_delegate) || (!_document))
        {
#if FPK_DEBUG_OPS
            NSLog(@"Ops cancelled");	
#endif
            return;
        }
        
        if(_page == 0)
        {
            FPKPageRenderingData * dummyData = [FPKPageRenderingData zeroData];
            [_delegate pageOperation:self didCompleteWithData:dummyData];
            
            return;
        }
        
        FPKPageData * data = [self.metricsCache metricsWithPage:_page];
        
        if(!data) {
            FPKPageMetrics * metrics = [_document pageMetricsForPage:_page];
            data = [FPKPageData dataWithPage:_page metrics:metrics];
            [self.metricsCache addMetrics:data];
        }
        
        if([self isCancelled])
        {
            return;
        }
        
        NSData * thumbnailData = [self.cache thumbnailDataForPage:_page];
        
        if(!thumbnailData) {
            
            thumbnailData = [self.thumbnailDataStore loadDataForPage:_page];
            
            if(thumbnailData) {
                
                if(self.sharedData.password.length > 0) {
                    
                    if(self.sharedData.algorithm == FPKEncryptionAlgorithmAES) {
                        
                        thumbnailData = [NSData decryptedDataForData:thumbnailData password:self.sharedData.key iv:cacheIV error:NULL];
                        
                    } else if (self.sharedData.algorithm == FPKEncryptionAlgorithmRC4) {
                        
                        thumbnailData= [NSData RC4DataForData:thumbnailData password:self.sharedData.key error:NULL];
                    }
                }
            }
        }
        
        if(thumbnailData) {
            
            CGImageRef img = [FPKImageUtils newJPEGImageWithData:thumbnailData];
            
            UIImage * image = [FPKImageUtils newImageWithCGImage:img];
            
            CGImageRelease(img);
            
            FPKPageRenderingData * renderingData = [FPKPageRenderingData dataWithData:data];
            renderingData.ui_image = image;
            
            if(![self isCancelled]) {
                id __weak this = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate pageOperation:this didCompleteWithData:renderingData];
                });
            } else {
                return;
            }
        }
        
        NSString * fileNameFormat = [MFDeferredPageOperation imageCacheNameFormatForScale:imageScale useJPEG:useJPEG];
        NSString * fileName = [NSString stringWithFormat:fileNameFormat, _page];
        NSString * path = [[self imagesCacheDirectory] stringByAppendingPathComponent:fileName];
        
        CGImageRef img = NULL;
        if(self.sharedData.password.length > 0) {
            
            if(self.sharedData.algorithm == FPKEncryptionAlgorithmAES) {
                
                if(useJPEG) {
                    img = [FPKImageUtils newJPEGImageWithContentsOfAESEncryptedFile:path key:self.sharedData.key iv:cacheIV];
                } else {
                    img = [FPKImageUtils newPNGImageWithContentsOfAESEncryptedFile:path key:self.sharedData.key iv:cacheIV];
                }
                
            } else if (self.sharedData.algorithm == FPKEncryptionAlgorithmRC4) {
                
                if(useJPEG) {
                    img = [FPKImageUtils newJPEGImageWithContentOfRC4EncryptedFile:path key:self.sharedData.key];
                } else {
                    img = [FPKImageUtils newPNGImageWithContentsOfRC4EncryptedFile:path key:self.sharedData.key];
                }
            }
            
        } else {
            
            if(useJPEG) {
                img = [FPKImageUtils newJPEGImageWithContentsOfFile:path];
            } else {
                img = [FPKImageUtils newPNGImageWithContentsOfFile:path];
            }
        }
        
        if([self isCancelled])
        {
            if(img) {
                CGImageRelease(img);
            }
            return;
        }

        if([self isCancelled]) {
            
            if(img) {
                CGImageRelease(img);
            }
            return;
        }
        
        UIImage * image = [FPKImageUtils newImageWithCGImage2:img];
        CGImageRelease(img);
        
        /* If at this point we don't have the image, we need to generate it */
        
        if(!image && (!self.isCancelled))
        {
            
            CGImageRef img = [self newImageWithPage:_page
                                 pixelScale:screenScale
                                 imageScale:imageScale
                            screenDimension:screenDimension
                                    cropbox:data.metrics.cropbox
                                      angle:degreesToRadians(normalize_angle(-data.metrics.angle))];
            
            if(img)
            {
                image = [[UIImage alloc]initWithCGImage:img
                                                  scale:screenScale
                                            orientation:UIImageOrientationUp];
                writeImageToDisk = YES;
                CGImageRelease(img);
            }
        }
        
        FPKPageRenderingData * renderingData = [FPKPageRenderingData dataWithData:data];
        renderingData.ui_image = image;
        
        if(![self isCancelled]) {
            id __weak this = self;
            dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate pageOperation:this didCompleteWithData:renderingData];
            });
        }
        
        if(writeImageToDisk && image)
        {
            ImageSaveInfo * info = [ImageSaveInfo new];
            info.useJPEG = self.settings.useJPEG;
            info.image = image;
            info.path = path;
            
            id __weak this = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [this saveImageToDisk:info];
            });
        }
        
#if FPK_DEBUG_OPS
        NSLog(@"Ops done");	
#endif
    }
}

-(void)dealloc
{
    self.delegate = nil;
}

@end
