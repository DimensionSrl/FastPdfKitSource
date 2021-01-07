//
//  FPKDetailView.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FPKDetailView.h"
#import "MFLinkAnnotation.h"
#import "MFURIAnnotation.h"
#import "MFRemoteLinkAnnotation.h"
#import "MFEmbeddedWebProvider.h"
#import "MFEmbeddedVideoProvider.h"
#import "MFEmbeddedAudioProvider.h"
#import "MFEmbeddedRemoteAudioProvider.h"
#import "MFOverlayView.h"
#import "MFTiledOverlayView.h"
#import "MFAudioAnnotation.h"
#import "MFWebAnnotation.h"
#import "MFVideoAnnotation.h"
#import "MFDocumentManager_private.h"
#import "FPKBaseDocumentViewController_private.h"
#import "PrivateStuff.h"
#import "FPKIntermediateView.h"

#define FPK_ANIMATE_OVERLAY_VIEWS 0
#define FPK_DEF_MAX_ZOOM 8.0

@interface FPKDetailView()

-(void)recalculatePagesInfo;

@property (nonatomic,strong) NSValue *previousPoint;
@property (nonatomic,strong) NSValue *previousTilePoint;

@property (nonatomic, strong) NSArray *leftAnnotations;
@property (nonatomic, strong) NSArray *rightAnnotations;

@property (nonatomic, strong) NSArray *leftDrawables;
@property (nonatomic, strong) NSArray *rightDrawables;

@property (nonatomic, strong) NSArray *leftTouchables;
@property (nonatomic, strong) NSArray *rightTouchables;
@property (nonatomic, readwrite) NSUInteger lastLeftTouchablesPage;
@property (nonatomic, readwrite) NSUInteger lastRightTouchablesPage;

@property (nonatomic, readwrite) NSUInteger lastLeftVideoControllerPage;
@property (nonatomic, readwrite) NSUInteger lastRightVideoControllerPage;
@property (nonatomic, strong) NSMutableArray * leftVideoControllers;
@property (nonatomic, strong) NSMutableArray * rightVideoControllers;

@property (nonatomic, strong) NSMutableArray * leftWebControllers;
@property (nonatomic, strong) NSMutableArray * rightWebControllers;
@property (nonatomic, readwrite) NSUInteger lastLeftWebControllerPage;
@property (nonatomic, readwrite) NSUInteger lastRightWebControllerPage;

@property (nonatomic, strong) NSMutableArray * leftAudioControllers;
@property (nonatomic, strong) NSMutableArray * rightAudioControllers;
@property (nonatomic, readwrite) NSUInteger lastLeftAudioControllerPage;
@property (nonatomic, readwrite) NSUInteger lastRightAudioControllerPage;

@property (nonatomic, readwrite) NSUInteger lastLeftTouchPage;
@property (nonatomic, readwrite) NSUInteger lastRightTouchPage;

@property (nonatomic, strong) NSMutableArray * leftRemoteAudioControllers;
@property (nonatomic, strong) NSMutableArray * rightRemoteAudioControllers;
@property (nonatomic, readwrite) NSUInteger lastLeftRemoteAudioControllerPage;
@property (nonatomic, readwrite) NSUInteger lastRightRemoteAudioControllerPage;

@property (nonatomic, strong) NSArray * leftOverlayViews;
@property (nonatomic, strong) NSArray * rightOverlayViews;
@property (nonatomic, readwrite) NSUInteger lastLeftOverlayViewsPage;
@property (nonatomic, readwrite) NSUInteger lastRightOverlayViewsPage;

@property (nonatomic, strong) NSMutableArray * leftVideoViews;
@property (nonatomic, strong) NSMutableArray * rightVideoViews;
@property (nonatomic, strong) NSMutableArray * leftVidePlayers;
@property (nonatomic, strong) NSMutableArray * rightVideoPlayers;

@end

@implementation FPKDetailView

@synthesize settings;

-(BOOL)gesturesDisabled{
    
    BOOL retVal = YES;
    
    if([delegate gesturesDisabled])
        retVal =  YES;
    else
        retVal =  NO;
    
    // NSLog(@"Gesture Disabled %i", retVal);
    
    return retVal;
}

-(void)recalculatePagesInfo {
	
	NSUInteger maxNrOfPages = [[delegate document]numberOfPages];
    
    renderInfo.initialized = NO;
    counter++;
    
    [overlayView setNeedsDisplay];
    
	[self setLeftPage:leftPageForPosition(viewPosition, pageMode, pageLead, pageDirection, maxNrOfPages)];
	[self setRightPage:rightPageForPosition(viewPosition, pageMode, pageLead, pageDirection, maxNrOfPages)];
}

@synthesize edgeFlipWidth;
@synthesize delegate;
@synthesize viewPosition, pageMode, leftPage, rightPage, pageLead, pageDirection;
@synthesize previousPoint, previousTilePoint;
@synthesize scrollDetailView, previewView, containerView, tiledView;
@synthesize leftAnnotations, rightAnnotations;
//@synthesize tiledViewData;
@synthesize rightDrawables, leftDrawables;
@synthesize overlayEnabled;
@synthesize overlayView, leftOverlayViews, rightOverlayViews, lastLeftOverlayViewsPage, lastRightOverlayViewsPage;
@synthesize leftVideoControllers, rightVideoControllers, lastLeftVideoControllerPage, lastRightVideoControllerPage;
@synthesize leftWebControllers, rightWebControllers, lastLeftWebControllerPage, lastRightWebControllerPage;
@synthesize leftAudioControllers, rightAudioControllers, lastLeftAudioControllerPage, lastRightAudioControllerPage;
@synthesize leftTouchables, rightTouchables, lastLeftTouchablesPage, lastRightTouchablesPage;
@synthesize renderInfo;
@synthesize zoomScale, zoomOffset, zoomRect;
@synthesize pendingOverlay;
@synthesize intermediateView;
@synthesize pendingOverlayViews;
@synthesize leftRemoteAudioControllers, rightRemoteAudioControllers, lastLeftRemoteAudioControllerPage, lastRightRemoteAudioControllerPage;
@synthesize pendingZoom;
@synthesize counter;
@synthesize lastLeftTouchPage, lastRightTouchPage;
@synthesize leftVideoViews, rightVideoViews, leftVidePlayers, rightVideoPlayers;
// @synthesize moviePlayerController;

-(void)setEdgeFlipWidth:(CGFloat)newEdgeFlipWidth {
    
    if(newEdgeFlipWidth < 0.0) {
        newEdgeFlipWidth = 0.0;
    } else if (newEdgeFlipWidth > 0.5) {
        newEdgeFlipWidth = 0.5;
    }
    
    edgeFlipWidth = newEdgeFlipWidth;
}

-(float)zoomScale {
    return scrollDetailView.zoomScale;
}

-(CGPoint)zoomOffset {
    return scrollDetailView.contentOffset;
}

#pragma mark - Geometry conversion functions

-(CGPoint)convertPoint:(CGPoint)point fromViewtoPage:(NSUInteger)page {
    
    FPKRenderInfo info = self.renderInfo;
    
    //MFTiledViewDataStruct data = tiledViewDataStruct;
    CGPoint tiledViewPoint = CGPointZero;
    
    if(!info.initialized) {
        return CGPointZero;
    }
    tiledViewPoint = [scrollDetailView convertPoint:point toView:tiledView];
    
    if(page == info.leftPageNumber) {
        
        return CGPointApplyAffineTransform(tiledViewPoint, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform));
        
    } else if (page == info.rightPageNumber) {
        
        return CGPointApplyAffineTransform(tiledViewPoint, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform));
        
    } else {
        
        return CGPointZero;
    }
}

-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page {
    
    //MFTiledViewDataStruct data = tiledViewDataStruct;
    FPKRenderInfo info = self.renderInfo;
    
    CGPoint tiledViewPoint = CGPointZero;
    
    if(!info.initialized)
        return CGPointZero;
    
    if(page == info.leftPageNumber) {
        
        tiledViewPoint = CGPointApplyAffineTransform(point, info.leftPageRenderInfo.pageTransform);
        
    } else if (page == info.rightPageNumber) {
        
        tiledViewPoint = CGPointApplyAffineTransform(point, info.rightPageRenderInfo.pageTransform);
        
    } else {
        
        return CGPointZero;
    }
    
    return [scrollDetailView convertPoint:tiledViewPoint fromView:tiledView];
}

