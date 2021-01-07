//
//  FPKURIAnnotation.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 10/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FPKURIAnnotation.h"

@implementation FPKURIAnnotation

-(void)dealloc {
    [_uri release];
    [super dealloc];
}
@end
