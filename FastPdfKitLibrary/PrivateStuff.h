//
//  PrivateStuff.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 7/1/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "Stuff.h"
#import <mach/mach_host.h>

#define FPK_PDF_TO_QUARTZ_ANGLE(x) degreesToRadians(normalize_angle(-(x)))

enum MFDeferredRenderMode {
	MFDeferredRenderModePageSingle = 1,
	MFDeferredRenderModePageDouble = 2
};
typedef NSUInteger MFDeferredRenderMode;

typedef struct MFRenderInfo {
    
    NSUInteger leftPage;
    NSUInteger rightPage;
    CGSize size;
    MFDeferredRenderMode mode;
    BOOL shadow;
    BOOL legacy;
    
} MFRenderInfo;

static inline NSInteger normalize_angle(const NSInteger degs) {
    int result = degs % 360;
    return result < 0 ? result + 360 : result;
}

static inline NSInteger ensureIsValidPdfRotationAngle(NSInteger angle) {
    NSInteger a = (angle % 90 == 0) ? angle : 0;
    a = normalize_angle(a);
    return a;
}

static inline NSUInteger pageForDirection(NSUInteger pageNumber,
                                          NSUInteger numberOfPages,
                                          MFDocumentDirection direction)
{
    if(direction == MFDocumentDirectionL2R) {
        return pageNumber;
    } else if (direction == MFDocumentDirectionR2L) {
        return numberOfPages-pageNumber+1;
    } else {
        return 0;
    }
}

static inline float radiansToDegrees(float rads) {
    return rads * 180.0f / M_PI;
}

static inline float degreesToRadians(float degs) {
    //return ((fmod(degs, 360.0)) / 180.0) * M_PI;
    return degs * M_PI / 180.0f;
}

static unsigned int countCores() {
    host_basic_info_data_t hostInfo;
    mach_msg_type_number_t infoCount;
    
    infoCount = HOST_BASIC_INFO_COUNT;
    host_info(mach_host_self(), HOST_BASIC_INFO, 
              (host_info_t)&hostInfo, &infoCount);
    
    return (unsigned int)(hostInfo.max_cpus);
}

static inline CGRect frameForLayer(CGSize screenSize, CGRect cropbox, int angle, int pos) {
    
    if(CGRectIsEmpty(cropbox))
        return CGRectZero;
    
    CGRect frame = CGRectZero;
    CGRect rotatedCropbox = CGRectZero; // Cropbox normalized for rotation.
    
    int normalizedAngle = (angle + 360) % 360;
    if(normalizedAngle == 90 || normalizedAngle == 270) {
        
        rotatedCropbox.size.width = cropbox.size.height;
        rotatedCropbox.size.height = cropbox.size.width;
        
    } else {
        
        rotatedCropbox.size = cropbox.size;
    }
    
    CGFloat ratio = screenSize.width/rotatedCropbox.size.width;
    
    //frame.size = rotatedCropbox.size;
    frame.size.width = screenSize.width; // Always
    frame.size.height = MAX(rotatedCropbox.size.height * ratio, screenSize.height);
    
//    if((frame.size.height = floorf(frame.size.height * ratio)) <= screenSize.height) {
//        
//        return rectForPosition(pos, screenSize);
//    }
    
    
    frame.origin = CGPointMake(pos * screenSize.width, 0);
    
    // NSLog(@"(%d) %@ inside %@ -> %@ [%d]",pos,NSStringFromCGRect(cropbox),NSStringFromCGSize(screenSize),NSStringFromCGRect(frame),angle);
    
    return frame;
}

static CGFloat transformVerticalScale(CGAffineTransform transform) {
    
    CGFloat scale = transform.a;
    if(!(transform.b == 0.0 && transform.c)) {
        scale = sqrtf(powf(transform.c, 2) +
                      powf(transform.d, 2));
    }
    return scale;
}

static CGFloat transformHorizontalScale(CGAffineTransform transform) {
    CGFloat scale = transform.a;
    if(!(transform.b == 0.0 && transform.c)) {
        scale = sqrtf(powf(transform.a, 2) +
                      powf(transform.b, 2));
    }
    return scale;
}

