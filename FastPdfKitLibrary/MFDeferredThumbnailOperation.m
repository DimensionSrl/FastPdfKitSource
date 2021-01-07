//
//  MFDeferredThumbnailOperation.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFDeferredThumbnailOperation.h"
#import <UIKit/UIKit.h>
#import "FPKPageRenderingData.h"
#import "MFDocumentManager_private.h"
#import "NSData+Crypto.h"
#import "FPKBaseDocumentViewController_private.h"

@implementation MFDeferredThumbnailOperation

@synthesize size, document, page;
@synthesize delegate;
@synthesize thumbsCacheDirectory;
@synthesize sharedData;

+(NSString *)thumbnailNameForPage:(NSUInteger)page {
    return [NSString stringWithFormat:@"thumb_%lu.thumb",(unsigned long)page];
}

+(NSString *)thumbnailImagePathForPage:(NSUInteger)page cacheFolderPath:(NSString *)documentId {
    
    NSString * tmbName = [[self class]thumbnailNameForPage:page];
    
    return [documentId stringByAppendingPathComponent:tmbName];
}

-(NSString *)thumbsCacheDirectory {
    
    if(!thumbsCacheDirectory) {
        
        self.thumbsCacheDirectory = [[delegate delegate]thumbsCacheDirectory];
    }
    
    return thumbsCacheDirectory;
}

-(void)main {
    
    if([self isCancelled])
        return;
    
    @autoreleasepool {
        
        FPKPageMetrics * metrics = [document pageMetricsForPage:page];
        
        if([self isCancelled])
            return;
        
        NSString * fallbackThumbPath = [[self class]thumbnailImagePathForPage:page cacheFolderPath:self.thumbsCacheDirectory];
        
        NSFileManager * fileManager = [[NSFileManager alloc]init];
        
        if([fileManager fileExistsAtPath:fallbackThumbPath])
        {
            NSData * data = nil;
            CGDataProviderRef provider = NULL;
            data = [[NSData alloc]initWithContentsOfFile:fallbackThumbPath options:NSDataReadingMappedIfSafe error:NULL];
            
            if(self.sharedData.password) {
                
                NSData * decryptedData = nil;
                if(self.sharedData.algorithm == FPKEncryptionAlgorithmAES) {
                    
                    decryptedData = [NSData decryptedDataForData:data password:self.sharedData.key iv:nil error:NULL];
                    
                }
                else if(self.sharedData.algorithm == FPKEncryptionAlgorithmRC4){
                    
                    decryptedData = [NSData RC4DataForData:data password:self.sharedData.key error:NULL];
                    
                }
                
                provider = CGDataProviderCreateWithCFData((CFDataRef)decryptedData);
                
            }
            else {
                
                provider = CGDataProviderCreateWithCFData((CFDataRef)data);
                
            }
            
            CGImageRef fallbackThumbSrcImage = CGImageCreateWithJPEGDataProvider(provider, NULL, YES, kCGRenderingIntentDefault);
            CGDataProviderRelease(provider);
            
            CGFloat height = CGImageGetHeight(fallbackThumbSrcImage);
            CGFloat width = CGImageGetWidth(fallbackThumbSrcImage);
            UIImage * fallbackThumbFinalImage = nil;
            
            if(height > 0 && width > 0)
            {
                UIGraphicsBeginImageContext(CGSizeMake(width, height));
                
                CGContextRef ctx = UIGraphicsGetCurrentContext();
                
                CGContextTranslateCTM(ctx, 0, (CGImageGetHeight(fallbackThumbSrcImage)));
                CGContextScaleCTM(ctx, 1, -1);
                
                CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), fallbackThumbSrcImage);
                
                CGImageRef fallbackThumbDstImage = CGBitmapContextCreateImage(ctx);
                
                UIGraphicsEndImageContext();
                
                fallbackThumbFinalImage = [[UIImage alloc]initWithCGImage:fallbackThumbDstImage];
                
                CGImageRelease(fallbackThumbDstImage);
                CGImageRelease(fallbackThumbSrcImage);
            }
            
            FPKPageRenderingData * fallbackThumbdata = [FPKPageRenderingData dataWithPage:page metrics:metrics];
            fallbackThumbdata.thumb = YES;
            [fallbackThumbdata setUi_image:fallbackThumbFinalImage]; // could be nil

            if(![self isCancelled]) {
                
                [delegate handlePageData:fallbackThumbdata];
            }
        }
    }
}


@end
