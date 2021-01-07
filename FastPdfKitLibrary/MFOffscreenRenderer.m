    //
//  MFOffscreenRenderer.m
//  PDFReaderHD
//
//  Created by Nicolò Tosi on 4/15/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFOffscreenRenderer.h"
#import "MFDocumentManager_private.h"
#import "PrivateStuff.h"
#import <pthread.h>

@interface MFOffscreenRenderer() {
    
    pthread_mutex_t mutex;
    pthread_cond_t condition;
    CGContextRef contextes[2];
    NSInteger contextIndices[2];
    NSUInteger waitingQueue;
    CGSize contextSizes[2];
}

 

@end

@implementation MFOffscreenRenderer

//static uint64_t timeSum = 0;
//static uint16_t timeCount = 0;

@synthesize dataSource;


-(NSInteger)lockAvailableContext {
    
    NSInteger index = -1;
    
    pthread_mutex_lock(&mutex);
    
    while(contextIndices[0] && contextIndices[1]) {
        waitingQueue++;
        pthread_cond_wait(&condition, &mutex);
        waitingQueue--;
    }
    
    if(!contextIndices[0]) {
        contextIndices[0] = 1;
        index = 0;
    } else if (!contextIndices[1]) {
        contextIndices[1] = 1;
        index = 1;
    }

    pthread_mutex_unlock(&mutex);
    
    return index;
}

-(void)unlockContext:(NSInteger)index {
    
    pthread_mutex_lock(&mutex);
    
    if(index >= 0 && index < 2) {
        
        if(contextIndices[index] == 1) {
            contextIndices[index] = 0;
        }
    }
    
    if(waitingQueue > 0) 
        pthread_cond_broadcast(&condition);
    
    pthread_mutex_unlock(&mutex);
    
}

-(void)releaseContextes {
    
    pthread_mutex_lock(&mutex);
    
    int index;
    for(index = 0; index < 2; index++) {
        CGContextRelease(contextes[index]),contextes[index] = NULL;
        contextSizes[index] = CGSizeZero;
    }
    
    pthread_mutex_unlock(&mutex);
}

BOOL FPKIsContextBigEnough(CGSize contextSize, CGSize contentSize) {
    
    if(contentSize.width > contextSize.width || contentSize.height > contextSize.height)
        return NO;
    
    return YES;
}

#pragma mark CGBitmapContext lifecycle

CGContextRef createBitmapContext(NSUInteger aWidth, NSUInteger anHeight) {
	
	// MOVED to the caller
	// CGFloat scale = [[UIScreen mainScreen]scale];
	
	size_t width = aWidth;
	size_t height = anHeight;
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = ((width * 4) + 0x0000000F) & ~0x0000000F; // 16 byte aligned is good
	
	//size_t dataSize = bytesPerRow * height;
	//void* data = calloc(1, dataSize);
	
	void * data = NULL;
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	CGContextRef bitmapContext = CGBitmapContextCreate(data, width, height, bitsPerComponent,
													   bytesPerRow, colorspace, 
													   kCGImageAlphaPremultipliedLast);
	
	CGColorSpaceRelease(colorspace);
	
	CGContextClearRect(bitmapContext, CGRectMake(0, 0, width, height));
	
	return bitmapContext;
}

void disposeBitmapContext(CGContextRef bitmapContext){
	
	//void * data = CGBitmapContextGetData(bitmapContext);
	CGContextRelease(bitmapContext);
	//free(data);	
	
}

-(void)tearDown {

	[self releaseContextes];
}


#pragma mark -
#pragma mark Rendering

