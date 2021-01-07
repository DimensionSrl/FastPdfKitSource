//
//  MFFPKAnnotation.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFFPKAnnotation.h"


@implementation MFFPKAnnotation

-(void)dealloc {
    
    [_originalUri release];
    [_url release];
    
    [super dealloc];
}

@end
