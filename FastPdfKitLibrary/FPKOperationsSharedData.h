//
//  FPKOperationsSharedData.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/31/12.
//
//

#import <Foundation/Foundation.h>

enum FPKEncryptionAlgorithm {
    FPKEncryptionAlgorithmNone = 0,
    FPKEncryptionAlgorithmAES = 1,
    FPKEncryptionAlgorithmRC4 = 2
};
typedef NSUInteger FPKEncryptionAlgorithm;

@interface FPKOperationsSharedData : NSObject {
    
    NSString * password;
    NSData * key;
    
    FPKEncryptionAlgorithm algorithm;
}

@property (copy, nonatomic) NSString * password;
@property (strong, readonly, nonatomic) NSData * key;
@property (readwrite, nonatomic) FPKEncryptionAlgorithm algorithm;
@end