-(CGImageRef)createImageWithImage:(CGImageRef)imageToBeDrawn {
    
    CGFloat width = CGImageGetWidth(imageToBeDrawn);
    CGFloat height = CGImageGetHeight(imageToBeDrawn);
    
    CGRect imageRect = CGRectMake(0, 0, width, height);
    CGImageRef image = NULL;
    
    CGSize pixelSize = imageRect.size;
    BOOL cropRequired = NO;
    
    NSInteger contextIndex = [self lockAvailableContext];
    
	if(invalid) {
		
        [self unlockContext:contextIndex];
		return NULL;
	}	
    
    
	if(!CGSizeEqualToSize(pixelSize, contextSizes[contextIndex])) {
		
        if(FPKIsContextBigEnough(contextSizes[contextIndex], pixelSize)) {
            
            cropRequired = YES;
            
        } else {
            
            if(contextes[contextIndex]!= NULL){
                disposeBitmapContext(contextes[contextIndex]);
            }
            
            contextes[contextIndex] = createBitmapContext(pixelSize.width,pixelSize.height); // Removed scale here.
            
            contextSizes[contextIndex] = pixelSize;
            cropRequired = NO;
        }
        
	} else {
        
        cropRequired = NO;
    }
    
    CGContextRef ctx = contextes[contextIndex];
    CGSize contextSize = contextSizes[contextIndex];
    //NSLog(@"On contex %d", contextIndex);
    CGContextDrawImage(ctx, imageRect, imageToBeDrawn);
    
    
    if(cropRequired) {
        
        CGImageRef tmpImage = CGBitmapContextCreateImage(ctx);
        image = CGImageCreateWithImageInRect(tmpImage, CGRectMake(0, contextSize.height-pixelSize.height, pixelSize.width, pixelSize.height));
        CGImageRelease(tmpImage);
        
        // NSLog(@"Cropping image %@",NSStringFromCGRect(CGRectMake(0, contextSize.height-pixelSize.height, pixelSize.width, pixelSize.height)));
        
    } else {
        
        image = CGBitmapContextCreateImage(ctx);
    }
    
    // NSLog(@"Image %ld x %ld", CGImageGetWidth(imageToBeDrawn), CGImageGetHeight(imageToBeDrawn));
    
    [self unlockContext:contextIndex];
    
    return image;	
}


-(CGImageRef)createImageWithPage:(NSUInteger)pageNr pixelScale:(CGFloat)pixelScale imageScale:(NSUInteger)scaling screenDimension:(CGFloat)dimension {
    
    CGImageRef image = NULL;
	BOOL cropRequired = NO;
    
    CGSize pixelSize = CGSizeZero;
    
    CGRect cropBox;
	int rotationAngleDegs;
   
    CGContextRef ctx = NULL;
	CGRect clipBox = CGRectZero;
    
    [dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:pageNr withBuffer:YES];
    
    // Round up the cropbox
    cropBox.size = CGSizeMake(fabs(cropBox.size.width), fabs(cropBox.size.height));
    cropBox.origin = CGPointMake(fabs(cropBox.origin.x), fabs(cropBox.origin.y));
    
    // Calculate 'optimal' image size
    CGFloat contentScale = (roundf((dimension*10.0)/(fminf(cropBox.size.width, cropBox.size.height)*10.0)));
    CGFloat vScale, hScale;
    
    vScale = hScale = 1.0;
    
    if(scaling == 0) {  // 1.0
        
        vScale = 1.0;
        hScale = 1.0;
        
    } else if (scaling == 1) { // Equal to pixel scale
        
        vScale = pixelScale;
        hScale = pixelScale;
        
    } else if (scaling == 2) { // Anamorphic
        
        vScale = pixelScale;
        hScale = 1.0;
    }
    
    vScale*=contentScale;
    hScale*=contentScale;
    
    pixelSize = CGSizeApplyAffineTransform(cropBox.size, CGAffineTransformMakeScale(hScale, vScale));
    
    NSInteger contextIndex = [self lockAvailableContext];
    
	if(invalid) {
		
        [self unlockContext:contextIndex];
		return NULL;
	}	
    
    
	if(!CGSizeEqualToSize(pixelSize, contextSizes[contextIndex])) {
		
        if(FPKIsContextBigEnough(contextSizes[contextIndex], pixelSize)) {
            
            cropRequired = YES;
            
        } else {
            
            if(contextes[contextIndex]!= NULL){
                disposeBitmapContext(contextes[contextIndex]);
            }
            
            contextes[contextIndex] = createBitmapContext(pixelSize.width,pixelSize.height); // Removed scale here.
            
            contextSizes[contextIndex] = pixelSize;
            cropRequired = NO;
        }
        
	} else {
        
        cropRequired = NO;
    }
	
	ctx = contextes[contextIndex];
	CGSize contextSize = contextSizes[contextIndex];
    
	CGContextSaveGState(ctx);
    
	clipBox = CGContextGetClipBoundingBox(ctx);
    
	//CGContextClearRect(ctx, clipBox); // No need?
    
    CGContextScaleCTM(ctx, hScale, vScale); // We are now in the scaled coordinate system
	
    CGContextSaveGState(ctx);
        
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, cropBox.size.width, cropBox.size.height));
        
    CGContextRestoreGState(ctx);
    
    CGContextClipToRect(ctx, CGRectMake(0, 0, cropBox.size.width, cropBox.size.height));
    // CGContextConcatCTM(ctx, pageTransfrom);
    
    CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
    
    [dataSource drawPageNumber:pageNr onContext:ctx];
    	
	CGContextRestoreGState(ctx);
	
    if(cropRequired) {
        
        CGImageRef tmpImage = CGBitmapContextCreateImage(ctx);
        image = CGImageCreateWithImageInRect(tmpImage, CGRectMake(0, contextSize.height-pixelSize.height, pixelSize.width, pixelSize.height));
        CGImageRelease(tmpImage);
        
        // NSLog(@"Cropping image %@",NSStringFromCGRect(CGRectMake(0, contextSize.height-pixelSize.height, pixelSize.width, pixelSize.height)));
        
	} else {
        
        image = CGBitmapContextCreateImage(ctx);
    }
    
    //NSLog(@"Image %ld x %ld", CGImageGetWidth(image), CGImageGetHeight(image));
    
    [self unlockContext:contextIndex];
    
	return image;	
}

