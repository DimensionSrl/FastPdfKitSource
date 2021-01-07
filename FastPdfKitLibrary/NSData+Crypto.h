//
//  NSData+NSData_Crypto.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/31/12.
//
//

#import <Foundation/Foundation.h>

@interface NSData (Crypto)

+(NSData *)decryptedDataForData:(NSData *)data
                        password:(NSString *)password
                              iv:(NSData *)iv
                            salt:(NSData *)salt
                           error:(NSError **)error;

+(NSData *)encryptedDataForData:(NSData *)data
                        password:(NSString *)password
                              iv:(NSData *)iv
                            salt:(NSData *)salt
                           error:(NSError **)error;

+(NSData *)AESKeyForPassword:(NSString *)password
                         salt:(NSData *)salt;

+(NSData *)encryptedDataForData:(NSData *)data
                        password:(NSData *)key
                              iv:(NSData *)iv
                           error:(NSError **)error;

+(NSData *)decryptedDataForData:(NSData *)data
                        password:(NSData *)key
                              iv:(NSData *)iv
                           error:(NSError **)error;

+(NSData *)RC4DataForData:(NSData *)data
                  password:(NSData *)key
                     error:(NSError **)error;

@end
