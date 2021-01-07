//
//  FPKImageUtils.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import "FPKImageUtils.h"
#import "NSData+Crypto.h"
#import "FPKImageUtils.h"
#import <QuartzCore/QuartzCore.h>

@implementation FPKImageUtils

/**
 * This will load a plain PNG file located at path.
 */
+(CGImageRef)newPNGImageWithContentsOfFile:(NSString *)path {
    
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    return [self newPNGImageWidthData:data];
}

/**
 * This will load a plain JPEG file located at path.
 */
+(CGImageRef)newJPEGImageWithContentsOfFile:(NSString *)path {
    
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    return [self newJPEGImageWithData:data];
}

/**
 * This will load in memory a new PNG image stored in data.
 */
+(CGImageRef)newPNGImageWidthData:(NSData *)data {
    
    if(data.length > 0) {
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
        CGImageRef img = CGImageCreateWithPNGDataProvider(provider, NULL, YES, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        return img;
    }
    return nil;
}

/**
 * This will load in memory a new JPEG image stored in data.
 */
+(CGImageRef)newJPEGImageWithData:(NSData *)data {
    
    if(data.length > 0) {
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
        CGImageRef img = CGImageCreateWithJPEGDataProvider(provider, NULL, YES, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        return img;
    }
    return nil;
}

+(CGImageRef)newPNGImageWithContentsOfAESEncryptedFile:(NSString *)path key:(NSData *)key iv:(NSData *)iv {
    
    NSData * data = [FPKImageUtils loadAESEncryptedDataAtPath:path key:key iv:iv];
    
    return [self newPNGImageWidthData:data];
}

+(CGImageRef)newJPEGImageWithContentsOfAESEncryptedFile:(NSString *)path key:(NSData *)key iv:(NSData *)iv {
    NSData * data = [FPKImageUtils loadAESEncryptedDataAtPath:path key:key iv:iv];
    return [self newJPEGImageWithData:data];
}


+(CGImageRef)newPNGImageWithContentsOfRC4EncryptedFile:(NSString *)path key:(NSData *)key {
    
    NSData * data = [self loadRC4EncryptedDataAtPath:path key:key];
    
    return [self newPNGImageWidthData:data];
}

+(CGImageRef)newJPEGImageWithContentOfRC4EncryptedFile:(NSString *)path key:(NSData *)key {
    NSData * data = [self loadRC4EncryptedDataAtPath:path key:key];
    return [self newJPEGImageWithData:data];
}

+(NSData *)loadRC4EncryptedDataAtPath:(NSString *)path key:(NSData *)key {
    
    NSError __autoreleasing * error = nil;
    NSData * plainData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
    
    if(!plainData) {
        return nil;
    }
    
    NSData * decryptedData = [NSData RC4DataForData:plainData password:key error:&error];
    
    return decryptedData;
}

+(NSData *)loadAESEncryptedDataAtPath:(NSString *)path key:(NSData *)key iv:(NSData *)iv {
    
    NSError __autoreleasing * error = nil;
    NSData * plainData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
    
    if(!plainData) {
        return nil;
    }
    
    NSData * decryptedData = [NSData decryptedDataForData:plainData password:key iv:iv error:&error];
    
    return decryptedData;
}

+(UIImage *)newImageWithCGImage2:(CGImageRef)imageRef {
    
    return [self newImageWithCGImage:imageRef];
    
    /*
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = CGRectMake(0,0,imageSize.width,imageSize.height);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // kCGImageAlphaNone with RGB is not supported (see https://developer.apple.com/library/mac/#qa/qa1037/_index.html )
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage * image = [[UIImage alloc]initWithCGImage:decompressedImageRef];
    
    CGImageRelease(decompressedImageRef);
    
    return image;
     */
}

+(UIImage *)newImageWithCGImage:(CGImageRef)tmpImg {
    
    UIImage * result = nil;
    if(tmpImg && (CGImageGetWidth(tmpImg) > 0) &&  (CGImageGetHeight(tmpImg) > 0))
    {
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGImageGetWidth(tmpImg), CGImageGetHeight(tmpImg)), YES, [[UIScreen mainScreen]scale]);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(ctx, 0, (CGImageGetHeight(tmpImg)));
        CGContextScaleCTM(ctx, 1, -1);
        
        CGContextDrawImage(ctx, CGRectMake(0, 0, CGImageGetWidth(tmpImg), CGImageGetHeight(tmpImg)), tmpImg);
        
        CGImageRef img = CGBitmapContextCreateImage(ctx);
        
        UIGraphicsEndImageContext();
        
        result = [[UIImage alloc]initWithCGImage:img scale:[[UIScreen mainScreen]scale] orientation:UIImageOrientationUp];
        
        CGImageRelease(img);
    }
    return result;
}


@end
