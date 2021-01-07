//
//  MFFontData.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGAffineTransform.h>
#import "mffontencoding.h"

@class MFWidthCluster;
@class MFUnicodeCluster;
@class MFCIDCluster;

extern void int_to_bytes(int value, unsigned char * bytes);
extern int bytes_to_int(const unsigned char * bytes, int len);

@interface MFFontData : NSObject {
	
	unsigned int lastChar;
	unsigned int firstChar;
	CGFloat widths [256];
	CGFloat ascent;
	CGFloat descent;
	CGFloat missingWidth;
	
    CGFloat averageWidth;
    int averageWidthCalculated;
    
    unsigned short type;
    
	MFFontEncoder * encoder;
	
	BOOL valid;
}

@property (readwrite,assign) MFFontEncoder * encoder;
@property (readwrite,assign) unsigned int firstChar;
@property (readwrite,assign) unsigned int lastChar;
@property (readwrite,assign) CGFloat ascent;
@property (readwrite,assign) CGFloat descent;
@property (readwrite,assign) CGFloat missingWidth;
@property (readwrite,getter=isValid) BOOL valid;

-(void)setWidths:(CGFloat *)wds length:(unsigned int)wdsLength;
-(void)sizesForCharacterCode:(unsigned int)cCode width:(CGFloat *)width ascent:(CGFloat *)asc andDescent:(CGFloat *)dsc;
-(CGRect)boxForCharacterCode:(unsigned int)cCode;
-(float)widthForCharacterCode:(unsigned int)cCode;

-(unsigned int *)unicodeForCharacterCode:(unsigned int)cCode length:(int *)length;

-(CGRect)boxForCharacterWidth:(CGFloat)width;
-(CGFloat)averageWidth;
-(int)getCid:(unsigned int *) cid fromByteSequence:(const unsigned char *)sequence;

@end


@interface MFFontDataType0 : MFFontData {
    
    MFUnicodeCluster * unicodeRanges;
    MFCIDCluster * cidRanges;
    MFCIDCluster * undefinedCids;
    MFWidthCluster * widthRanges;
    
    CGFloat defaultWidth;
    int writingMode;
}
@property (readwrite) CGFloat defaultWidth;
@property (readonly) MFUnicodeCluster * unicodeRanges;
@property (readonly) MFCIDCluster * cidRanges;
@property (readonly) MFWidthCluster * widthRanges;
@property (readonly) MFCIDCluster * undefinedCids;
@property (nonatomic, readwrite) int writingMode;
@end


@interface MFFontDataType1 : MFFontData

@end


@interface MFFontDataTrueType : MFFontData 


@end


@interface MFFontDataType3 : MFFontData {
	
	CGAffineTransform matrix;
	
}

@property (readwrite) CGAffineTransform matrix;

@end
