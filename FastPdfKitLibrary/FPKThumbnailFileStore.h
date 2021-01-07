//
//  FPKThumbnailReadWriter.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FPKThumbnailDataStore.h"

@interface FPKThumbnailFileStore : NSObject <FPKThumbnailDataStore>

@property (nonatomic,copy) NSString * directory;
@property (nonatomic,readonly) BOOL verbose;
@end
