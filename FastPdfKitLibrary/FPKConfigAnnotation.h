//
//  FPKConfigAnnotation.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 12/02/15.
//
//

#import <Foundation/Foundation.h>
#import "MFFPKAnnotation.h"

@interface FPKConfigAnnotation : MFFPKAnnotation

@property (nonatomic, copy) NSNumber * maxZoomScale;
@property (nonatomic, copy) NSNumber * edgeFlipMargin;

@end
