//
//  MFRemoteLinkAnnotation.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MFRemoteLinkAnnotation.h"

@implementation MFRemoteLinkAnnotation

-(void)dealloc {

    [_document release];
    [_destination release];
    
    [super dealloc];
}

@end
