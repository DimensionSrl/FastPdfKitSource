//
//  FPKBookmark.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/09/14.
//
//

#import <Foundation/Foundation.h>

@interface FPKBookmark : NSObject

@property (strong, nonatomic) NSNumber * pageNumber;

@property (copy, nonatomic) NSString * title;

@property (nonatomic, readonly) NSUUID * uniqueId;

+(FPKBookmark *)newBookmarkWithPageNumber:(NSNumber *)page title:(NSString *)title;

@end
