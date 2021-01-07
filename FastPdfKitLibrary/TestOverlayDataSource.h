//
//  TestOverlayDataSource.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/05/15.
//
//

#import <Foundation/Foundation.h>
#import "MFDocumentOverlayDataSource.h"
#import "MFOverlayDrawable.h"
#import "MFOverlayTouchable.h"

@interface TestDrawable : NSObject<MFOverlayDrawable, MFOverlayTouchable>

@property (nonatomic, copy) UIColor * color;
@property (nonatomic, readwrite) CGRect rect;
@property (nonatomic, copy) NSString * text;
@end

@interface TestOverlayDataSource : NSObject <MFDocumentOverlayDataSource>

@end