-(CGImageRef)createImageForThumbnailPage:(NSUInteger)page size:(CGSize)size scale:(CGFloat)scale {
    
    UIGraphicsBeginImageContextWithOptions(size, YES, scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -size.height);
    
    CGRect cropBox;
    int rotationAngleDegs;
    float rotationAngleRads;
    CGSize rotatedCropBoxSize;
    
    [dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:page];
    
    // PDF document uses left hand rule, cgcontext right hand rule...
    rotationAngleDegs = normalize_angle(-rotationAngleDegs);
    
    // ... and takes radians not degrees
    rotationAngleRads = degreesToRadians(rotationAngleDegs);
    
    // Cropbox size is always the same, but the proportions are inverted if the rotation
    // is 90 or 270 deg
    if(rotationAngleDegs == 90 || rotationAngleDegs == 270) {
        rotatedCropBoxSize = CGSizeMake(cropBox.size.height, cropBox.size.width);
    } else {
        rotatedCropBoxSize = cropBox.size;
    }
    
    // Calculate page/layer ratio
    CGFloat hRatio = (size.width)/rotatedCropBoxSize.width;
    CGFloat vRatio = (size.height)/rotatedCropBoxSize.height;
    CGFloat minRatio = fmin(hRatio, vRatio);
    
    CGSize scaledCropBoxSize = rotatedCropBoxSize;
    scaledCropBoxSize.width = ceilf(scaledCropBoxSize.width * minRatio);
    scaledCropBoxSize.height = ceilf(scaledCropBoxSize.height * minRatio);
    
    CGRect scaledCropBox = CGRectZero;
    scaledCropBox.size = scaledCropBoxSize;
    
    CGContextSaveGState(ctx);
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, scaledCropBox);
    CGContextRestoreGState(ctx);
    
    CGContextScaleCTM(ctx, minRatio, minRatio);
    
    if(rotationAngleDegs == 0) {
        
        // Don't do anything (but will break the if/else sequence early in 99% of the cases)
        
    } else if(rotationAngleDegs == 90) {
        
        CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, 0);
        
    } else if (rotationAngleDegs == 180) {
        
        CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, rotatedCropBoxSize.height);
        
    } else if (rotationAngleDegs == 270) {
        
        CGContextTranslateCTM(ctx, 0, rotatedCropBoxSize.height);
    }
    
    CGContextRotateCTM(ctx, rotationAngleRads);
    
    CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
    
    [dataSource drawPageNumber:page onContext:ctx];
    
    CGImageRef fullImage = CGBitmapContextCreateImage(ctx); // Pixel space dimension

    CGSize pixelSpaceCropbox = CGSizeApplyAffineTransform(scaledCropBoxSize, CGAffineTransformMakeScale(scale, scale));
    CGSize pixelSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
    
    CGImageRef image = CGImageCreateWithImageInRect(fullImage, CGRectMake(0, pixelSize.height - pixelSpaceCropbox.height, pixelSpaceCropbox.width, pixelSpaceCropbox.height));
    
    CGImageRelease(fullImage);
    
    UIGraphicsEndImageContext();
    
    return image;
}

