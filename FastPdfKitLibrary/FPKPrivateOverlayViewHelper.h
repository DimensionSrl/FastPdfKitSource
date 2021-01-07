//
//  FPKPrivateOverlayViewHelper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import <Foundation/Foundation.h>
#import "MFOverlayView.h"



@class MFDocumentViewController;
@class MFDocumentManager;

@interface FPKPrivateOverlayViewHelper : NSObject <FPKOverlayViewDataSource_Private>
-(void)removeAllObjects;
@property (nonatomic, strong) MFDocumentManager * document;
@property (nonatomic, weak) MFDocumentViewController * documentViewController;
@property (nonatomic, readwrite) NSUInteger supportedEmbeddedAnnotations;
@end
