//
//  NSData+NSData_Crypto.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/31/12.
//
//

#import "NSData+Crypto.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@implementation NSData (Crypto)

NSString * const kRNCryptManagerErrorDomain = @"com.mobfarm.fastpdfkit";

const CCAlgorithm kAlgorithm = kCCAlgorithmAES128;
const NSUInteger kAlgorithmKeySize = kCCKeySizeAES128;
const NSUInteger kAlgorithmBlockSize = kCCBlockSizeAES128;
const NSUInteger kAlgorithmIVSize = kCCBlockSizeAES128;
//const NSUInteger kPBKDFSaltSize = 8;
const NSUInteger kPBKDFRounds = 10000;  // ~80ms on an iPhone 4

+(NSData *)RC4DataForData:(NSData *)data
                        password:(NSData *)key
                           error:(NSError **)error {
    
    size_t outLength;
    NSMutableData *
    cipherData = [NSMutableData dataWithLength:data.length];
    
    CCCryptorStatus
    result = CCCrypt(kCCEncrypt, // operation
                     kCCAlgorithmRC4, // Algorithm
                     0, // options
                     key.bytes, // key
                     key.length, // keylength
                     NULL, // (*iv).bytes,// iv
                     data.bytes, // dataIn
                     data.length, // dataInLength,
                     cipherData.mutableBytes, // dataOut
                     cipherData.length, // dataOutAvailable
                     &outLength); // dataOutMoved
    
    if (result == kCCSuccess) {
        cipherData.length = outLength;
    }
    else {
        
        NSLog(@"%d", result);
        
        if (error) {
            *error = [NSError errorWithDomain:kRNCryptManagerErrorDomain
                                         code:result
                                     userInfo:nil];
        }
        return nil;
    }
    
    return cipherData;
}


+(NSData *)encryptedDataForData:(NSData *)data
                        password:(NSData *)key
                              iv:(NSData *)iv
                           error:(NSError **)error {
    
    size_t outLength;
    NSMutableData *
    cipherData = [NSMutableData dataWithLength:data.length +
                  kAlgorithmBlockSize];
    
    CCCryptorStatus
    result = CCCrypt(kCCEncrypt, // operation
                     kAlgorithm, // Algorithm
                     kCCOptionPKCS7Padding, // options
                     key.bytes, // key
                     key.length, // keylength
                     (__bridge const void *)(iv), // (*iv).bytes,// iv
                     data.bytes, // dataIn
                     data.length, // dataInLength,
                     cipherData.mutableBytes, // dataOut
                     cipherData.length, // dataOutAvailable
                     &outLength); // dataOutMoved
    
    if (result == kCCSuccess) {
        cipherData.length = outLength;
    }
    else {
        if (error) {
            *error = [NSError errorWithDomain:kRNCryptManagerErrorDomain
                                         code:result
                                     userInfo:nil];
        }
        return nil;
    }
    
    return cipherData;
}


+ (NSData *)decryptedDataForData:(NSData *)data
                        password:(NSData *)key
                              iv:(NSData *)iv
                           error:(NSError **)error {
    
    size_t outLength;
    
    NSMutableData *
    cipherData = [[NSMutableData alloc]initWithLength:data.length + kCCBlockSizeAES128];
    
    
    CCCryptorStatus
    result = CCCrypt(kCCDecrypt, kAlgorithm, kCCOptionPKCS7Padding, key.bytes, key.length, (__bridge const void *)(iv), data.bytes, data.length, cipherData.mutableBytes, cipherData.length, &outLength);
    
    if(result == kCCSuccess) {
        cipherData.length = outLength;
    }
    else {
        if(error) {
            *error = [NSError errorWithDomain:kRNCryptManagerErrorDomain
                                         code:result
                                     userInfo:nil];
        }
        return nil;
    }
    
    return cipherData;
}


+ (NSData *)decryptedDataForData:(NSData *)data
                        password:(NSString *)password
                              iv:(NSData *)iv
                            salt:(NSData *)salt
                           error:(NSError **)error {
    
    NSData *key = [self AESKeyForPassword:password salt:salt];
    
    return [NSData decryptedDataForData:data password:key iv:iv error:error];
}

+ (NSData *)encryptedDataForData:(NSData *)data
                        password:(NSString *)password
                              iv:(NSData *)iv
                            salt:(NSData *)salt // salt:(NSData **)salt
                           error:(NSError **)error {
    
    NSData *key = [self AESKeyForPassword:password salt:salt];
    
    return [NSData encryptedDataForData:data password:key iv:iv error:error];
}

// ===================

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    
    int result = SecRandomCopyBytes(kSecRandomDefault,
                                    length,
                                    data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d",
             errno);
    
    return data;
}

// ===================

// Replace this with a 10,000 hash calls if you don't have CCKeyDerivationPBKDF
+ (NSData *)AESKeyForPassword:(NSString *)password
                         salt:(NSData *)salt {
    NSMutableData *
    derivedKey = [NSMutableData dataWithLength:kAlgorithmKeySize];
    
    int
    result = CCKeyDerivationPBKDF(kCCPBKDF2,            // algorithm
                                  password.UTF8String,  // password
                                  password.length,  // passwordLength
                                  salt.bytes,           // salt
                                  salt.length,          // saltLen
                                  kCCPRFHmacAlgSHA1,    // PRF
                                  kPBKDFRounds,         // rounds
                                  derivedKey.mutableBytes, // derivedKey
                                  derivedKey.length); // derivedKeyLen
    
    // Do not log password here
    NSAssert(result == kCCSuccess,
             @"Unable to create AES key for password: %d", result);
    
    return derivedKey;
}

@end