-(CGImageRef)createImageForThumbnailOfPageNumber:(NSUInteger)pageNr ofSize:(CGSize)size andScale:(CGFloat)scale {
	
    return [self createImageForThumbnailPage:pageNr size:size scale:scale];
    
    
//	CGImageRef image = NULL;
//	
//	[scratchpadLock lock];
//	
//	if(invalid) {
//		
//		[scratchpadLock unlock];
//		return NULL;
//	}
//    
//    CGSize actualSize = size;
//    actualSize.width*=scale;
//    actualSize.height*=scale;
//	
//	if(!CGSizeEqualToSize(actualSize, scratchpadSize)) {
//		
//		if(scratchpadCtx!=NULL){
//			disposeBitmapContext(scratchpadCtx);
//		}
//		
//		scratchpadCtx = createBitmapContext(actualSize.width, actualSize.height);
//		scratchpadSize = actualSize;
//	}
//	
//	
//	CGContextRef ctx = scratchpadCtx;
//	
//	CGContextSaveGState(ctx);
//	
//	CGRect clipbox = CGContextGetClipBoundingBox(ctx);
//	//CGContextClearRect(ctx, clipbox);
//	
//	//CGContextScaleCTM(ctx, scale, scale);
//	
//	CGRect cropBox;
//	int rotationAngleDegs;
//	float rotationAngleRads;
//	CGSize rotatedCropBoxSize;
//	
//	[dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:pageNr];
//	
//	// PDF document uses left hand rule, cgcontext right hand rule...
//	rotationAngleDegs = normalize_angle(-rotationAngleDegs);
//	
//	// ... and takes radians not degrees
//	rotationAngleRads = degreesToRadians(rotationAngleDegs);
//	
//	// Cropbox size is always the same, but the proportions are inverted if the rotation
//	// is 90 or 270 deg
//	if(rotationAngleDegs == 90 || rotationAngleDegs == 270) {
//		rotatedCropBoxSize = CGSizeMake(cropBox.size.height, cropBox.size.width);
//	} else {
//		rotatedCropBoxSize = cropBox.size;
//	}
//	
//	// Calculate page/layer ratio
//	CGFloat hRatio = (scratchpadSize.width)/rotatedCropBoxSize.width;
//	CGFloat vRatio = (scratchpadSize.height)/rotatedCropBoxSize.height;
//	CGFloat minRatio = fmin(hRatio, vRatio);
//	
//	CGSize scaledCropBoxSize = rotatedCropBoxSize;
//	scaledCropBoxSize.width = ceilf(scaledCropBoxSize.width * minRatio);
//	scaledCropBoxSize.height = ceilf(scaledCropBoxSize.height * minRatio);
//	
//	CGRect scaledCropBox = CGRectZero;
//	scaledCropBox.size = scaledCropBoxSize;
//	
//	CGContextSaveGState(ctx);
//	CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
//	CGContextFillRect(ctx, scaledCropBox);
//	CGContextRestoreGState(ctx);
//	
//	CGContextScaleCTM(ctx, minRatio, minRatio);
//	
//	if(rotationAngleDegs == 0) {
//		
//		// Don't do anything (but will break the if/else sequence early in 99% of the cases)
//		
//	} else if(rotationAngleDegs == 90) {
//		
//		CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, 0);
//		
//	} else if (rotationAngleDegs == 180) {
//		
//		CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, rotatedCropBoxSize.height);
//		
//	} else if (rotationAngleDegs == 270) {
//		
//		CGContextTranslateCTM(ctx, 0, rotatedCropBoxSize.height);
//	}
//	
//	CGContextRotateCTM(ctx, rotationAngleRads);
//	
//	CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
//	
//	[dataSource drawPageNumber:pageNr onContext:ctx];
//		
//	CGContextRestoreGState(ctx);
//    
//	CGImageRef fullImage = CGBitmapContextCreateImage(ctx);
//	
//    image = CGImageCreateWithImageInRect(fullImage, CGRectMake(0, actualSize.height - scaledCropBoxSize.height, scaledCropBoxSize.width, scaledCropBoxSize.height));
//    
//    CGImageRelease(fullImage);
//    
//	[scratchpadLock unlock];
//	
//	return image;
}

