//
//  MFEmbeddedWebProvider.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/10/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFDocumentOverlayDataSource.h"
#import "FPKPrivateOverlayWrapper.h"

@class MFWebAnnotation;

@interface MFEmbeddedWebProvider : FPKPrivateOverlayWrapper <MFDocumentOverlayDataSource>

@property (nonatomic,strong) NSURL * pageURL;
@property (nonatomic,readwrite) BOOL reloadOnDisplay;
@property (nonatomic,readwrite) CGRect webFrame;
@property (nonatomic,readwrite) BOOL initialized;
@property (nonatomic, strong) UIWebView * webView;

+(MFEmbeddedWebProvider *)providerForAnnotation:(MFWebAnnotation *)annotation;

@end