static const CGFloat RADIANS_0_DEG = 0;
static const CGFloat RADIANS_90_DEG = M_PI * 0.5;
static const CGFloat RADIANS_180_DEG = M_PI;
static const CGFloat RADIANS_270_DEG = M_PI * 1.5;

static inline CGFloat fastDegreesToRadians(NSInteger degrees) {
    switch(degrees) {
        case 0:
            return RADIANS_0_DEG;
        case 90:
            return RADIANS_90_DEG;
        case 180:
            return RADIANS_180_DEG;
        case 270:
            return RADIANS_270_DEG;
        default:
            return degreesToRadians(degrees);
    }
}

static inline CGPoint adjustedRotationCenter(NSInteger angle, CGSize cropbox) {
    
    CGPoint rotationCenter = CGPointZero;
    
    switch(angle) {
        case 90:
            rotationCenter.y = cropbox.height;
            break;
        case 180:
            rotationCenter.x = cropbox.width;
            rotationCenter.y = cropbox.height;
            break;
        case 270:
            rotationCenter.x = cropbox.width;
            break;
    }
    
    return rotationCenter;
}

static inline void transformAndBoxForPageRenderingRight(CGAffineTransform * rTransform,
                                                        CGRect *rBox,
                                                        CGSize containerSize,
                                                        CGRect rCropbox,
                                                        NSInteger rAngle,
                                                        CGFloat containerPadding,
                                                        BOOL flip) {
    
    if(rTransform == NULL && rBox == NULL) {
        return;
    }
    
    if(CGSizeEqualToSize(containerSize, CGSizeZero)) {
        if(rBox != NULL) {
            *rBox = CGRectZero;
        }
        if(rTransform != NULL) {
            *rTransform = CGAffineTransformIdentity;
        }
        return;
    }
    
    if(CGRectIsEmpty(rCropbox)||CGRectIsNull(rCropbox)) {
        if(rBox!=NULL) {
            *rBox = CGRectZero;
        }
        
        if(rTransform!=NULL) {
            *rTransform = CGAffineTransformIdentity;
        }
        return;
    }
    
    CGAffineTransform flipTransform = CGAffineTransformIdentity;
    if(flip) {
        flipTransform = CGAffineTransformMakeScale(1, -1);
        flipTransform = CGAffineTransformTranslate(flipTransform, 0, -containerSize.height);
    }
    
    NSInteger rotation = ensureIsValidPdfRotationAngle(rAngle);
    
    CGSize rightHalfContainerSize = containerSize;
    rightHalfContainerSize.width = containerSize.width * 0.5;
    rightHalfContainerSize.height -= containerPadding * 2;
    rightHalfContainerSize.width -= containerPadding;
    
    // Flip width/height for 90 and 270 degrees rotation.
    CGSize normalizedCropboxSize = (rotation == 90 || rotation == 270) ? CGSizeMake(rCropbox.size.height, rCropbox.size.width) : rCropbox.size;
    
    CGFloat ratioH = rightHalfContainerSize.width / normalizedCropboxSize.width;
    CGFloat ratioV = rightHalfContainerSize.height / normalizedCropboxSize.height;
    CGFloat ratioMin = fminf(ratioH, ratioV);
    
    CGSize paddedCropboxSize = normalizedCropboxSize;
    paddedCropboxSize.width = normalizedCropboxSize.width * ratioMin;
    paddedCropboxSize.height = normalizedCropboxSize.height * ratioMin;
    
    CGFloat rDeltaX = containerSize.width * 0.5;
    CGFloat rDeltaY = containerPadding + ((rightHalfContainerSize.height - paddedCropboxSize.height) * 0.5);
    
    CGRect paddedCropbox;
    paddedCropbox.size = paddedCropboxSize;
    paddedCropbox.origin.x = rDeltaX;
    paddedCropbox.origin.y = rDeltaY;
    
    if(rBox) {
        *rBox = CGRectApplyAffineTransform(paddedCropbox, flipTransform);
    }
    
    CGPoint rotationCenter = adjustedRotationCenter(rotation, paddedCropboxSize);
    
    if(rTransform) {
        
        CGAffineTransform pageTransform = flipTransform;
        CGFloat dx = rDeltaX + rotationCenter.x;
        CGFloat dy = rDeltaY + rotationCenter.y;
        pageTransform = CGAffineTransformTranslate(pageTransform, dx, dy);
        pageTransform = CGAffineTransformScale(pageTransform, ratioMin, ratioMin);
        pageTransform = CGAffineTransformRotate(pageTransform, -fastDegreesToRadians(rotation));
        pageTransform = CGAffineTransformTranslate(pageTransform, -rCropbox.origin.x, -rCropbox.origin.y);
        
        *rTransform = pageTransform;
    }
}