-(CGImageRef)createImageFromPDFPagesLeft:(NSInteger)leftPage andRight:(NSInteger)rightPage size:(CGSize)s andScale:(CGFloat)scale useLegacy:(BOOL)legacy showShadow:(BOOL)shadow andPadding:(CGFloat)padding {
	
	CGImageRef image = NULL;
	
    CGSize transformSize = s;
    CGSize pixelSize = CGSizeApplyAffineTransform(s, CGAffineTransformMakeScale(1.0, scale));
    
    CGAffineTransform lTransform, rTransform;
    CGRect lPageFrame, rPageFrame;
    CGRect lCropbox, rCropbox;
    int lAngle, rAngle;
    
    lPageFrame = rPageFrame = CGRectZero;
    lAngle = rAngle = 0;
    
    [dataSource getCropbox:&lCropbox andRotation:&lAngle forPageNumber:leftPage];
    [dataSource getCropbox:&rCropbox andRotation:&rAngle forPageNumber:rightPage];
    
    transformAndBoxForPagesRendering(&lTransform, &rTransform, &lPageFrame, &rPageFrame, transformSize, lCropbox, rCropbox, lAngle, rAngle, padding, NO);
    
	NSInteger contextIndex = [self lockAvailableContext];
	
    //NSLog(@"Rendering on context %d",contextIndex);
    
	if(invalid) {
		
		[self unlockContext:contextIndex];
		return NULL;
	}
	
	
	if(!CGSizeEqualToSize(pixelSize, contextSizes[contextIndex])) {
		
		if(contextes[contextIndex]!=NULL){
			disposeBitmapContext(contextes[contextIndex]);
		}
		
		contextes[contextIndex] = createBitmapContext(pixelSize.width, pixelSize.height);
		contextSizes[contextIndex] = pixelSize;
	}
	
	CGContextRef ctx = contextes[contextIndex];
	__unused CGSize contextSize = contextSizes[contextIndex];
    
	CGContextSaveGState(ctx);
	
	CGRect clipbox = CGContextGetClipBoundingBox(ctx);
	
	CGContextClearRect(ctx, clipbox);
//    CGContextSetRGBFillColor(ctx, 0.0, 1.0, 0, 1.0);
//    CGContextFillRect(ctx, clipbox);

//     NSLog(@"L %@ R %@",NSStringFromCGRect(lPageFrame),NSStringFromCGRect(rPageFrame));
    
    CGContextScaleCTM(ctx, 1.0, scale);
    
    if(NO) {
        
        CGContextSaveGState(ctx);
        CGContextSetShadow(ctx,CGSizeMake(padding*0.75, -padding*0.75),padding);
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        if(leftPage!=0)
            CGContextFillRect(ctx, lPageFrame);
        if(rightPage!=0)
            CGContextFillRect(ctx, rPageFrame);
        CGContextSetShadowWithColor(ctx, CGSizeZero, 0, NULL);
        CGContextRestoreGState(ctx);
        
    } else {
        
        CGContextSaveGState(ctx);
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        if(leftPage!=0)
            CGContextFillRect(ctx, lPageFrame);
        if(rightPage!=0)
            CGContextFillRect(ctx, rPageFrame);
        CGContextRestoreGState(ctx);
    }
    
    if(!legacy) {
        
        // Left
        
        CGContextSaveGState(ctx);
        
        CGContextClipToRect(ctx, lPageFrame);
        
        CGContextConcatCTM(ctx, lTransform);
        [dataSource drawPageNumber:leftPage onContext:ctx];
        
        CGContextRestoreGState(ctx);
        
        
        // Right 
        
        CGContextSaveGState(ctx);
        
        CGContextClipToRect(ctx, rPageFrame);
        
        CGContextConcatCTM(ctx, rTransform);
        [dataSource drawPageNumber:rightPage onContext:ctx];
        
        CGContextRestoreGState(ctx);
        
    }
    
    /*
     // Get half the bounds.
     CGSize halvedContentSize = contextSize;
     halvedContentSize.width-=(padding*2);
     halvedContentSize.height-=(padding*2);
     halvedContentSize.width*=0.5;
     
     CGContextScaleCTM(ctx, scale, scale);
     CGContextTranslateCTM(ctx, padding, padding);
     
     // Left page
     CGContextSaveGState(ctx); // Push
     
     CGRect cropBox;
     int rotationAngleDegs;
     float rotationAngleRads;
     CGSize rotatedCropBoxSize;
     
     [dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:leftPage];
     
     // PDF document uses left hand rule, cgcontext right hand rule and takes radians not degrees.
     rotationAngleDegs = normalize_angle(-rotationAngleDegs);
     rotationAngleRads = degreesToRadians(rotationAngleDegs);
     
     // Cropbox size is always the same, but the proportions are inverted if the rotation
     // is 90 or 270 deg.
     if(rotationAngleDegs == 90 || rotationAngleDegs == 270) {
     rotatedCropBoxSize = CGSizeMake(cropBox.size.height, cropBox.size.width);
     } else {
     rotatedCropBoxSize = cropBox.size;
     }
     
     CGFloat hRatio = (halvedContentSize.width)/rotatedCropBoxSize.width;
     CGFloat vRatio = (halvedContentSize.height)/rotatedCropBoxSize.height;
     CGFloat minRatio = fmin(hRatio, vRatio);
     
     CGSize scaledCropBoxSize = rotatedCropBoxSize;
     scaledCropBoxSize.width=floorf(scaledCropBoxSize.width*minRatio);
     scaledCropBoxSize.height=floorf(scaledCropBoxSize.height*minRatio);
     
     CGRect scaledCropBox = CGRectZero;
     scaledCropBox.size = scaledCropBoxSize;
     
     CGFloat deltaX = ceilf((halvedContentSize.width-scaledCropBoxSize.width));
     CGFloat deltaY = ceilf((halvedContentSize.height-scaledCropBoxSize.height)*0.5);
     
     CGContextTranslateCTM(ctx, deltaX, deltaY);
     
     if(shadow) {
     CGContextSaveGState(ctx);
     CGContextSetShadow(ctx,CGSizeMake(4, -4),5);
     CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
     CGContextFillRect(ctx, scaledCropBox);
     CGContextRestoreGState(ctx);
     }
     
     if(!legacy) {
     
     CGContextClipToRect(ctx, scaledCropBox);
     
     CGContextScaleCTM(ctx, minRatio, minRatio);
     
     if(rotationAngleDegs == 0) {
     
     // Don't do anything (but will break the if/else sequence early in 99% of the cases)
     
     } else if(rotationAngleDegs == 90) {
     
     CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, 0);
     
     } else if (rotationAngleDegs == 180) {
     
     CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, rotatedCropBoxSize.height);
     
     } else if (rotationAngleDegs == 270) {
     
     CGContextTranslateCTM(ctx, 0, rotatedCropBoxSize.height);
     
     } else { // As it were 0
     // Do nothing again...
     
     }
     
     CGContextRotateCTM(ctx, rotationAngleRads);
     
     CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
     
     [dataSource drawPageNumber:leftPage onContext:ctx];
     
     } // Legacy.
     
     CGContextRestoreGState(ctx); // Pop
     
     
     // Right page.
     CGContextTranslateCTM(ctx, halvedContentSize.width, 0);
     
     CGContextSaveGState(ctx); // Push
     
     [dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:rightPage];
     
     // PDF document uses left hand rule, cgcontext right hand rule...
     rotationAngleDegs = normalize_angle(-rotationAngleDegs);
     
     // ... and takes radians not degrees
     rotationAngleRads = degreesToRadians(rotationAngleDegs);
     
     // Cropbox size is always the same, but the proportions are inverted if the rotation
     // is 90 or 270 deg
     if(rotationAngleDegs == 90 || rotationAngleDegs == 270) {
     rotatedCropBoxSize = CGSizeMake(cropBox.size.height, cropBox.size.width);
     } else {
     rotatedCropBoxSize = cropBox.size;
     }
     
     hRatio = (halvedContentSize.width)/rotatedCropBoxSize.width;
     vRatio = (halvedContentSize.height)/rotatedCropBoxSize.height;
     minRatio = fmin(hRatio, vRatio);
     
     scaledCropBoxSize = rotatedCropBoxSize;
     scaledCropBoxSize.width = floorf(scaledCropBoxSize.width*minRatio);
     scaledCropBoxSize.height = floorf(scaledCropBoxSize.height*minRatio);
     
     scaledCropBox = CGRectZero;
     scaledCropBox.size = scaledCropBoxSize;
     
     deltaX = 0;
     deltaY = ceilf((halvedContentSize.height-scaledCropBoxSize.height)*0.5);
     
     CGContextTranslateCTM(ctx, deltaX, deltaY);
     
     if(shadow) {
     CGContextSaveGState(ctx);
     CGContextSetShadow(ctx,CGSizeMake(4, -4),5);
     CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
     CGContextFillRect(ctx, scaledCropBox);
     CGContextRestoreGState(ctx);
     }
     
     if(!legacy) {
     
     CGContextClipToRect(ctx, scaledCropBox);
     
     CGContextScaleCTM(ctx, minRatio, minRatio);
     
     if(rotationAngleDegs == 0) {
     
     // Don't do anything (but will break the if/else sequence early in 99% of the cases)
     
     } else if(rotationAngleDegs == 90) {
     
     CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, 0);
     
     } else if (rotationAngleDegs == 180) {
     
     CGContextTranslateCTM(ctx, rotatedCropBoxSize.width, rotatedCropBoxSize.height);
     
     } else if (rotationAngleDegs == 270) {
     
     CGContextTranslateCTM(ctx, 0, rotatedCropBoxSize.height);
     
     } else { // As it were 0
     // Do nothing again...
     
     }
     
     CGContextRotateCTM(ctx, rotationAngleRads);
     
     CGContextTranslateCTM(ctx, -cropBox.origin.x, -cropBox.origin.y);
     
     [dataSource drawPageNumber:rightPage onContext:ctx];
     
     } // Legacy.
     
     CGContextRestoreGState(ctx); // Pop
     
     // Finalizing.
     */
    
	CGContextRestoreGState(ctx);
	
	image = CGBitmapContextCreateImage(ctx);
	
    [self unlockContext:contextIndex];
	
	return image;
}