-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page {
    
    // MFTiledViewDataStruct data = self.tiledViewDataStruct;
    FPKRenderInfo info = renderInfo;
    
    CGRect tiledViewRect = CGRectNull;
    CGRect pageRect = CGRectNull;
    
    if(!info.initialized)
        return CGRectNull;
    
    tiledViewRect = [scrollDetailView convertRect:rect toView:tiledView];
    
    if(page == info.leftPageNumber) {
        
        pageRect = CGRectApplyAffineTransform(tiledViewRect, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform));    
        return pageRect;
    } else if (page == info.rightPageNumber) {
        
        pageRect = CGRectApplyAffineTransform(tiledViewRect, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform));
        return pageRect;
        
    } else {
        
        return CGRectNull;
    }
}

-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page {
    
    //MFTiledViewDataStruct data = self.tiledViewDataStruct;
    FPKRenderInfo info = renderInfo;
    
    CGRect tiledViewRect = CGRectNull;
    
    if(!info.initialized)
        return CGRectNull;
    
    if(page == info.leftPageNumber) {
        
        tiledViewRect = CGRectApplyAffineTransform(rect, info.leftPageRenderInfo.pageTransform);
        
    } else if (page == info.rightPageNumber) {
        
        tiledViewRect = CGRectApplyAffineTransform(rect, info.rightPageRenderInfo.pageTransform);
        
    } else {
        
        return CGRectNull;
    }
    
    return [scrollDetailView convertRect:tiledViewRect fromView:tiledView];
}

-(CGRect)convertRect:(CGRect)rect toOverlayFromPage:(NSUInteger)page {
    //MFTiledViewDataStruct data = self.tiledViewDataStruct;
    FPKRenderInfo info = renderInfo;
    
    if(!info.initialized)
        return CGRectNull;
    
    if(page == info.leftPageNumber) {
        
        return CGRectApplyAffineTransform(rect, info.leftPageRenderInfo.pageTransform);
        
    } else if (page == info.rightPageNumber) {
        
        return CGRectApplyAffineTransform(rect, info.rightPageRenderInfo.pageTransform);
        
    } else {
        
        return CGRectNull;
    }
}

-(CGRect)convertRect:(CGRect)rect fromOverlayToPage:(NSUInteger)page {
    
    FPKRenderInfo info = renderInfo;
    
    if(!info.initialized)
        return CGRectNull;
    
    if(page == info.leftPageNumber) {
        
        return  CGRectApplyAffineTransform(rect, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform));    
        
    } else if (page == info.rightPageNumber) {
        
        return CGRectApplyAffineTransform(rect, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform));
        
    } else {
        
        return CGRectNull;
    }
}

-(CGPoint)convertPoint:(CGPoint)point toOverlayFromPage:(NSUInteger)page {
    //MFTiledViewDataStruct data = self.tiledViewDataStruct;
    FPKRenderInfo info = renderInfo;
    
    if(!info.initialized)
        return CGPointZero;
    
    if(page == info.leftPageNumber) {
        
        return CGPointApplyAffineTransform(point, info.leftPageRenderInfo.pageTransform);
        
    } else if (page == info.rightPageNumber) {
        
        return CGPointApplyAffineTransform(point, info.rightPageRenderInfo.pageTransform);
        
    } else {
        
        return CGPointZero;
    }
    
}

-(CGPoint)convertPoint:(CGPoint)point fromOverlayToPage:(NSUInteger)page {
    FPKRenderInfo info = renderInfo;
    
    if(!info.initialized)
        return CGPointZero;
    
    if(page == info.leftPageNumber) {
        
        return  CGPointApplyAffineTransform(point, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform));    
        
    } else if (page == info.rightPageNumber) {
        
        return CGPointApplyAffineTransform(point, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform));
        
    } else {
        
        return CGPointZero;
    }
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return containerView;
    //return [scrollDetailView viewWithTag:111];
}

-(float)zoomLevelForAnnotationRect:(CGRect)rect ofPage:(NSUInteger)page {
    
    CGAffineTransform pageTransform;
    CGRect transformedRect;
    CGSize viewSize = scrollDetailView.bounds.size;
    //float zoom;
    float vRatio,hRatio;
    FPKRenderInfo info;
    
    if(!self.renderInfo.initialized)
        return 0;
    
    info = self.renderInfo;
    
    if(page == info.leftPageNumber) {
        
        pageTransform = info.leftPageRenderInfo.pageTransform;
        
    } else if (page == info.rightPageNumber) {
        
        pageTransform = info.rightPageRenderInfo.pageTransform;
        
    } else {
        return 0;
    }
    
    transformedRect = CGRectApplyAffineTransform(rect, pageTransform);
    
    vRatio = viewSize.height/transformedRect.size.height;
    hRatio = viewSize.width/transformedRect.size.width;
    
    return (fminf(vRatio, hRatio));
    
}

#pragma mark - Touch handling

-(NSArray *)touchablesForPage:(NSUInteger)page {
    
    return [_drawablesDataSource touchablesForPage:page];
}

-(NSArray *)drawablesForPage:(NSUInteger)page {
    
	return [_drawablesDataSource drawablesForPage:page];
}


-(BOOL)handleDoubleTouchOnTiledViewAtPoint:(NSValue *)value {
    
    CGRect annotationRect = CGRectNull;
    NSString * annotationUri = nil;
    BOOL annotationFound = NO;
    CGPoint pointInView, pointInDocument;
	NSUInteger page = 0;
    FPKRenderInfo info;
    
    [value getValue:&pointInView]; // Get the CGPoint from NSValue.
	
    // Skip if the tiledView has been not already initialized by at least one tile draw call.
	if(!(self.renderInfo.initialized)) {
        
		return NO;
	}	
    
    info = self.renderInfo;
    
	if(info.leftPageNumber != 0) {
        
		pointInDocument = CGPointApplyAffineTransform(pointInView, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform)); // Point in document user space.
        
      	if(nil==self.leftAnnotations) {
			NSArray *tmp = [[delegate document]linkAnnotationsForPageNumber:info.leftPageNumber];
			self.leftAnnotations = tmp;
		}
		
		for(MFLinkAnnotation *annotation in self.leftAnnotations) {
            
            if([annotation containsPoint:pointInDocument]) {
                
                annotationFound = YES;
                page = info.leftPageNumber;
                
                annotationRect = annotation.rect;
                
                if([annotation isKindOfClass:[MFURIAnnotation class]]) {
                    
                    annotationUri = [(MFURIAnnotation *)annotation uri];
                }
                
                
                break;
            }
		}
	}
	
	if((info.rightPageNumber!=0)&&(!annotationFound)) {   // Check the right page, if necessary.
		
		pointInDocument = CGPointApplyAffineTransform(pointInView, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform)); // Point in document user space.
		
		if(nil==self.rightAnnotations) {
			NSArray *tmp = [[delegate document]linkAnnotationsForPageNumber:info.rightPageNumber];
			self.rightAnnotations = tmp;
		}
		
		for(MFLinkAnnotation *annotation in self.rightAnnotations) {
            
            if([annotation containsPoint:pointInDocument]) {
                
                annotationFound = YES;
                page = info.rightPageNumber;
                annotationRect = annotation.rect;
                
                if([annotation isKindOfClass:[MFURIAnnotation class]]) {
                    
                    annotationUri = [(MFURIAnnotation *)annotation uri];
                }
                
                break;
            }
		}
	}
    
    if(annotationFound)
        [delegate didReceiveDoubleTapOnAnnotationRect:annotationRect withUri:annotationUri onPage:page];
    
    return annotationFound;
}

