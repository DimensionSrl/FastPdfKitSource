//
//  FPKUserDefaultsBookmarkManager.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/09/14.
//
//

#import "FPKUserDefaultsBookmarkManager.h"
#import "FPKBookmarksManager.h"
#import "FPKBookmark.h"

@implementation FPKUserDefaultsBookmarkManager

+(FPKUserDefaultsBookmarkManager *)defaultManager {
    static dispatch_once_t onceToken;
    static FPKUserDefaultsBookmarkManager * defaultManager = nil;
    dispatch_once(&onceToken, ^{
        defaultManager = [[FPKUserDefaultsBookmarkManager alloc]init];
    });
    return defaultManager;
}

+(NSString *)bookmarksKeyForDocumentId:(NSString *)documentId {
    
    return [NSString stringWithFormat:@"bookmarks_%@", documentId];
}

/**
 * This method will load the bookmarks stored in user defaults associated with the
 * specifid document id.
 * @param documentId The document id string.
 * @return An array of FPKBookmark.
 */
-(NSArray *)loadBookmarksForDocumentId:(NSString *)documentId {
    
    NSString * key = [FPKUserDefaultsBookmarkManager bookmarksKeyForDocumentId:documentId];
    
    id object = [[NSUserDefaults standardUserDefaults]objectForKey:key];
    
    if([object isKindOfClass:[NSData class]]) {
      
        NSData * data = (NSData *)object;
        
        NSArray * bookmarks = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        return bookmarks;
    }
    
    return nil;
}

/**
 * This method will save the array of bookmarks  in user defaults with a key
 * generated from the specified documentId.
 * @param bookmarks The bookmarks to save.
 * @param documentId The documentId to use to generate the key.
 */
-(void)saveBookmarks:(NSArray *)bookmarks forDocumentId:(NSString *)documentId {
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:bookmarks];
    
    NSString * key = [FPKUserDefaultsBookmarkManager bookmarksKeyForDocumentId:documentId];
    
    [[NSUserDefaults standardUserDefaults]setObject:data forKey:key];
    if(![[NSUserDefaults standardUserDefaults]synchronize]) {
#if DEBUG
        NSLog(@"Could not save bookmarks to standard UserDefaults");
#endif
    }
}

@end