-(CGImageRef)createImageFromPDFPage:(NSInteger)page size:(CGSize)size  andScale:(CGFloat)scale useLegacy:(BOOL)legacy showShadow:(BOOL)shadow andPadding:(CGFloat)padding {
	
	CGImageRef image = NULL;
	BOOL cropRequired = NO;
    
    CGSize transformSize = size;
    CGSize pixelSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(1.0, scale));
    
    // NSLog(@"Transform size %@ pixelSize %@",NSStringFromCGSize(transformSize),NSStringFromCGSize(pixelSize));
    
    CGRect cropBox;
	int rotationAngleDegs;
    //	float rotationAngleRads;
    //	CGSize rotatedCropBoxSize;
    
    CGContextRef ctx;
	CGRect clipBox;
    
    //  CGSize size = CGSizeApplyAffineTransform(s, CGAffineTransformMakeScale(scale, scale));
    //  CGFloat padding = p * scale;
    
	//[dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:page];
	[dataSource getCropbox:&cropBox andRotation:&rotationAngleDegs forPageNumber:page withBuffer:YES];
    // NSLog(@"%@ %@",NSStringFromCGSize(size),NSStringFromCGSize(cropBox.size));
    
    CGRect pageFrame;
    CGAffineTransform pageTransfrom;
    
    transformAndBoxForPageRendering(&pageTransfrom, &pageFrame, transformSize, cropBox, degreesToRadians(normalize_angle(-rotationAngleDegs)), padding, NO);
    
    NSInteger contextIndex = [self lockAvailableContext];
    //NSLog(@"Rendering on context %d",contextIndex);
    
	if(invalid) {
		
		[self unlockContext:contextIndex];
		return NULL;
	}	
	
	if(!CGSizeEqualToSize(pixelSize, contextSizes[contextIndex])) {
		
        //if(NO) {
        if(FPKIsContextBigEnough(contextSizes[contextIndex], pixelSize)) {
            
            cropRequired = YES;
            // NSLog(@"Crop enabled");
            
        } else {
            
            if(contextes[contextIndex]!=NULL){
                disposeBitmapContext(contextes[contextIndex]);
            }
            
            //NSLog(@"Creating context");
            
            contextes[contextIndex] = createBitmapContext(pixelSize.width, pixelSize.height); // Removed scale here.
            contextSizes[contextIndex] = pixelSize;
            cropRequired = NO;
        }
        
		
	} else {
        cropRequired = NO;
        
    }
    
    //NSLog(@"Pixel size %@", NSStringFromCGSize(pixelSize));
	
	ctx = contextes[contextIndex];
    CGSize contextSize = contextSizes[contextIndex];
	
	CGContextSaveGState(ctx);
    
	clipBox = CGContextGetClipBoundingBox(ctx);
	
    
	CGContextClearRect(ctx, clipBox);
