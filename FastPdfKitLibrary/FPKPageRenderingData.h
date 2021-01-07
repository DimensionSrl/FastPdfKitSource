//
//  MFPageData.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "FPKPageMetrics.h"

@interface FPKPageData : NSObject <FPKMetrics>

@property (nonatomic, strong) FPKPageMetrics * metrics;
@property (nonatomic, readwrite) NSUInteger page;

+(FPKPageData *)zeroData;
+(FPKPageData *)dataWithPage:(NSUInteger)page metrics:(FPKPageMetrics *)metrics;

@end

@interface FPKPageRenderingData : NSObject <FPKMetrics>

@property (nonatomic, readonly) FPKPageData * data;

@property (nonatomic, strong) UIImage * ui_image;
@property (nonatomic, readwrite, getter = isThumb) BOOL thumb;
@property (nonatomic, strong) NSDictionary * description;

+(FPKPageRenderingData *)zeroData;
+(FPKPageRenderingData *)dataWithPage:(NSUInteger)page metrics:(FPKPageMetrics *)metrics;
+(FPKPageRenderingData *)dataWithData:(FPKPageData *)data;

@end

@interface MFPageDataOldEngine : NSObject {
    
    CGImageRef image;
}

-(void)setImage:(CGImageRef)image;
-(CGImageRef)image;

-(BOOL)isEqualToPageData:(MFPageDataOldEngine *)other;

@property (nonatomic, readwrite) BOOL legacy;
@property (nonatomic, readwrite) NSUInteger mode;
@property (nonatomic, readwrite) BOOL shadow;
@property (nonatomic, readwrite) float padding;
@property (nonatomic, readwrite) NSUInteger left;
@property (nonatomic, readwrite) NSUInteger right;
@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) int angle;
@property (nonatomic, readwrite) CGRect cropbox;
@property (nonatomic, strong) NSNumber * operationId;
@end
