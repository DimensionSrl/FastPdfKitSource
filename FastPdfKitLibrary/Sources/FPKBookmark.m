//
//  FPKBookmark.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/09/14.
//
//

#import "FPKBookmark.h"

@interface FPKBookmark()

@property (nonatomic, readwrite, strong) NSUUID * uniqueId;

@end

@implementation FPKBookmark

+(FPKBookmark *)newBookmarkWithPageNumber:(NSNumber *)pageNr title:(NSString *)title
{
    FPKBookmark * bookmark = [[FPKBookmark alloc]init];
    bookmark.pageNumber = pageNr;
    bookmark.title = title;
    bookmark.uniqueId = [NSUUID UUID];
    
    return bookmark;
}

-(NSString *)title {
    if(!_title) {
        _title = [NSString stringWithFormat:@"Page %lu", (unsigned long)self.pageNumber.unsignedIntegerValue];
    }
    return _title;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject:self.uniqueId.UUIDString forKey:@"uniqueId"];
    [encoder encodeObject:self.pageNumber forKey:@"pageNumber"];
    [encoder encodeObject:self.title forKey:@"title"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        
        self.uniqueId = [[NSUUID alloc]initWithUUIDString:[decoder decodeObjectForKey:@"uniqueId"]];
        self.pageNumber = [decoder decodeObjectForKey:@"pageNumber"];
        self.title = [decoder decodeObjectForKey:@"title"];
    }
    return self;
}

@end