//    CGContextSetRGBFillColor(ctx, 1.0, 0, 0, 1.0);
//    CGContextFillRect(ctx, clipBox);
    
    CGContextScaleCTM(ctx, 1.0, scale);
	
    if(NO) {
        
        CGContextSaveGState(ctx);
        
        CGContextSetShadow(ctx,CGSizeMake(padding*0.75, -padding*0.75),padding);
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(ctx, pageFrame);
        CGContextSetShadowWithColor(ctx, CGSizeZero, 0, NULL);
        
        CGContextRestoreGState(ctx);
        
    } else {
        
        CGContextSaveGState(ctx);
        
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(ctx, pageFrame);
        
        CGContextRestoreGState(ctx);
    }
    
    if(!legacy) {
        
        CGContextClipToRect(ctx, pageFrame);
        CGContextConcatCTM(ctx, pageTransfrom);
        
        [dataSource drawPageNumber:page onContext:ctx];
    }
    
	CGContextRestoreGState(ctx);
	
    if(cropRequired) 
    {
        CGImageRef tmpImage = CGBitmapContextCreateImage(ctx);
        image = CGImageCreateWithImageInRect(tmpImage, CGRectMake(0, contextSize.height-pixelSize.height, pixelSize.width, pixelSize.height));
        CGImageRelease(tmpImage);
	} 
    else 
    {
        image = CGBitmapContextCreateImage(ctx);
    }
    
	[self unlockContext:contextIndex];
    
