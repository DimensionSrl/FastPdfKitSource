//
//  FPKAnnotationsHelper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import <Foundation/Foundation.h>

@interface FPKAnnotationsHelper : NSObject

@property (nonatomic, strong) NSCache * annotationCache;

-(NSArray *)annotationsForPage:(NSUInteger)page;
-(void)addAnnotations:(NSArray *)annotations page:(NSUInteger)page;

@end