// Handle touch on tiledView here.
- (void)handleTouchOnTiledViewAtPoint:(NSValue *)value {
    
    FPKRenderInfo info;
    
    // Skip if the tiledView has been not already initialized by at least one tile draw call.
	if(!(self.renderInfo.initialized)) {
		return;
	}
    
    info = self.renderInfo;
	
	CGPoint pointInView;
	[value getValue:&pointInView];
	
	if(info.leftPageNumber!=0) {
		
		CGAffineTransform t = CGAffineTransformConcat(info.leftPageRenderInfo.pageTransform, self.tiledView.transform);
		CGRect quad = CGRectApplyAffineTransform(info.leftPageRenderInfo.pageRect, t); // Page cropbox in view coordinates.
		
		CGPoint pointInDocument = CGPointApplyAffineTransform(pointInView, CGAffineTransformInvert(info.leftPageRenderInfo.pageTransform)); // Point in document user space.
        CGPoint pointInOverlaySpace = [self convertPoint:pointInDocument toOverlayFromPage:info.leftPageNumber];
        
        // Handle the touchables.
        
        self.leftTouchables = [_drawablesDataSource touchablesForPage:info.leftPageNumber];
        
        for(id<MFOverlayTouchable> touchable in self.leftTouchables) {
            if([touchable containsPoint:pointInDocument]) {
                [delegate didReceiveTapOnTouchable:touchable];
                return;
            }
        }
        
        // Handle the annotations.
        
        if(self.lastLeftTouchPage!=info.leftPageNumber) {
            
            self.lastLeftTouchPage = info.leftPageNumber;
            
			NSArray *tmp = [[delegate document]linkAnnotationsForPageNumber:info.leftPageNumber];
			self.leftAnnotations = tmp;
		}
        
        NSMutableDictionary * tmp = nil;
        
		for(MFLinkAnnotation *annotation in self.leftAnnotations) {
            
			if([annotation isKindOfClass:[MFLinkAnnotation class]]) {
				
                if([annotation containsPoint:pointInDocument]) {
					
                    [delegate willFollowLinkToPage:annotation.destinationPage];
                    
                    [delegate goToPage:annotation.destinationPage];
        
                    return;	
				}
                
			} else if([annotation isKindOfClass:[MFURIAnnotation class]]) {
                
				MFURIAnnotation *uriAnnotation = (MFURIAnnotation *)annotation;
				if([uriAnnotation containsPoint:pointInDocument]) {
                    
                    NSString *uri = [uriAnnotation uri];
                    
                    if(!tmp) {
                        tmp = [NSMutableDictionary dictionary];
                    }
                    [tmp setValue:[NSValue valueWithCGRect:annotation.rect] forKey:uri]; // Cachine the annotation data for deferred invocation of the delegate callback.
					// [delegate didReceiveTapOnAnnotationRect:annotation.rect withUri:uri onPage:info.leftPageNumber];
				}
                
			} else if ([annotation isKindOfClass:[MFRemoteLinkAnnotation class]]) {
                
                MFRemoteLinkAnnotation *remoteAnnotation = (MFRemoteLinkAnnotation *)annotation;
                
				if(CGRectContainsPoint(remoteAnnotation.rect, pointInDocument)) {
                    
                    if(remoteAnnotation.destination) {
                        [delegate didReceiveTapOnAnnotationRect:remoteAnnotation.rect destination:remoteAnnotation.destination file:remoteAnnotation.document];

                    } else if (remoteAnnotation.page > 0) {
                        [delegate didReceiveTapOnAnnotationRect:remoteAnnotation.rect page:remoteAnnotation.page file:remoteAnnotation.document];

                    }
                    
                    return;
				}
            }
		}
		
        if(tmp) {
            
            NSArray * uris = nil;
            NSValue * rectValue;
            CGRect rect;
            
            uris = [tmp allKeys];
            
            for(NSString * uri in uris) {
                rectValue = [tmp valueForKey:uri];
                [rectValue getValue:&rect];
                [delegate didReceiveTapOnAnnotationRect:rect
                                                withUri:uri
                                                 onPage:info.leftPageNumber];
            }
            
        } else if(CGRectContainsPoint(info.leftPageRenderInfo.pageRect, pointInView)) {
			[delegate didReceiveTapOnPage:self.leftPage
                                  atPoint:pointInDocument];
		}	
	}
	
	if(info.rightPageNumber!=0) {
		
		CGAffineTransform t = CGAffineTransformConcat(info.rightPageRenderInfo.pageTransform, self.tiledView.transform);
		CGRect quad = CGRectApplyAffineTransform(info.rightPageRenderInfo.pageRect, t); // Page cropbox in view coordinates.
		
		CGPoint pointInPageSpace = CGPointApplyAffineTransform(pointInView, CGAffineTransformInvert(info.rightPageRenderInfo.pageTransform)); // Point in document user space.
        
        CGPoint pointInOverlaySpace = [self convertPoint:pointInPageSpace toOverlayFromPage:info.rightPageNumber];
        
        self.rightTouchables = [_drawablesDataSource touchablesForPage:info.rightPageNumber];
        
        for(id<MFOverlayTouchable> touchable in self.rightTouchables) {
            if([touchable containsPoint:pointInPageSpace]) {
                [delegate didReceiveTapOnTouchable:touchable];
                return;
            }
        }
        
		if(self.lastRightTouchPage != info.rightPageNumber) {
            
            self.lastRightTouchPage = info.rightPageNumber;
            
			NSArray *tmp = [[delegate document]linkAnnotationsForPageNumber:info.rightPageNumber];
			self.rightAnnotations = tmp;
		}
        
        NSMutableDictionary * tmp = nil;
		
		for(MFLinkAnnotation *annotation in self.rightAnnotations) {
			if([annotation isKindOfClass:[MFLinkAnnotation class]]) {
				if([annotation containsPoint:pointInPageSpace]) {
					[delegate goToPage:annotation.destinationPage];
					return;	
				}
			} else if([annotation isKindOfClass:[MFURIAnnotation class]]) {
				MFURIAnnotation *uriAnnotation = (MFURIAnnotation *)annotation;
				if([uriAnnotation containsPoint:pointInPageSpace]) {
					NSString *uri = [uriAnnotation uri];
                    
                    if(!tmp) {
                        tmp = [NSMutableDictionary dictionary];
                    }
                    [tmp setValue:[NSValue valueWithCGRect:annotation.rect] forKey:uri]; // Cachine the annotation data for deferred invocation of the delegate callback.
					//[delegate didReceiveTapOnAnnotationRect:annotation.rect withUri:uri onPage:info.rightPageNumber];
					//return;
				}
			} else if ([annotation isKindOfClass:[MFRemoteLinkAnnotation class]]) {
                
                MFRemoteLinkAnnotation *remoteAnnotation = (MFRemoteLinkAnnotation *)annotation;
				if([remoteAnnotation containsPoint:pointInPageSpace]) {
                    
                    if(remoteAnnotation.destination) {
                        [delegate didReceiveTapOnAnnotationRect:remoteAnnotation.rect destination:remoteAnnotation.destination file:remoteAnnotation.document];
                        return;    
                    } else if (remoteAnnotation.page > 0) {
                        [delegate didReceiveTapOnAnnotationRect:remoteAnnotation.rect page:remoteAnnotation.page file:remoteAnnotation.document];
                        return;
                    }
                    
				}
            }
		}
		
        if(tmp) {
            
            NSArray * uris = nil;
            NSValue * rectValue;
            CGRect rect;
            
            uris = [tmp allKeys];
            
            for(NSString * uri in uris) {
                rectValue = [tmp valueForKey:uri];
                [rectValue getValue:&rect];
                [delegate didReceiveTapOnAnnotationRect:rect withUri:uri onPage:info.rightPageNumber];
            }

		} else if(CGRectContainsPoint(info.rightPageRenderInfo.pageRect, pointInOverlaySpace)) {
			[delegate didReceiveTapOnPage:self.rightPage atPoint:pointInPageSpace];
		}	
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
	NSSet *allTouches = [event allTouches];
	switch ([allTouches count]) {
			
		case 1: { // Touch with one finger
			UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
			CGPoint pointInView = [touch locationInView:scrollDetailView];
			CGPoint pointInSuperView = [touch locationInView:[[self superview] superview]];
			CGPoint pointInContentView = [touch locationInView:self.tiledView];
			
			NSArray *touchArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:pointInView.x], [NSNumber numberWithFloat:pointInView.y], nil];
			
			switch ([touch tapCount]) {
				case 1: { //Single Tap.
					
					// Cancel previous request if it is still pending.
					[NSObject cancelPreviousPerformRequestsWithTarget:delegate selector:@selector(didReceiveTapAtPoint:) object:previousPoint];
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextButtonPressed) object:nil];
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prevButtonPressed) object:nil];
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTouchOnTiledViewAtPoint:) object:self.previousTilePoint];
					
					if([delegate isPageFlipOnEdgeTouchEnabled]) {
						CGFloat width = self.frame.size.width;
                        
						if (pointInSuperView.x < (width * edgeFlipWidth)) {
							
                            [self performSelector:@selector(prevButtonPressed) withObject:nil afterDelay:.25];
                            
                        } else if (pointInSuperView.x > (width * (1.0 - edgeFlipWidth))) {
                            
                            [self performSelector:@selector(nextButtonPressed) withObject:nil afterDelay:.25];
                            
                        } else {
							
							if([delegate isDocumentInteractionEnabled]) {
								
								NSValue *tiledPoint = [NSValue valueWithCGPoint:pointInContentView];
								self.previousTilePoint = tiledPoint;
								[self performSelector:@selector(handleTouchOnTiledViewAtPoint:) withObject:tiledPoint afterDelay:.25];
								
							}
							
							NSValue *pointValue = [NSValue valueWithCGPoint:pointInView];
							[self setPreviousPoint:pointValue];
							[delegate performSelector:@selector(didReceiveTapAtPoint:) withObject:pointValue afterDelay:.25];
							
						}
					} else {
						
						if([delegate isDocumentInteractionEnabled]) {
							
							NSValue *tiledPoint = [NSValue valueWithCGPoint:pointInContentView];
							self.previousTilePoint = tiledPoint;
							[self performSelector:@selector(handleTouchOnTiledViewAtPoint:) withObject:tiledPoint afterDelay:.25];
							
						}
						
						NSValue *pointValue = [NSValue valueWithCGPoint:pointInView];
						self.previousPoint = pointValue;
						[delegate performSelector:@selector(didReceiveTapAtPoint:) withObject:pointValue afterDelay:.25];
					}
					break;
				} 
				case 2: { //Double tap.
					
					if([delegate isZoomInOnDoubleTapEnabled]) {
						
						// Cancel any single tap requests.
						[NSObject cancelPreviousPerformRequestsWithTarget:delegate selector:@selector(didReceiveTapAtPoint:) object:previousPoint];
						[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextButtonPressed) object:nil];
						[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prevButtonPressed) object:nil];
						[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTouchOnTiledViewAtPoint:) object:self.previousTilePoint];
						
						self.previousPoint = nil;
						[self performSelector:@selector(doubleTapMethod:) withObject:touchArray];
					}
					break;		
				} 
			}
		} break;
		case 2: { //Tap with two fingers
			
		} break;
		default:
			break;
	}
}

