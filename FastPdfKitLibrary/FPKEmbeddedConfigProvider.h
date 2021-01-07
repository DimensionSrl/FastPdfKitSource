//
//  FPKEmbeddedConfigProvider.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 12/02/15.
//
//

#import <Foundation/Foundation.h>
#import "FPKPrivateOverlayWrapper.h"
#import "FPKConfigAnnotation.h"

@interface FPKEmbeddedConfigProvider : FPKPrivateOverlayWrapper

+(FPKEmbeddedConfigProvider *)providerForAnnotation:(FPKConfigAnnotation *)annotation
                                           delegate:(MFDocumentViewController *)controller;

@property (nonatomic,copy) NSNumber * maxZoomScale;
@property (nonatomic,copy) NSNumber * edgeFlipWidth;

@end