static inline void transformAndBoxForPageRenderingLeft(CGAffineTransform * lTransform,
                                                       CGRect *lBox,
                                                       CGSize containerSize,
                                                       CGRect lCropbox,
                                                       NSInteger lAngle,
                                                       CGFloat containerPadding,
                                                       BOOL flip) {
    if(lTransform == NULL && lBox == NULL) {
        return;
    }
    
    if(CGSizeEqualToSize(containerSize, CGSizeZero)) {
        if(lBox != NULL) {
            *lBox = CGRectZero;
        }
        if(lTransform != NULL) {
            *lTransform = CGAffineTransformIdentity;
        }
        return;
    }
    
    // Calculate the two subframes.
  
    
    CGAffineTransform lPageTransform;
    
    CGAffineTransform flipTransform = CGAffineTransformIdentity;
    if(flip) {
        
        /*
         Invert the origin on the vertical axis.
         
         This is usually done to have the coordinates in an origin on the bottom
         left, because all the other parameters are passed in an origin on the
         top left coordinate system.
         */
        
        flipTransform = CGAffineTransformMakeScale(1, -1);
        flipTransform = CGAffineTransformTranslate(flipTransform, 0, -containerSize.height);
    }
    
    if(CGRectIsEmpty(lCropbox)||CGRectIsNull(lCropbox)) {
        if(lBox!=NULL) {
            *lBox = CGRectZero;
        }
        
        if(lTransform!=NULL) {
            *lTransform = CGAffineTransformIdentity;
        }
        return;
    }
    
    NSInteger rotation = ensureIsValidPdfRotationAngle(lAngle);
    
    CGFloat lWidth = containerSize.width * 0.5;
    CGSize lHalfSize = containerSize;
    
    lHalfSize.width = lWidth;
    lHalfSize.height -= containerPadding * 2.0;
    lHalfSize.width -= containerPadding;
    
    CGSize normCropboxSize = (rotation == 90 || rotation == 270) ? CGSizeMake(lCropbox.size.height, lCropbox.size.width) : lCropbox.size;
    
    // Calculate the rect in frame for the left page.
    
    CGFloat lRatioH = lHalfSize.width / normCropboxSize.width;
    CGFloat lRatioV = lHalfSize.height / normCropboxSize.height;
    CGFloat lRatioMin = fminf(lRatioH, lRatioV);
    
    CGSize paddedCropboxSize = normCropboxSize;
    paddedCropboxSize.width = normCropboxSize.width * lRatioMin;
    paddedCropboxSize.height = normCropboxSize.height * lRatioMin;
    
    CGFloat deltaX = containerPadding + (lHalfSize.width - paddedCropboxSize.width);
    CGFloat deltaY = containerPadding + ((lHalfSize.height - paddedCropboxSize.height) * 0.5);
    
    CGRect paddedCropbox;
    paddedCropbox.size = paddedCropboxSize;
    paddedCropbox.origin.x = deltaX;
    paddedCropbox.origin.y = deltaY;
    
    if(lBox) {
        *lBox = CGRectApplyAffineTransform(paddedCropbox, flipTransform);
    }
    
    CGPoint rotationCenter = adjustedRotationCenter(rotation, paddedCropboxSize);
    
    if(lTransform) {
        
        lPageTransform = flipTransform;
        lPageTransform = CGAffineTransformTranslate(lPageTransform, deltaX+rotationCenter.x, deltaY+rotationCenter.y);
        lPageTransform = CGAffineTransformScale(lPageTransform, lRatioMin, lRatioMin);
        lPageTransform = CGAffineTransformRotate(lPageTransform, -fastDegreesToRadians(rotation));
        lPageTransform = CGAffineTransformTranslate(lPageTransform, -lCropbox.origin.x, -lCropbox.origin.y);
        
        *lTransform = lPageTransform;
    }
}