-(void)prevButtonPressed{
	[delegate moveToPreviousPage];
}

-(void)nextButtonPressed{
	[delegate moveToNextPage];
}

-(void)doubleTapMethod:(NSArray *)touchArray{
	
    BOOL annotationFound = NO;
    
    CGPoint touchPoint;
    CGRect fitZoomRect;
    NSValue * pointValue;
    CGFloat pointX, pointY;
    
    if ([scrollDetailView zoomScale] > 1.0) { // Replace if(zoomed)
        
        [scrollDetailView setZoomScale:1.0 animated:YES];
        zoomed = NO;
        
    } else {
        
        // If the delegates does handle the double tap on annotation, check them out.
        
        if([delegate didReceiveDoubleTapOnAnnotationRect:CGRectNull withUri:nil onPage:0]) {
            
            pointX = [[touchArray objectAtIndex:0]floatValue];
            pointY = [[touchArray objectAtIndex:1]floatValue];
            
            touchPoint = CGPointMake(pointX, pointY);
            
            pointValue = [NSValue valueWithCGPoint:touchPoint];
            
            annotationFound = [self handleDoubleTouchOnTiledViewAtPoint:pointValue];
            
        }
        
        if(!annotationFound) {
            
            BOOL isPad = NO;
            
#ifdef UI_USER_INTERFACE_IDIOM
            isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
            
            // If no annotation is found, behave as usual.
            touchPoint = CGPointMake([[touchArray objectAtIndex:0] floatValue], [[touchArray objectAtIndex:1] floatValue]);
            
            if (isPad) {	
                
                fitZoomRect = CGRectMake(touchPoint.x - scrollDetailView.contentSize.width/5, touchPoint.y - scrollDetailView.contentSize.height/5, scrollDetailView.contentSize.width/2.5, scrollDetailView.contentSize.height/2.5);
                
            } else {
                
                fitZoomRect = CGRectMake(touchPoint.x - scrollDetailView.contentSize.width/8, touchPoint.y - scrollDetailView.contentSize.height/8, scrollDetailView.contentSize.width/4, scrollDetailView.contentSize.height/4);
            }
            
            [scrollDetailView zoomToRect:fitZoomRect animated:YES];
            zoomed = YES;
        }    
    }
}


-(BOOL) showShadow {
    return [delegate showShadow];
}

-(CGFloat) padding {
    return [delegate padding];
}


-(void)setPageLead:(NSInteger)aPageLead {
	
	if(pageLead != aPageLead) {
		pageLead = aPageLead;
		[self recalculatePagesInfo];
        [self setNeedsDisplay];
	}
}

-(void)setPageDirection:(NSInteger)aDirection {
	
	if(pageDirection != aDirection) {
		pageDirection = aDirection;
        [self recalculatePagesInfo];
        [self setNeedsDisplay];
	}
}

-(void)setPosition:(NSInteger)aPosition {
	
	if(viewPosition != aPosition) {
		viewPosition = aPosition;
		[self recalculatePagesInfo];
        [self setNeedsDisplay];
	}
}


-(void)setRightPage:(NSInteger)newPage {
    if(rightPage!=newPage) {
        rightPage = newPage;
        [self recalculatePagesInfo];
        
        if(pageMode == MFDocumentModeOverflow)
            [self setNeedsLayout];
        
        [self setNeedsDisplay];
    }
}

-(void)setLeftPage:(NSInteger)newPage {
    if(leftPage!=newPage) {
        //renderInfo.initialized = NO;
        leftPage = newPage;
        [self recalculatePagesInfo];
        if(pageMode == MFDocumentModeOverflow)
            [self setNeedsLayout];
        
        [self setNeedsDisplay];
    }
}

-(void)setPageMode:(NSInteger)aPageMode {
	
	if(pageMode != aPageMode) {
        // NSLog(@"Setting page mode %d",aPageMode);
        //renderInfo.initialized = NO;
		pageMode = aPageMode;
		[self recalculatePagesInfo];
        [tiledView setMode:aPageMode];
        [self setNeedsLayout];
        [self setNeedsDisplay];
	}
}

-(void)resetEdgeFlipWidth {
    
    NSLog(@"Method -resetEdgeFlipWidth does nothing. Just set -edgeFlipWidth to the desired amount. Valid range is between 0 and 0.5");
}


-(void)setZoomLevel{
    
    // Reset the default zoom.
    
    float defZoomScale = [delegate defaultMaxZoomScale];
    
    if(fabsf([scrollDetailView maximumZoomScale] - defZoomScale) > FLT_EPSILON) {
        [scrollDetailView setMaximumZoomScale:[delegate defaultMaxZoomScale]];
    }
    
    // Zoom lock.
    
    if([delegate autozoomOnPageChange]) {
        
        [scrollDetailView setContentOffset:CGPointMake(0, 0)];
        [scrollDetailView setZoomScale:zoomScale animated:YES];
        
    } else {
        
        [scrollDetailView setContentOffset:CGPointMake(0, 0) animated:NO];
        [scrollDetailView setZoomScale:1.0 animated:NO];
    }
}

-(void)prepareContents {
    
    return;
}

