//
//  FPKThumbnailScrollViewDelegate.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/9/12.
//
//

#import <Foundation/Foundation.h>

@protocol FPKThumbnailScrollViewDelegate <NSObject>

-(NSString *)titleForThumbnailViewOfPage:(NSUInteger)page;

@end
