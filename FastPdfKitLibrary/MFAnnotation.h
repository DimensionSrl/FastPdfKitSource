//
//  MFAnnotation.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 11/14/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "MFOverlayTouchable.h"

@interface MFAnnotation : NSObject <MFOverlayTouchable>

/**
 Rect of the annotation, that is the area occupied by the annotation on the page
 in the PDF Coordinate System.
 */
@property (assign, readwrite) CGRect rect;

/**
 Rect converted to hybrid UI space (pdf-as-view).
 */
@property (assign, readwrite) CGRect frame;

@end
