//
//  FPKChildViewControllerWrapper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 15/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FPKPrivateOverlayWrapper.h"

@interface FPKChildViewControllersWrapper : FPKPrivateOverlayWrapper;
@property (nonatomic,strong) UIViewController * controller;
@end