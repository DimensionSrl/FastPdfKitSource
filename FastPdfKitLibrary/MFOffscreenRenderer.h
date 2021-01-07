//
//  MFOffscreenRenderer.h
//  PDFReaderHD
//
//  Created by Nicolò Tosi on 4/15/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class MFDocumentManager;
@interface MFOffscreenRenderer : NSObject {
	
	BOOL invalid;
	
    //CGContextRef offscreenCtx;
	//CGSize contextSize;
	//NSLock * lock;
    
    CGContextRef scratchpadCtx;
    CGSize scratchpadSize;
    NSRecursiveLock * scratchpadLock;
	
	MFDocumentManager *__weak dataSource;
    
}

@property (nonatomic,weak) MFDocumentManager *dataSource;

-(CGImageRef)createImageWithPage:(NSUInteger)pageNr pixelScale:(CGFloat)aScale imageScale:(NSUInteger)scaling screenDimension:(CGFloat)dimension;
-(CGImageRef)createImageWithImage:(CGImageRef)image;
-(CGImageRef)createImageFromPDFPagesLeft:(NSInteger)leftPage andRight:(NSInteger)rightPage size:(CGSize)size andScale:(CGFloat)scale useLegacy:(BOOL)legacy showShadow:(BOOL)shadow andPadding:(CGFloat)padding;
-(CGImageRef)createImageFromPDFPage:(NSInteger)page size:(CGSize)size  andScale:(CGFloat)scale useLegacy:(BOOL)legacy showShadow:(BOOL)shadow andPadding:(CGFloat)padding;

-(CGImageRef)createImageForThumbnailOfPageNumber:(NSUInteger)pageNr ofSize:(CGSize)size andScale:(CGFloat)scale;

-(void)tearDown;

@end
