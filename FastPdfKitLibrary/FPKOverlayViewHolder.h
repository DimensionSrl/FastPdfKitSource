//
//  FPKOverlayWrapper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 28/11/14.
//
//

#import <Foundation/Foundation.h>
#import "MFOverlayView.h"
#import "FPKOverlayViewDataSource.h"

/*!
 POCO holding an overlay view and other useful parameter for it.
 */
@interface FPKOverlayViewHolder : NSObject

/*!
 The UIView to display as overlay.
 */
@property (nonatomic, strong) UIView * view;

/*!
 The rect (PDF Coordinate System) for the overlay view.
 */
@property (nonatomic, readwrite) CGRect rect;

/*!
 Owner of this FPKOverlayWrapper.
 */
@property (nonatomic, weak) id<FPKOverlayViewDelegate_Private> owner;

/*!
 Where the UIView comes from.
 */
@property (nonatomic, weak) id<FPKOverlayViewDataSource> dataSource;

/*!
 YES if the view coordinates are in PDF Coordinates System, NO if they are in
 UI space.
 */
@property (nonatomic, readwrite) BOOL pdfCoordinates;

@end
