//
//  FPKAnnotationCache.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#import <UIKit/UIKit.h>

@interface FPKAnnotationsCache : NSObject

-(NSInteger)annotationsCountForPage:(NSUInteger)page;
-(void)addAnnotationsCount:(NSUInteger)count page:(NSUInteger)page;
+(NSArray *)emptyAnnotations;

@end
