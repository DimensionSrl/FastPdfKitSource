//
//  FPKAnnotationDrawable.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 06/10/15.
//
//

#import <Foundation/Foundation.h>
#import "MFOverlayDrawable.h"
#import "MFDocumentOverlayDataSource.h"
#import "MFDocumentManager.h"

@interface FPKAnnotationDrawableDataSource : NSObject <MFDocumentOverlayDataSource>

@property (nonatomic, strong) MFDocumentManager * documentManager;

@end
