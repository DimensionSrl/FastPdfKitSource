//
//  FPKOverlayViewDataSource_Private.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/05/15.
//
//

@class MFOverlayView;

@protocol FPKOverlayViewDataSource_Private

-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page;

@end