#if DEBUG & FPK_DEBUG_RENDERTIME
    
    endTime = mach_absolute_time();
	
    elapsedTime = endTime - startTime;
    elapsedTimeNano = elapsedTime * timeBaseInfo.numer / timeBaseInfo.denom;
    
    timeCount++;
    timeSum+=elapsedTimeNano;
        
    fprintf(stdout,"tot t %llu ms for page %d\n",elapsedTimeNano/1000000,page);
    fprintf(stdout,"avg t %llu ms\n",(timeSum/timeCount)/1000000);
#endif
    
	return image;	
}


#pragma mark -
#pragma mark Lifecycle

-(id)init {
	
	if((self = [super init])) {
		
        int index;
        
        for(index = 0; index < 2; index++) {
            contextes[index] = NULL;
            contextSizes[index] = CGSizeZero;
            contextIndices[index] = 0;
        }
        
        pthread_mutex_init(&mutex, NULL);
        pthread_cond_init(&condition, NULL);
        
        scratchpadLock = [[NSRecursiveLock alloc]init];
        scratchpadSize = CGSizeZero;
	}
    
	return self;
}

	   
- (void)dealloc {
	
#if FPK_DEALLOC
	NSLog(@"%@ -dealloc",NSStringFromClass([self class]));
#endif	
	
	self.dataSource = nil;
	
	[self releaseContextes];
    
    if(scratchpadCtx!=NULL) {
        disposeBitmapContext(scratchpadCtx);
    }
	
	
}


@end
