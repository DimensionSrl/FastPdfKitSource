//
//  FPKDrawableOverlayView.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/05/15.
//
//

#import <Foundation/Foundation.h>
#import "FPKDrawablesBunch.h"
#import "FPKPageMetrics.h"

@interface FPKDrawableOverlayView : UIView

@property (nonatomic, strong) FPKDrawablesBunch * pdfCoordinatesDrawables;
@property (nonatomic, strong) FPKDrawablesBunch * uiCoordinatesDrwables;

@property (nonatomic, strong) FPKPageMetrics * metrics;

@end