-(void)removeOverlayViews:(BOOL)animated {
    
    UIView * subview = nil;
    
    // Video.
    
    NSUInteger count = 0;
    
//    if(self.moviePlayerController) {
//            
//    [self.moviePlayerController pause];
//    [self.moviePlayerController.view removeFromSuperview];
//    
//    }
        
    for(MFEmbeddedVideoProvider * provider in self.leftVideoControllers) {
        
        subview = provider.videoPlayerView;
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
    }
    
    for(MFEmbeddedVideoProvider * provider in self.rightVideoControllers) {
        
        subview = provider.videoPlayerView;
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
    }
    
    // Web.
    
    for(MFEmbeddedWebProvider * provider in self.leftWebControllers) {
        
        subview = [provider webView];
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
    }
    
    for(MFEmbeddedWebProvider * provider in self.rightWebControllers) {
        
        subview = [provider webView];
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
    }
    
    // Local audio.
    
    for(MFEmbeddedAudioProvider * provider in self.rightAudioControllers) {
        subview = (UIView *)[provider audioPlayerView];
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
        
        provider.audioPlayerView = nil;
    }
    
    for(MFEmbeddedAudioProvider * provider in self.leftAudioControllers) {
        subview = (UIView *)[provider audioPlayerView];
        
        [provider willRemoveOverlayView:subview pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview pageView:nil];
        
        provider.audioPlayerView = nil;
    }
    
    // Remote audio.
    
    for(MFEmbeddedRemoteAudioProvider * provider in self.rightRemoteAudioControllers) {
        subview = (UIView *)[provider audioPlayerView];
        
        [provider willRemoveOverlayView:subview  pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview  pageView:nil];
        
        provider.audioPlayerView = nil;
    }
    
    for(MFEmbeddedRemoteAudioProvider * provider in self.leftRemoteAudioControllers) {
        subview = (UIView *)[provider audioPlayerView];
        
        [provider willRemoveOverlayView:subview  pageView:nil];
        [subview removeFromSuperview];
        [provider didRemoveOverlayView:subview  pageView:nil];
        
        provider.audioPlayerView = nil;
    }
    
    // User defined overlay views.
    
    for(UIView * overlaySubview in self.leftOverlayViews) {
        
        [delegate willRemoveOverlayView:overlaySubview];
        
        if(NO) { // TODO: temp disabled animation, fix them.
            [self animateOverlaySubviewOut:overlaySubview];
        } else {
            [overlaySubview removeFromSuperview];
        }
        [delegate didRemoveOverlayView:overlaySubview];
        count++;
    }
    
    for(UIView * overlaySubview in self.rightOverlayViews) {
        
        [delegate willRemoveOverlayView:overlaySubview];
        
        if(NO) {
            // TODO: temp disabled animation, fix them.
            [self animateOverlaySubviewOut:overlaySubview];
        } else {
            [overlaySubview removeFromSuperview];
        }
        
        [delegate didRemoveOverlayView:overlaySubview];
        count++;
    }
    
    // NSLog(@"Removed %d overlay views",count);
}

