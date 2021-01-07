//
//  FPKThumbnailReadWriter.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#import "FPKThumbnailFileStore.h"

@interface FPKThumbnailFileStore()

@end

@implementation FPKThumbnailFileStore


+(NSString *)thumbnailNameForPage:(NSUInteger)page {
    return [NSString stringWithFormat:@"thumb_%lu.thumb",(unsigned long)page];
}

+(NSString *)thumbnailImagePathForPage:(NSUInteger)page cacheFolderPath:(NSString *)folderPath {
    
    NSString * fileName = [[self class]thumbnailNameForPage:page];
    NSString * filePath = [folderPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

-(NSString *)savefileNameForPage:(NSUInteger)page {
    
    return [FPKThumbnailFileStore thumbnailImagePathForPage:page cacheFolderPath:self.directory];
}

-(BOOL)dataAvailableForPage:(NSUInteger)page {
    NSString * file = [self savefileNameForPage:page];
    return [[NSFileManager defaultManager]fileExistsAtPath:file];
}

-(NSData *)loadDataForPage:(NSUInteger)page {
    NSString * file = [self savefileNameForPage:page];
    NSError * __autoreleasing error = nil;
    NSData * data = [NSData dataWithContentsOfFile:file options:NSDataReadingMappedIfSafe error:&error];
    if(!data && self.verbose && error) {
        NSLog(@"%@",error.localizedDescription);
    }
    return data;
}

-(void)saveData:(NSData *)data page:(NSUInteger)page {
    NSString * file = [self savefileNameForPage:page];
        NSError * __autoreleasing error = nil;
    if(![data writeToFile:file options:0 error:&error]) {
        if(self.verbose && error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
}

@end
