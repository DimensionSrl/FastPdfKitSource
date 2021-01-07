//
//  MFAnnotation.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 11/14/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFAnnotation.h"

@implementation MFAnnotation

-(BOOL)containsPoint:(CGPoint)point {
	
	return CGRectContainsPoint(_rect, point);
}

@end
