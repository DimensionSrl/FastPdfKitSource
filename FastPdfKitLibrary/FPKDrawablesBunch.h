//
//  FPKDrawablesBunch.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/11/15.
//
//

#import <Foundation/Foundation.h>

@protocol FPKDrawablesBunchDrawer <NSObject>

-(void)drawDrawables:(NSArray *)drawable context:(CGContextRef)ctx;

@end

/*!
 FPKDrawablesBunchDrawer for drawing MFDrawables defined in a coordinates system
 with the origin on the lower left a.k.a. PDF coordinate system.
 */
@interface FPKDrawablesBunchDrawerPDFCoordinates :  NSObject <FPKDrawablesBunchDrawer>

@end

/*!
 FPKDrawablesBunchDrawer for drawing MFDrawables defined in a coordinates system
 with the origin on the upper left.
 */
@interface FPKDrawablesBunchDrawerBase :  NSObject <FPKDrawablesBunchDrawer>

@end

/*!
 FPKDrawablesBunch holds and draws a bunch of MFDrawables. 
 
 The associated FPKDrawablesBunchDrawer is responsible for actually drawing the 
 objects.
 */
@interface FPKDrawablesBunch : NSObject

@property (nonatomic, strong) id<FPKDrawablesBunchDrawer> drawer;

@property (nonatomic, strong) NSArray * drawables;

-(void)drawInContext:(CGContextRef) ctx;

@end