static inline CGPoint FPKReversedAnnotationPoint(CGPoint point, CGFloat pageHeight) {
    CGPoint result;
    result.x = point.x;
    result.y = pageHeight - point.y;
    return result;
}

static inline CGRect FPKReversedAnnotationRect(CGRect rect, CGFloat pageHeight) {
    CGRect result;
    result.origin.x = rect.origin.x;
    result.origin.y = pageHeight - (rect.size.height + rect.origin.y);
    result.size = rect.size;
    return result;
}

/*!
 Calculate useful values to convert pdf page coordinates in view coordinates.
 
 @param lTransform Will contain the left transform.
 
 @param rTransform Will contain the right transform.
 
 @param lBox Will contain the frame of the left page.
 
 @param rBox Will contain the frame of the right page.
 
 @param containerSize Pass the frame of the container.
 
 @param lCropbox The cropbox of the left page.
 
 @param rCropbox The cropbox of the right page.
 
 @param lAngle The rotation of the left page.
 
 @param rAngle The rotation of the right page.
 
 @param containerPadding The padding in the container.
 
 @param flip Pass true to have values returned in a coordinate system with
 origin on the bottom left (i.e. for use in a CGContext).
 
 */
static inline void transformAndBoxForPagesRendering(CGAffineTransform * lTransform,
                                                    CGAffineTransform * rTransform,
                                                    CGRect * lBox,
                                                    CGRect *rBox,
                                                    CGSize containerSize,
                                                    CGRect lCropbox,
                                                    CGRect rCropbox,
                                                    NSInteger lAngle,
                                                    NSInteger rAngle,
                                                    CGFloat containerPadding,
                                                    BOOL flip) {
    
    transformAndBoxForPageRenderingLeft(lTransform, lBox,containerSize,lCropbox,lAngle,containerPadding,flip);
    transformAndBoxForPageRenderingRight(rTransform,rBox,containerSize,rCropbox,rAngle,containerPadding,flip);
}


/*!
 Calculate useful values to convert pdf page coordinates in view coordinates.
 
 @param transform Will contain the transform.
 
 @param box Will contain the frame of the right page.
 
 @param containerSize Pass the frame of the container.
 
 @param cropbox The cropbox of the left page.
 
 @param angle The rotation of the page.
 
 @param containerPadding The padding in the container.
 
 @param flip Pass true to have values returned in a coordinate system with
 origin on the bottom left (i.e. for use in a CGContext).
 
 */
