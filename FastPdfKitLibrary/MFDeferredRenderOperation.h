//
//  MFDeferredRenderOperation.h
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/19/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "PrivateStuff.h"

@protocol MFDeferredRenderOperationDelegate;

@class MFDocumentManager;

@class MFPageDataOldEngine;
@interface MFDeferredRenderOperation : NSOperation {
	
	CGSize size;					// Size of the resulting image.
	NSNumber * number;				// Id of the resulting image.
	
    NSInteger leftNumber;			// Left page number.
	NSInteger rightNumber;			// Right page number (optional).
	MFDocumentManager * document;	// Source document manager.
	MFDeferredRenderMode mode;		// Mode.
	BOOL legacy;					// Legacy mode.
    CGFloat padding;
    BOOL showShadow;
}

-(id)initWithTarget:(id<MFDeferredRenderOperationDelegate>)aTarget leftPage:(NSInteger)leftPageNumber rightPage:(NSInteger)rightPageNumber document:(MFDocumentManager *)aDocument imagSize:(CGSize)aSize operationNumber:(NSNumber *)aName;

@property (strong) MFDocumentManager * document;
@property (readwrite) NSInteger leftNumber;
@property (readwrite) NSInteger rightNumber;
@property (readwrite) CGSize size;
@property (weak) id<MFDeferredRenderOperationDelegate> delegate;
@property (copy) NSNumber * number;
@property (readwrite) MFDeferredRenderMode mode;
@property (readwrite) BOOL legacy;
@property (readwrite) BOOL showShadow;
@property (readwrite) CGFloat padding;
@property (nonatomic,strong) MFPageDataOldEngine * data;
@end

@protocol MFDeferredRenderOperationDelegate

-(MFDocumentManager *)documentForRenderOperation:(MFDeferredRenderOperation *)operation;

-(void)renderOperation:(MFDeferredRenderOperation *)operation didCompleteWithData:(MFPageDataOldEngine *)data;

@end
