//
//  FPKOverlayViewHelper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 28/11/14.
//
//

#import <Foundation/Foundation.h>
#import "MFOverlayView.h"

@class MFDocumentViewController;

@interface FPKOverlayViewHelper : NSObject <FPKOverlayViewDelegate_Private, FPKOverlayViewDataSource_Private>

@property (nonatomic, weak) MFDocumentViewController * documentViewController;

@end
