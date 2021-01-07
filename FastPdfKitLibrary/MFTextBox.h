//
//  MFTextBox.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class FPKTextBuffer;

@interface MFGlyphQuad : NSObject
-(id)init;
-(id)initWithX:(float)x Y:(float)y width:(float)w height:(float)h andTranfrom:(CGAffineTransform *)aTransform;
-(id)initWithBox:(CGRect *) aBox andTranfrom:(CGAffineTransform *)aTransform;
-(void)extendBox:(CGRect)anotherBox;

@property (readwrite,assign) CGAffineTransform transform;
@property (readwrite,assign) CGRect box;


@end

@interface MFTextBox : NSObject {
    
    NSString *text;
    NSMutableArray * quads;
    unsigned int startPosition;
    unsigned int endPosition;
    NSRange searchTermRange;
    BOOL completed;
}

-(void)addGlyphQuad:(MFGlyphQuad *)quad;
-(void)discardLastGlyphQuad;
-(MFGlyphQuad *)lastGlyphQuad;

-(void)sampleTextFromUnicodeBuffer:(FPKTextBuffer *)buffer;
-(void) sampleTextFromUnicodeBuffer:(unsigned int *)buffer length:(int)length;

@property(nonatomic,readwrite)BOOL completed;
@property(nonatomic,copy)NSString *text;
@property(nonatomic,retain)NSMutableArray * quads;
@property(nonatomic,readwrite)unsigned int startPosition;
@property(nonatomic,readwrite)unsigned int endPosition;
@property (nonatomic,readwrite) NSRange searchTermRange;
@end
