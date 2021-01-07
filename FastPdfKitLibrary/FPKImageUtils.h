//
//  FPKImageUtils.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 03/12/14.
//
//

#import <Foundation/Foundation.h>

@interface FPKImageUtils : NSObject
/**
 * This will load a plain PNG file located at path.
 */
+(CGImageRef)newPNGImageWithContentsOfFile:(NSString *)path;

/**
 * This will load a plain JPEG file located at path.
 */
+(CGImageRef)newJPEGImageWithContentsOfFile:(NSString *)path;

/**
 * This will load in memory a new PNG image stored in data.
 */
+(CGImageRef)newPNGImageWidthData:(NSData *)data;
/**
 * This will load in memory a new JPEG image stored in data.
 */
+(CGImageRef)newJPEGImageWithData:(NSData *)data;

/**
 * Attempt to load a PNG image from an AES encrypted file at a specified path.
 * @path NSString absolute path.
 * @key NSData with AES key.
 * @iv NSData with AES initialization vector.
 */
+(CGImageRef)newPNGImageWithContentsOfAESEncryptedFile:(NSString *)path key:(NSData *)key iv:(NSData *)iv;

+(CGImageRef)newJPEGImageWithContentsOfAESEncryptedFile:(NSString *)path key:(NSData *)key iv:(NSData *)iv;

+(CGImageRef)newPNGImageWithContentsOfRC4EncryptedFile:(NSString *)path key:(NSData *)key;

+(CGImageRef)newJPEGImageWithContentOfRC4EncryptedFile:(NSString *)path key:(NSData *)key;

+(NSData *)loadRC4EncryptedDataAtPath:(NSString *)path key:(NSData *)key;

+(NSData *)loadAESEncryptedDataAtPath:(NSString *)path key:(NSData *)key iv:(NSData *)iv;

+(UIImage *)newImageWithCGImage:(CGImageRef)tmpImg;

+(UIImage *)newImageWithCGImage2:(CGImageRef)imageRef;

@end