-(void)buildContainerViewForFrame:(CGRect)frame {
    
    UIView * aContainerView = nil;
    UIView * aPreviewView = nil;
    FPKTiledView * aTiledView = nil;
    MFOverlayView * anOverlayView = nil;
    
	aPreviewView = [[UIView alloc]initWithFrame:frame];
	[aPreviewView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[aPreviewView setAutoresizesSubviews:YES];
    [aPreviewView setOpaque:YES];
	self.previewView = aPreviewView;
    
	aTiledView = [[FPKTiledView alloc]initWithFrame:frame];
	[aTiledView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[aTiledView setAutoresizesSubviews:YES];
	[aTiledView setDelegate:self];
	[aTiledView setOpaque:NO];
	self.tiledView = aTiledView;
    
    if(delegate.useTiledOverlayView) {
        
        anOverlayView = [[MFTiledOverlayView alloc]initWithFrame:frame];
        
    } else {
        
        anOverlayView = [[MFOverlayView alloc]initWithFrame:frame];
    }
    
    [anOverlayView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [anOverlayView setDelegate:self];
    [anOverlayView setOpaque:NO];
    [self setOverlayView:anOverlayView];
    
    aContainerView = [[UIView alloc]initWithFrame:frame];
	[aContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[aContainerView setAutoresizesSubviews:YES];
	
	[aContainerView addSubview:previewView];
	[aContainerView insertSubview:tiledView aboveSubview:previewView];
    [aContainerView insertSubview:overlayView aboveSubview:tiledView];

    [self.scrollDetailView addSubview:aContainerView];
    self.containerView = aContainerView;
    
}


-(void)checkForPendingActions {
    
	if(self.pendingZoom) {
        
		self.pendingZoom = NO;
		
		[self performZoomOnRect:pendingZoomRect ofPage:pendingZoomPage withZoomLevel:pendingZoomLevel];
	}
    
    if(self.pendingOverlay) {
        
        self.pendingOverlay = NO;
        
        [self reloadOverlay];
    }
    
    if(self.pendingOverlayViews) {
        
        self.pendingOverlayViews = NO;
        
        [self layoutOverlayViews];
    }
}

-(void)animateOverlaySubviewWithMove:(UIView *)subview {
    
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.25f;
    animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
    animation.toValue = [NSValue valueWithCGPoint:[subview center]];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [[subview layer]addAnimation:animation forKey:@"move-in"];
    
    [[subview layer]setPosition:subview.center];
}

-(void)animateOverlaySubviewIn:(UIView *)subview {
    
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.25f;
    animation.fillMode = kCAFillModeForwards;
    animation.fromValue = [NSNumber numberWithInt:0.0];
    animation.toValue = [NSNumber numberWithInt:1.0];
    animation.removedOnCompletion = YES;
    [animation setValue:subview forUndefinedKey:@"subview"];
    [[subview layer]addAnimation:animation forKey:@"fade-in"];
    
    [[subview layer] setOpacity:1.0];
    
    // [[subview layer]setValue:[NSNumber numberWithFloat:1.0] forKey:@"opacity"];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
}

-(void)animateOverlaySubviewOut:(UIView *)subview {
    /*
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.25f;
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
    animation.fromValue = [NSValue valueWithCGPoint:[subview center]];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.delegate = self;
    [animation setValue:subview forUndefinedKey:@"subview"];
    [[subview layer]addAnimation:animation forKey:@"move-in"];
     */
    
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.4f;
    animation.fromValue = [NSNumber numberWithInt:1.0];
    animation.toValue = [NSNumber numberWithInt:0.0];  
    animation.delegate = self;
    animation.fillMode = kCAFillModeForwards;
    [animation setValue:subview forUndefinedKey:@"subview"];    
    [[subview layer] addAnimation:animation forKey:@"fade-out"];
    
    [[subview layer] setOpacity:0];
    
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.4];
//    [subview setAlpha:0.0];
//    [UIView setAnimationDelegate:subview];
//    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
//    [UIView commitAnimations];
}

-(void)layoutOverlayViews {
    
    NSUInteger count = 0;
    
    if(onSight && renderInfo.initialized) {
        
        NSArray * annotations = nil;
        NSMutableArray * controllersArray = nil;
        UIView * overlaySubview = nil;
        CGRect overlayViewFrame;
        
        if(leftPage!=0 && delegate.fpkAnnotationsEnabled) {
            
            // Video annotation.
            
            if(self.lastLeftVideoControllerPage != leftPage) {
                
                self.lastLeftVideoControllerPage = leftPage;
                self.leftVideoControllers = nil;
                
                annotations = [[delegate document]videoAnnotationsForPageNumber:leftPage];
                
                if([annotations count] > 0) {
                    
                    //overlayViewsSet = [[NSMutableSet alloc]init];
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFVideoAnnotation * annotation in annotations) {
                        
                        MFEmbeddedVideoProvider * provider = [[MFEmbeddedVideoProvider alloc]init];
                        provider.videoURL = annotation.url;
                        provider.videoFrame = annotation.rect;
                        
                        provider.loop = annotation.loop.boolValue;
                        provider.autoplay = annotation.autoplay.boolValue;
                        provider.controls = annotation.controls.boolValue;
                        
                        //[overlayViewsSet addObject:provider.videoPlayerView];
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                    }
                    
                    self.leftVideoControllers = controllersArray;
                    controllersArray = nil;
                }
                    
            }
                        
            for(MFEmbeddedVideoProvider * provider in self.leftVideoControllers) {
                
                overlaySubview = [provider videoPlayerView];
                
                overlayViewFrame = provider.videoFrame;

                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.leftPageRenderInfo.pageTransform);
                overlaySubview.frame = overlayViewFrame;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
                
                [overlayView addSubview:overlaySubview];
                
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif
                
                [provider didAddOverlayView:overlaySubview pageView:nil];
                
            }

            // Local audio annotation.
            
            if(self.lastLeftAudioControllerPage != leftPage) {
                
                self.lastLeftAudioControllerPage = leftPage;
                self.leftAudioControllers = nil;
                
                annotations = [[delegate document]audioAnnotationsForPageNumber:leftPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFAudioAnnotation * annotation in annotations) {
                        
                        MFEmbeddedAudioProvider * provider = [[MFEmbeddedAudioProvider alloc]init];
                        provider.audioURL = annotation.url;
                        provider.rect = annotation.rect;
                        
                        if(annotation.autoplay)
                        {
                            provider.autoplay = annotation.autoplay.boolValue;
                        }
                        else
                        {
                            provider.autoplay = [delegate doesHaveToAutoplayAudio:annotation.originalUri];
                        }
                        
                        provider.showView = annotation.showView ? annotation.showView.boolValue : YES;
                        
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                        
                    }
                    
                    self.leftAudioControllers = controllersArray;
                    controllersArray = nil;
                    
                }
            }
            
            for(MFEmbeddedAudioProvider * provider in self.leftAudioControllers) {
                
                CGRect tmpframe;
                
                Class<MFAudioPlayerViewProtocol> viewClass = [delegate classForAudioPlayerView];
                overlaySubview = [viewClass audioPlayerViewInstance];
                
                provider.audioPlayerView = (UIView<MFAudioPlayerViewProtocol>*)overlaySubview;
                
                overlayViewFrame = provider.rect;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.leftPageRenderInfo.pageTransform);
                tmpframe = overlaySubview.frame;
                tmpframe.origin = overlayViewFrame.origin;
                overlaySubview.frame = tmpframe;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];

                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif                
                [provider didAddOverlayView:overlaySubview pageView:nil];
                count++;
            }
            
            
            // Remote audio annotation.
            
            if(self.lastLeftRemoteAudioControllerPage != leftPage) {
                
                self.lastLeftRemoteAudioControllerPage = leftPage;
                self.leftRemoteAudioControllers = nil;
                
                annotations = [[delegate document]remoteAudioAnnotationsForPageNumber:leftPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFAudioAnnotation * annotation in annotations) {
                        
                        MFEmbeddedRemoteAudioProvider * provider = [[MFEmbeddedRemoteAudioProvider alloc]init];
                        provider.audioURL = annotation.url;
                        provider.audioFrame = annotation.rect;
                        
                        if(annotation.autoplay)
                        {
                            provider.autoplay = annotation.autoplay.boolValue;
                        }
                        else
                        {
                            provider.autoplay = [delegate doesHaveToAutoplayAudio:annotation.originalUri];
                        }
                        
                        provider.showView = annotation.showView ? annotation.showView.boolValue : YES;
                        
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                        
                    }
                    
                    self.leftRemoteAudioControllers = controllersArray;
                    controllersArray = nil;
                    
                }
            }
            
            for(MFEmbeddedRemoteAudioProvider * provider in self.leftRemoteAudioControllers) {
                
                CGRect tmpframe;
                
                Class<MFAudioPlayerViewProtocol> viewClass = [delegate classForAudioPlayerView];
                overlaySubview = [viewClass audioPlayerViewInstance];
                
                provider.audioPlayerView = (UIView<MFAudioPlayerViewProtocol>*)overlaySubview;
                
                overlayViewFrame = provider.audioFrame;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.leftPageRenderInfo.pageTransform);
                tmpframe = overlaySubview.frame;
                tmpframe.origin = overlayViewFrame.origin;
                overlaySubview.frame = tmpframe;
                
                [provider willAddOverlayView:overlaySubview  pageView:nil];
                
                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif                
                [provider didAddOverlayView:overlaySubview  pageView:nil];
            }
            
            // Web annotation.
            
            if(self.lastLeftWebControllerPage != leftPage) {
                
                self.lastLeftWebControllerPage = leftPage;
                self.leftWebControllers = nil;
                
                annotations = [[delegate document]webAnnotationsForPageNumber:leftPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFWebAnnotation * annotation in annotations) {
                        
                        MFEmbeddedWebProvider * provider = [[MFEmbeddedWebProvider alloc]init];
                        provider.pageURL = annotation.url;
                        provider.webFrame = annotation.rect;
                        
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                    }
                    
                    self.leftWebControllers = controllersArray;
                    controllersArray = nil;
                }
            }
            
            for(MFEmbeddedWebProvider * provider in self.leftWebControllers) {
                
                overlaySubview = [provider webView];
                overlayViewFrame = provider.webFrame;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.leftPageRenderInfo.pageTransform);
                overlaySubview.frame = overlayViewFrame;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif
                [provider didAddOverlayView:overlaySubview pageView:nil];
            }

            self.leftOverlayViews = [delegate overlayViewsForPage:leftPage];
            for(UIView * overlaySubview in leftOverlayViews) {
                    
                    // MBOH
                    /*
                     overlayViewFrame = [delegate rectForOverlayView:overlaySubview onPage:leftPage];
                    overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.leftPageRenderInfo.pageTransform);
                    overlaySubview.frame = overlayViewFrame;
                    
                    count++;
                    
                    [delegate willAddOverlayView:overlaySubview];
                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif                
                [delegate didAddOverlayView:overlaySubview];
                     
                     */
            }
            
        } // End of leftPage
        
        if(rightPage!=0 && ([delegate currentMode] == MFDocumentModeDouble) && delegate.fpkAnnotationsEnabled) {
            
            // Video annotations.
            
            if(self.lastRightVideoControllerPage != rightPage) {
                
                self.lastRightVideoControllerPage = rightPage;
                self.rightVideoControllers = nil;
                
                annotations = [[delegate document]videoAnnotationsForPageNumber:rightPage];
                
                if([annotations count] > 0) {
                    
                    //overlayViewsSet = [[NSMutableSet alloc]init];
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFVideoAnnotation * annotation in annotations) {
                        
                        MFEmbeddedVideoProvider * provider = [[MFEmbeddedVideoProvider alloc]init];
                        provider.videoURL = annotation.url;
                        provider.videoFrame = annotation.rect;
                        provider.autoplay = [delegate doesHaveToAutoplayVideo:annotation.originalUri];
                        
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                    }
                    
                    self.rightVideoControllers = controllersArray;
                    controllersArray = nil;
                }
            }
            
            for(MFEmbeddedVideoProvider * provider in self.rightVideoControllers) {
                
                overlaySubview = provider.videoPlayerView;
                overlayViewFrame = provider.videoFrame;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.rightPageRenderInfo.pageTransform);
                overlaySubview.frame = overlayViewFrame;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif
                [provider didAddOverlayView:overlaySubview pageView:nil];
            }

            // Audio annotation.
            
            if(self.lastRightAudioControllerPage != rightPage) {
                
                self.lastRightAudioControllerPage = rightPage;
                self.rightAudioControllers = nil;
                
                annotations = [[delegate document]audioAnnotationsForPageNumber:rightPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFAudioAnnotation * annotation in annotations) {
                        
                        MFEmbeddedAudioProvider * provider = [[MFEmbeddedAudioProvider alloc]init];
                        provider.audioURL = annotation.url;
                        provider.rect = annotation.rect;
                        
                        if(annotation.autoplay)
                        {
                            provider.autoplay = annotation.autoplay.boolValue;
                        }
                        else
                        {
                            provider.autoplay = [delegate doesHaveToAutoplayAudio:annotation.originalUri];
                        }
                        
                        provider.showView = annotation.showView ? annotation.showView.boolValue : YES;
                        
                        [controllersArray addObject:provider];
                        
                        provider = nil;
                    }
                    
                    self.leftAudioControllers = controllersArray;
                    controllersArray = nil;
                }
            }
            
            for(MFEmbeddedAudioProvider * provider in self.rightAudioControllers) {
                
                CGRect tmpframe;
                
                Class<MFAudioPlayerViewProtocol> viewClass = [delegate classForAudioPlayerView];
                overlaySubview = [viewClass audioPlayerViewInstance];
                provider.audioPlayerView = (UIView<MFAudioPlayerViewProtocol>*)overlaySubview;
                //[(UIView<MFAudioPlayerViewProtocol>*)overlaySubview setAudioProvider:provider];
                
                overlayViewFrame = provider.rect;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.rightPageRenderInfo.pageTransform);
                tmpframe = overlaySubview.frame;
                tmpframe.origin = overlayViewFrame.origin;
                overlaySubview.frame = tmpframe;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [overlayView addSubview:overlaySubview];
