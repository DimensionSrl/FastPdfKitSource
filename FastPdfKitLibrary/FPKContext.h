//
//  FPKContext.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 20/11/15.
//
//

#import <Foundation/Foundation.h>
#import "FPKBaseDocumentViewController_private.h"

@interface FPKContext : NSObject
@property (nonatomic, weak) MFDocumentViewController * documentViewController;
@property (nonatomic, strong) FPKOverlayViewHelper * overlayViewHelper;
@end
