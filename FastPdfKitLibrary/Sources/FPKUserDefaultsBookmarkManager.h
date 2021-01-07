//
//  FPKUserDefaultsBookmarkManager.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/09/14.
//
//

#import <Foundation/Foundation.h>

#import "FPKBookmarksManager.h"

@interface FPKUserDefaultsBookmarkManager : NSObject <FPKBookmarksManager>

+(FPKUserDefaultsBookmarkManager *)defaultManager;

@end
