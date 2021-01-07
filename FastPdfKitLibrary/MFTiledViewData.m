//
//  MFTiledViewData.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 12/6/10.
//  Copyright 2010 com.mobfarm. All rights reserved.
//

#import "MFTiledViewData.h"


//CGRect fpkRenderInfoRectForPageNumber(FPKRenderInfo * info, NSUInteger pageNumber) {
//    
//    if(pageNumber == info->leftPageNumber) {
//        
//        return info->leftPageRenderInfo.pageRect;
//        
//    } else if (pageNumber == info->rightPageNumber) {
//        
//        return info->rightPageRenderInfo.pageRect;
//    }
//    
//    return CGRectNull;
//}
//
//CGAffineTransform fpkRenderInfoTransformFroPageNumber(FPKRenderInfo * info, NSUInteger pageNumber) {
//    
//    if(pageNumber == info->leftPageNumber) {
//        
//        return info->leftPageRenderInfo.pageTransform;
//        
//    } else if (pageNumber == info->rightPageNumber) {
//        
//        return info->rightPageRenderInfo.pageTransform;
//    }
//    
//    return CGAffineTransformIdentity;
//}

@implementation MFTiledViewData
@synthesize initialized, leftTransform, rightTransform, leftRect, rightRect, leftNumber, rightNumber;
//@synthesize pendingOverlay;

-(id)init {

	if((self = [super init])) {
	
		self.initialized = NO;
		self.leftTransform = CGAffineTransformIdentity;
		self.rightTransform = CGAffineTransformIdentity;
		self.leftRect = CGRectNull;
		self.rightRect = CGRectNull;
		self.leftNumber = 0;
		self.rightNumber = 0;
		
	}
	return self;
}


@end
