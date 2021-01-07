//
//  MFTiledViewData.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 12/6/10.
//  Copyright 2010 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <QuartzCore/QuartzCore.h>

typedef struct FPKPageRenderInfo {
    
    CGAffineTransform pageTransform;
    CGRect pageRect;
    
} FPKPageRenderInfo;

typedef struct FPKRenderInfo {
    
    BOOL initialized;
    
    NSUInteger leftPageNumber;
    NSUInteger rightPageNumber;
    
    FPKPageRenderInfo leftPageRenderInfo;
    FPKPageRenderInfo rightPageRenderInfo;
    
} FPKRenderInfo;

//CGRect fpkRenderInfoRectForPageNumber(FPKRenderInfo * info, NSUInteger pageNumber);
//CGAffineTransform fpkRenderInfoTransformFroPageNumber(FPKRenderInfo * info, NSUInteger pageNumber);
                                                      
//typedef struct MFTiledViewDataStruct {
//    
//    BOOL initialized;
//	CGAffineTransform leftTransform;
//	CGAffineTransform rightTransform;
//	CGRect leftRect;
//	CGRect rightRect;
//	NSUInteger leftNumber;
//	NSUInteger rightNumber;
//    
//    //BOOL pendingOverlay;
//    
//} MFTiledViewDataStruct;

@interface MFTiledViewData : NSObject {
	
	// Rendering.
	BOOL initialized;
	CGAffineTransform leftTransform;
	CGAffineTransform rightTransform;
	CGRect leftRect;
	CGRect rightRect;
	NSUInteger leftNumber;
	NSUInteger rightNumber;
    
    //BOOL pendingOverlay;
	
}


@property (readwrite) BOOL initialized;
@property (readwrite) CGAffineTransform leftTransform;
@property (readwrite) CGAffineTransform rightTransform;
@property (readwrite) CGRect leftRect;
@property (readwrite) CGRect rightRect;
@property (readwrite) NSUInteger leftNumber;
@property (readwrite) NSUInteger rightNumber;
//@property (readwrite) BOOL pendingOverlay;

@end
