//
//  MFSearchItem.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/25/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFTextItem.h"
#import <UIKit/UIKit.h>

@implementation MFTextItem

-(id)initWithText:(NSString *)someText andHighlightPath:(CGPathRef)aPath {
	
    if((self = [super init])) {
        
		_text = [someText copy];
		_highlightPath = CGPathCreateCopy(aPath);
		_page = 0;
	}
    
	return self;
}

-(id)initWithText:(NSString *)someText highlightPath:(CGPathRef)aPath andPage:(NSUInteger)aPage {
    
    if((self = [super init])) {
        
		_text = [someText copy];
		_highlightPath = CGPathCreateCopy(aPath);
		_page = aPage;
	}
    
	return self;
}

-(void)dealloc {
    CGPathRelease(_highlightPath);
}

@end
