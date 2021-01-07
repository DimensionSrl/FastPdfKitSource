//
//  MFURIAnnotation.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 11/14/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFURIAnnotation.h"

@implementation MFURIAnnotation

-(void)dealloc {
	[_uri release], _uri = nil;
	[super dealloc];
}

-(FPKURIAnnotation *)annotation {
    FPKURIAnnotation * annotation = [[FPKURIAnnotation alloc]init];
    annotation.uri = self.uri;
    annotation.rect = self.rect;
    return [annotation autorelease];
}

@end
