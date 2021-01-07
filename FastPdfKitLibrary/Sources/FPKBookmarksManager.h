//
//  FPKBookmarksManager.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/09/14.
//
//

#import <Foundation/Foundation.h>

@protocol FPKBookmarksManager <NSObject>

-(NSArray *)loadBookmarksForDocumentId:(NSString *)documentId;
-(void)saveBookmarks:(NSArray *)bookmarks forDocumentId:(NSString *)documentId;

@end