static inline void transformAndBoxForPageRendering(CGAffineTransform * transform,
                                                   CGRect * box,
                                                   CGSize containerSize,
                                                   CGRect cropbox,
                                                   NSInteger angle,
                                                   CGFloat containerPadding,
                                                   BOOL flip) {
    
    if(transform == NULL && box == NULL) {
        return;
    }
    
    if(CGSizeEqualToSize(containerSize, CGSizeZero)) {
        if(box != NULL) {
            *box = CGRectZero;
        }
        if(transform != NULL) {
            *transform = CGAffineTransformIdentity;
        }
        return;
    }
    
    angle = ensureIsValidPdfRotationAngle(angle);
    
    CGAffineTransform flipTransfrom = CGAffineTransformIdentity;
    if(flip) {
        flipTransfrom = CGAffineTransformMakeScale(1, -1);
        flipTransfrom = CGAffineTransformTranslate(flipTransfrom, 0, -containerSize.height);
    }
    
    CGSize rotationNormalizedCropboxSize;   // Normalized for page rotation.
    if(angle == 90 || angle == 270) {
        
        rotationNormalizedCropboxSize = CGSizeMake(cropbox.size.height, cropbox.size.width);
        
    } else {
        
        rotationNormalizedCropboxSize = cropbox.size;
    }
    
    // Round up the cropbox
    cropbox.size = CGSizeMake(floorf(cropbox.size.width), floorf(cropbox.size.height));
    cropbox.origin = CGPointMake(floorf(cropbox.origin.x), floorf(cropbox.origin.y));
    
    // Actual content area (view - padding)
    CGSize paddedFrameSize = CGSizeMake(containerSize.width - containerPadding * 2.0f, containerSize.height - containerPadding * 2.0f);
    
    // Scaling
    CGFloat frameToCropboxRatioH = paddedFrameSize.width / rotationNormalizedCropboxSize.width;
    CGFloat frameToCropboxRatioV = paddedFrameSize.height / rotationNormalizedCropboxSize.height;
    CGFloat frameToCropboxRatioMin = fminf(frameToCropboxRatioH, frameToCropboxRatioV);
    
    // Calculate padded cropbox size, this will give at least <padding> pixel of padding
    CGSize paddedCropboxSize = rotationNormalizedCropboxSize;
    paddedCropboxSize.width = paddedCropboxSize.width * frameToCropboxRatioMin;
    paddedCropboxSize.height = paddedCropboxSize.height * frameToCropboxRatioMin;
    
    // Calculate padded cropbox offest in the frame.
    CGFloat paddedCropboxOffsetX = containerPadding + ((paddedFrameSize.width - paddedCropboxSize.width) * 0.5f);
    CGFloat paddedCropboxOffsetY = containerPadding + ((paddedFrameSize.height - paddedCropboxSize.height) * 0.5f);
    
    // The rect where the page will be draw in the context.
    CGRect drawFrame = CGRectZero;
    drawFrame.size = paddedCropboxSize;
    drawFrame.origin.x = paddedCropboxOffsetX;
    drawFrame.origin.y = paddedCropboxOffsetY;
    
    if(box!=NULL) {
        *box = CGRectApplyAffineTransform(drawFrame, flipTransfrom); // Assign the calculated page rect to the box. This rect can be used to draw the white page and the underlaying shadow.
    }
    
    // This is the transform that convert the page coordinates to view coordinates. We need to calculate it only if requested.
    if(transform!=NULL) {
        
        CGPoint rotationCenter = adjustedRotationCenter(angle, paddedCropboxSize);
        CGAffineTransform drawTransform = flipTransfrom;
        drawTransform = CGAffineTransformTranslate(drawTransform, paddedCropboxOffsetX + rotationCenter.x, paddedCropboxOffsetY + rotationCenter.y);
        drawTransform = CGAffineTransformScale(drawTransform, frameToCropboxRatioMin, frameToCropboxRatioMin);
        drawTransform = CGAffineTransformRotate(drawTransform, -fastDegreesToRadians(angle));
        drawTransform = CGAffineTransformTranslate(drawTransform, -cropbox.origin.x, -cropbox.origin.y);
        *transform = drawTransform;
    }
}

#pragma mark - From Stuff.h


static inline NSInteger pageNumberForPosition(NSInteger position) {
	return position+1;
}

static inline CGSize sizeForContent(NSInteger numberOfPages, CGSize pageSize) {
	
    CGSize size;
    
    CGFloat contentHeight = pageSize.height;
	CGFloat contentWidth = numberOfPages * pageSize.width;
	
    size = CGSizeMake(contentWidth, contentHeight);
    
    return size;
}

