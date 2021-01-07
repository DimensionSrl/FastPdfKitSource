//
//  FPKOperationsSharedData.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/31/12.
//
//

#import "FPKOperationsSharedData.h"
#import "NSData+Crypto.h"

@interface FPKOperationsSharedData ()

@property (strong, readwrite, nonatomic) NSData * key;

@end

@implementation FPKOperationsSharedData

@synthesize key, password, algorithm;

static char salt [] = "p40l1n0p4p3r1n00";
static int salt_len = 16;

-(NSData *)key {
    
    @synchronized(self) {
     
        if((!key) && (self.password)) 
        {
            
            NSData * saltData = [[NSData alloc]initWithBytes:salt length:salt_len];
            NSData * saltedPassword = [NSData AESKeyForPassword:password salt:saltData];
            
            self.key = saltedPassword;
            
        }
    }
    
    return key;
}

@end
