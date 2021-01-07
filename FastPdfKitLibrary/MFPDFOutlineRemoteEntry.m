//
//  MFPDFOutlineRemoteEntry.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFPDFOutlineRemoteEntry.h"

@implementation MFPDFOutlineRemoteEntry

@synthesize destination;
@synthesize file;

-(id)initWithTitle:(NSString *)entryTitle {
    
    self = [super initWithTitle:entryTitle];
    if(self) {
        
    }
    
    return self;
}


@end