static inline NSUInteger numberOfPositions(NSUInteger numberOfPages, MFDocumentMode pagesForPositions, MFDocumentLead lead) {
	
	NSInteger nrOfPos = 0;
	if(pagesForPositions == MFDocumentModeSingle || pagesForPositions == MFDocumentModeOverflow){
		
		nrOfPos = numberOfPages;
		
	} else if (pagesForPositions == MFDocumentModeDouble) {
		
		if(lead == MFDocumentLeadLeft) {
			
			nrOfPos = ceil((double)numberOfPages*0.5);
			
		} else if (lead == MFDocumentLeadRight) {
			nrOfPos = ceil(((double)numberOfPages+1.0)*0.5); 
		}
	}
	return nrOfPos;
}

static inline NSInteger positionForPage(NSUInteger page, MFDocumentMode mode, MFDocumentLead lead, MFDocumentDirection direction, NSUInteger maxPages) {
	
    NSInteger pos = 0;
	
	if(direction == MFDocumentDirectionL2R) {
		// Page will remain the same
	} else if (direction == MFDocumentDirectionR2L) {
		page = maxPages-page+1;
	}
	
	if(mode == MFDocumentModeSingle || mode == MFDocumentModeOverflow) {
		pos = page-1;
	} else if (mode == MFDocumentModeDouble) {
		if(lead == MFDocumentLeadLeft) {
			pos = (ceil((double)page * 0.5))-1;
		} else if (lead == MFDocumentLeadRight) {
			pos = (floor((double)page * 0.5));
		}
	}
	return pos;
}


static inline NSUInteger leftPageForPosition(NSInteger position, MFDocumentMode mode, MFDocumentLead lead, MFDocumentDirection direction, NSUInteger maxPages) {
	
	NSInteger page = 0;
	
	if(mode == MFDocumentModeSingle || mode == MFDocumentModeOverflow) {
		page = position+1;
	} else if (mode == MFDocumentModeDouble) {
		
		if(lead == MFDocumentLeadLeft) {
			page = position * 2 + 1;
		} else if (lead == MFDocumentLeadRight) {
			page = position * 2 + 0;
		}
	}
	
	if(page < 0 || page > maxPages) {
		page = 0;
	}
	
	if(direction == MFDocumentDirectionR2L) {
		page = maxPages-page+1;
	}
	
	return page;
}

static inline NSUInteger rightPageForPosition(NSInteger position, MFDocumentMode mode, MFDocumentLead lead, MFDocumentDirection direction, NSUInteger maxPages) {
	
	NSInteger page = 0;
	
	if(mode == MFDocumentModeSingle || mode == MFDocumentModeOverflow) {
		page = 0;
	} else if (mode == MFDocumentModeDouble) {
		
        if(lead == MFDocumentLeadLeft) {
            page = position * 2 + 2;
        } else if (lead == MFDocumentLeadRight) {
            page = position * 2 + 1;
        }
	}
	
	if(page < 0 || page > maxPages) {
		page = 0;
	}
	
	if(direction == MFDocumentDirectionR2L) {
		page = maxPages-page+1;
	}
	
	return page;
}

// Return the smallest pages displayed, ranging between 1 and maxPages
static inline NSUInteger pageForPosition(NSInteger position, MFDocumentMode mode, MFDocumentLead lead, MFDocumentDirection direction, NSUInteger maxPages) {
	
	NSInteger page = 0;
	
	if(mode == MFDocumentModeSingle || mode == MFDocumentModeOverflow) {
		page = position+1;
	} else if (mode == MFDocumentModeDouble) {
		if(lead == MFDocumentLeadLeft) {
			page = position * 2 + 1;
		} else if (lead == MFDocumentLeadRight) {
			page = position * 2;
		}
	}
 	
	if(page <= 0)
		page = 1;
	if(page > maxPages)
		page = maxPages;
	
	if(direction == MFDocumentDirectionR2L) {
		page = maxPages-page+1;
	}
	
	return page;
	
}

static inline CGRect rectForPosition(NSInteger position, CGSize pageSize) {
	
	return CGRectMake(position * pageSize.width, 0, pageSize.width, pageSize.height);
	
}