#endif
                [self animateOverlaySubviewIn:overlaySubview];
                [provider didAddOverlayView:overlaySubview pageView:nil];
            }
            
            
            // Remote audio annotation.
            
            if(self.lastRightRemoteAudioControllerPage != rightPage) {
                
                self.lastRightRemoteAudioControllerPage = rightPage;
                self.rightRemoteAudioControllers = nil;
                
                annotations = [[delegate document]remoteAudioAnnotationsForPageNumber:rightPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFAudioAnnotation * annotation in annotations) {
                        
                        MFEmbeddedRemoteAudioProvider * provider = [[MFEmbeddedRemoteAudioProvider alloc]init];
                        provider.audioURL = annotation.url;
                        provider.audioFrame = annotation.rect;
                        provider.autoplay = [delegate doesHaveToAutoplayAudio:annotation.originalUri];

                            provider.showView = annotation.showView.boolValue;

                        
                        [controllersArray addObject:provider];
                        provider = nil;
                    }
                    
                    self.rightRemoteAudioControllers = controllersArray;
                    controllersArray = nil;
                }
            }
            
            for(MFEmbeddedRemoteAudioProvider * provider in self.rightRemoteAudioControllers) {
                
                CGRect tmpframe;
                
                Class<MFAudioPlayerViewProtocol> viewClass = [delegate classForAudioPlayerView];
                overlaySubview = [viewClass audioPlayerViewInstance];
                
                provider.audioPlayerView = (UIView<MFAudioPlayerViewProtocol>*)overlaySubview;
                
                overlayViewFrame = provider.audioFrame;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.rightPageRenderInfo.pageTransform);
                tmpframe = overlaySubview.frame;
                tmpframe.origin = overlayViewFrame.origin;
                overlaySubview.frame = tmpframe;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [overlayView addSubview:overlaySubview];
#endif
                [self animateOverlaySubviewIn:overlaySubview];
                [provider didAddOverlayView:overlaySubview pageView:nil];
            }
            
            
            // Web annotation.
            
            if(self.lastRightWebControllerPage != rightPage) {
                
                self.lastRightWebControllerPage = rightPage;
                self.rightWebControllers = nil;
                
                annotations = [[delegate document]webAnnotationsForPageNumber:rightPage];
                
                if([annotations count] > 0) {
                    
                    controllersArray = [[NSMutableArray alloc]init];
                    
                    for(MFWebAnnotation * annotation in annotations) {
                        
                        MFEmbeddedWebProvider * provider = [[MFEmbeddedWebProvider alloc]init];
                        provider.pageURL = annotation.url;
                        provider.webFrame = annotation.rect;
                        
                        // Auto load here.
                        [controllersArray addObject:provider];
                        provider = nil;
                    }
                    
                    self.rightWebControllers = controllersArray;
                    controllersArray = nil;
                    
                }
            }
            
            for(MFEmbeddedWebProvider * provider in self.rightWebControllers) {
                
                overlaySubview = [provider webView];
                overlayViewFrame = provider.webFrame;
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.rightPageRenderInfo.pageTransform);
                overlaySubview.frame = overlayViewFrame;
                
                [provider willAddOverlayView:overlaySubview pageView:nil];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [overlayView addSubview:overlaySubview];
#endif
                [self animateOverlaySubviewIn:overlaySubview];
                [provider didAddOverlayView:overlaySubview pageView:nil];
            }
            
            // Overlay views.
//            
//            if(self.lastRightOverlayViewsPage!=rightPage) {
//                self.lastRightOverlayViewsPage = rightPage;
//                self.rightOverlayViews = [delegate overlayViewsForPage:rightPage];
//            }
            self.rightOverlayViews = [delegate overlayViewsForPage:rightPage];
            for(UIView * overlaySubview in rightOverlayViews) {
                
                /*
                // TODO: fix this (FIX WHAT???)
                overlayViewFrame = [delegate rectForOverlayView:overlaySubview onPage:rightPage];
                overlayViewFrame = CGRectApplyAffineTransform(overlayViewFrame, self.renderInfo.rightPageRenderInfo.pageTransform);
                overlaySubview.frame = overlayViewFrame;
                
                count++;
                
                [delegate willAddOverlayView:overlaySubview];
                [overlayView addSubview:overlaySubview];
#if FPK_ANIMATE_OVERLAY_VIEWS
                [self animateOverlaySubviewIn:overlaySubview];
#endif                

                [delegate didAddOverlayView:overlaySubview];
                 */
            }
        }
        
        // NSLog(@"Added %d overlay views",count);
        
    } else {
        
        self.pendingOverlayViews = YES;
    }
}

-(void)reloadOverlay {
    
    if(self.renderInfo.initialized && onSight) {
        
        [overlayView setNeedsDisplay];
        
    } else {
        
        self.pendingOverlay = YES;
        
    }
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    // zoomOffset = [scrollDetailView contentOffset];
    if(scrollView == scrollDetailView) {
        zoomLevel = scale;
        [delegate didEndZoomAtScale:scale];    
    }
}

-(void)saveZoom {
    
    // zoomOffset = [scrollDetailView contentOffset];
    // zoomLevel = [scrollDetailView zoomScale];
    
    return;
}

-(void)isOnSight {
    
    if(!onSight) {
        
        onSight = YES;
        
        // The following actions might be deferred if the requirements (render info correctly set) are not meet.
        
        [self resetEdgeFlipWidth];
        [self setZoomLevel];
        [self reloadOverlay];
        [self layoutOverlayViews];
    }
}

-(void)isOutOfSight:(BOOL)animated {
    
    if(onSight) {
        
        onSight = NO;
        
        [self saveZoom];        
        [self removeOverlayViews:animated];

    }
}

-(void)performZoomOnRect:(CGRect)rect ofPage:(NSUInteger)page withZoomLevel:(float)aZoomLevel {
    
    CGRect transformedRect = CGRectNull;
    CGAffineTransform t;
    CGSize zoomedViewSize;
    CGRect centeredRect;
    FPKRenderInfo info;
    
	if(self.renderInfo.initialized && onSight) {
		
        info = self.renderInfo;
        
        //    CGRect transformedRect = CGRectNull;
        
        //   aZoomLevel = 0;        
        //[scrollDetailView setZoomScale:aZoomLevel];
        
		if(page == info.leftPageNumber) {
			
			t = CGAffineTransformIdentity;
			t = CGAffineTransformConcat(self.tiledView.transform, t);
			t = CGAffineTransformConcat(info.leftPageRenderInfo.pageTransform, t);
			transformedRect = CGRectApplyAffineTransform(rect, t);
			
		} else if (page == info.rightPageNumber) {
			
			t = CGAffineTransformIdentity;
			t = CGAffineTransformConcat(self.tiledView.transform, t);
			t = CGAffineTransformConcat(info.rightPageRenderInfo.pageTransform, t);
			transformedRect = CGRectApplyAffineTransform(rect, t);
            
		} else {
            // Should never happen.
            
            // Recheck the data struct
            
            return;
        }
        
        if(aZoomLevel > 0.0) {
            
            zoomedViewSize = self.scrollDetailView.bounds.size;
            zoomedViewSize.width*=(1/aZoomLevel);
            zoomedViewSize.height*=(1/aZoomLevel);
            
            centeredRect = transformedRect;
            centeredRect.size.width+=(zoomedViewSize.width - centeredRect.size.width);
            centeredRect.size.height+=(zoomedViewSize.height - centeredRect.size.height);
            
            centeredRect.origin.x -= ((zoomedViewSize.width - transformedRect.size.width)*0.5);
            centeredRect.origin.y -= ((zoomedViewSize.height - transformedRect.size.height)*0.5);
            
            [scrollDetailView zoomToRect:centeredRect animated:YES];
            
        } else {
            
            [scrollDetailView zoomToRect:transformedRect animated:YES];
        }
        
	} else {
		
		self.pendingZoom = YES;
		pendingZoomRect = rect;
		pendingZoomPage = page;
		pendingZoomLevel = aZoomLevel;
	}
}

-(void)performZoom{
	
	[scrollDetailView setZoomScale:zoomLevel animated:YES];
}

//-(void)setZoomOnUnfocus {
//	zoomLevel = [scrollDetailView zoomScale];
//	zoomOffset = [scrollDetailView contentOffset];
//}

