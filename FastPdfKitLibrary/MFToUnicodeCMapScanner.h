//
//  MFToUnicodeCMapScanner.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 1/28/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "mffontencoding.h"

@interface MFToUnicodeCMapScanner : NSObject {

	CGPDFStreamRef cmapStream;
	MFFontEncoder * encoder;
}

@property (nonatomic,assign) CGPDFStreamRef cmapStream;
@property (nonatomic,assign) MFFontEncoder * encoder;

-(void)scan;

@end
