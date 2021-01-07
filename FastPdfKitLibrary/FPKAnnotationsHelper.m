//
//  FPKAnnotationsHelper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import "FPKAnnotationsHelper.h"

@implementation FPKAnnotationsHelper

-(instancetype)init {
    self = [super init];
    if(self) {
        self.annotationCache = [NSCache new];
    }
    return self;
}

-(NSArray *)annotationsForPage:(NSUInteger)page {
    return [self.annotationCache objectForKey:@(page)];
}

-(void)addAnnotations:(NSArray *)annotations page:(NSUInteger)page {
    [self.annotationCache setObject:annotations forKey:@(page)];
}

@end
