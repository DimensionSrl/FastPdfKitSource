//
//  MFEmbeddedVideoProvider2.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 15/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FPKChildViewControllersHelper.h"
#import "FPKChildViewControllersWrapper.h"

@class MFDocumentViewController;

@interface MFEmbeddedVideoProvider : FPKChildViewControllersWrapper
@property (nonatomic, readwrite) BOOL autoplay;
@property (nonatomic, readwrite) BOOL loop;
@property (nonatomic, readwrite) BOOL controls;
@property (nonatomic, copy) NSURL * URL;
@end