-(void)emptyCache {
    
	self.leftAnnotations = nil;
	self.rightAnnotations = nil;    
}

-(void)setSettings:(FPKSharedSettings *)newSettings
{
    if(settings!=newSettings)
    {
        settings = newSettings;
    }
    
    // self.tiledView.settings = settings;
}

-(id)initWithFrame:(CGRect)frame delegate:(MFDocumentViewController *)delegate {
    
    self = [super initWithFrame:frame];
    
    self.delegate = delegate;
    
    UIView * anIntermediateView = nil;
    MFScrollDetailView * aScrollView = nil;
    
    if (self) {
        // Initialization code
        
        // CGRect frame = CGRectNull;
        
        counter = 0;
        
        renderInfo.initialized = NO;            // Default NO.
        zoomed = NO;                            // Default NO.
        zoomLevel = 1.0;                        // Default 1.0.
        onSight = NO;                           // Default NO.
        edgeFlipWidth = 0.1;                    // Default 0.1.
        
        self.userInteractionEnabled = YES;
        
        self.lastLeftVideoControllerPage = 0;   // Default 0.
        self.lastRightVideoControllerPage = 0;  // Default 0.
        
        frame.origin = CGPointZero;
        
        anIntermediateView = [[FPKIntermediateView alloc]initWithFrame:frame];
        [anIntermediateView setOpaque:NO];
        [anIntermediateView setAutoresizesSubviews:YES];
        [anIntermediateView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        
        [self addSubview:anIntermediateView];
        self.intermediateView = anIntermediateView;
        
        aScrollView = [[MFScrollDetailView alloc]initWithFrame:frame];
        
        if(self.delegate.overflowEnabled && leftPage!=0) {
            
            CGRect cropbox;
            int angle;
            int pos = (leftPage-1); // TODO: take direction into account;
            CGRect contentFrame;
            [[delegate document]getCropbox:&cropbox andRotation:&angle forPageNumber:leftPage withBuffer:NO];
            
            // TODO: fix this
            //contentFrame = frameForLayer(frame.size, cropbox, angle, pos);
            
            frame.size = contentFrame.size;
            frame.origin = CGPointZero;
        }
        
        [aScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollView setAutoresizesSubviews:YES];
        [aScrollView setDelegate:self];
        [aScrollView setContentSize:CGSizeMake(frame.size.width,frame.size.height)];
        [aScrollView setMinimumZoomScale:1.0];
        
        float maxZoomScale = [delegate defaultMaxZoomScale];
        
        if(maxZoomScale > 0.0) {
            [aScrollView setMaximumZoomScale:maxZoomScale];
        } else {
            [aScrollView setMaximumZoomScale:FPK_DEF_MAX_ZOOM];
        }
        
        [aScrollView setAlwaysBounceHorizontal:NO];
        [aScrollView setDirectionalLockEnabled:NO];
        [aScrollView setScrollEnabled:YES];
        
        [intermediateView addSubview:aScrollView];
        self.scrollDetailView = aScrollView;
        
        [self buildContainerViewForFrame:frame];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
#if FPK_DEALLOC
    NSLog(@"%@ - initWithFrame:",NSStringFromClass([self class]));
#endif
    
    self = [super initWithFrame:frame];
    
    UIView * anIntermediateView = nil;
    MFScrollDetailView * aScrollView = nil;
    
    if (self) {
        // Initialization code
        
        // CGRect frame = CGRectNull;
        
        counter = 0;
        
        renderInfo.initialized = NO;            // Default NO.
        zoomed = NO;                            // Default NO.
        zoomLevel = 1.0;                        // Default 1.0.
        onSight = NO;                           // Default NO.
        edgeFlipWidth = 0.1;                    // Default 0.1.
        
        self.userInteractionEnabled = YES;
        
        self.lastLeftVideoControllerPage = 0;   // Default 0.
        self.lastRightVideoControllerPage = 0;  // Default 0.
        
        frame.origin = CGPointZero;
        
        anIntermediateView = [[FPKIntermediateView alloc]initWithFrame:frame];
        [anIntermediateView setOpaque:NO];
        [anIntermediateView setAutoresizesSubviews:YES];
        [anIntermediateView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];

        [self addSubview:anIntermediateView];
        self.intermediateView = anIntermediateView;

        
        aScrollView = [[MFScrollDetailView alloc]initWithFrame:frame];
        
        if(delegate.overflowEnabled && leftPage!=0) {
            
            CGRect cropbox;
            int angle;
            int pos = (leftPage-1); // TODO: take direction into account;
            CGRect contentFrame;
            [[delegate document]getCropbox:&cropbox andRotation:&angle forPageNumber:leftPage withBuffer:NO];
            
            // TODO: fix this
            contentFrame = frameForLayer(frame.size, cropbox, angle, pos);
            
            frame.size = contentFrame.size;
            frame.origin = CGPointZero;
        }
        
        [aScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollView setAutoresizesSubviews:YES];
        [aScrollView setDelegate:self];
        [aScrollView setContentSize:CGSizeMake(frame.size.width,frame.size.height)];
        [aScrollView setMinimumZoomScale:1.0];
        
        float maxZoomScale = [delegate defaultMaxZoomScale];
        
        if(maxZoomScale > 0.0) {
            [aScrollView setMaximumZoomScale:maxZoomScale];
        } else {
            [aScrollView setMaximumZoomScale:FPK_DEF_MAX_ZOOM];
        }
        
        [aScrollView setAlwaysBounceHorizontal:NO];
        [aScrollView setDirectionalLockEnabled:NO];
        [aScrollView setScrollEnabled:YES];
        
        [intermediateView addSubview:aScrollView];
        self.scrollDetailView = aScrollView;
        
        // [self buildContainerViewForFrame:frame];
    }
    
    return self;
}

/*
 // OLD
-(void)resetContents {
    
    // return;
    
    CGRect frame = [scrollDetailView frame];
	frame.origin = CGPointZero;
    
    [self removeOverlayViews];    // Necessary to send will/didRemove messages to the views before they are destroyed.
	    
    [scrollDetailView setZoomScale:1.0 animated:NO]; // Reset the scroll detail view and its content.
	[scrollDetailView setContentOffset:CGPointZero animated:NO];
    
    self.leftAnnotations = nil;
	self.rightAnnotations = nil;
	self.leftDrawables = nil;
	self.rightDrawables = nil;
	
	renderInfo.initialized = NO;
    
	// [self buildContainerViewForFrame:frame];
    
    [self setNeedsDisplay];
    
}
*/

-(void)invalidateRenderInfo {
    
    renderInfo.initialized = NO;
    counter++;
    [tiledView setNeedsDisplay];
    [overlayView setNeedsDisplay];
}

-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGRect containerFrame = self.bounds;
    CGRect contentFrame = CGRectZero;
    
    [intermediateView setFrame:containerFrame];
    
    if(!tiledView) {
        [self buildContainerViewForFrame:containerFrame];
    }
    
    if((pageMode == MFDocumentModeOverflow) && leftPage!=0) {
        
        CGRect cropbox;
        CGRect tmpFrame;
        
        int angle;
        int pos = (leftPage-1); // TODO: take direction into account;
        
        [[delegate document]getCropbox:&cropbox andRotation:&angle forPageNumber:leftPage withBuffer:NO];
        
        if(!CGRectIsEmpty(cropbox)) {
            tmpFrame = frameForLayer(containerFrame.size, cropbox, angle, pos);
            contentFrame.size = tmpFrame.size;
        } else {
            contentFrame = containerFrame;
        }
        
    } else {
            
        contentFrame = containerFrame;
    }
    
    [scrollDetailView setContentSize:contentFrame.size];
    
    [[tiledView layer]setContents:nil];
    
    renderInfo.initialized = NO;
    counter++;
    
    [containerView setFrame:contentFrame];
    [[tiledView layer]setNeedsDisplay];
    [[overlayView layer]setNeedsDisplay];
}


- (void)dealloc {
    
#if FPK_DEALLOC
    NSLog(@"%@ - dealloc",NSStringFromClass([self class]));
#endif
    
//    [self.moviePlayerController stop];
//    [moviePlayerController release];
//    
    
    // Subviews.
    
    [tiledView setDelegate:nil];
	
    // Scrollview.
	[scrollDetailView setDelegate:nil];
    
	
}

@end
