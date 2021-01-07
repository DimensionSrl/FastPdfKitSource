//
//  MFTiledOverlayView.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 5/27/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFTiledOverlayView.h"
#import "MFQuickTiledLayer.h"

@implementation MFTiledOverlayView

+(Class)layerClass {
	return [MFQuickTiledLayer class];
}

-(void)clear {
    
    [[self layer]setContents:nil];
    [[self layer]setNeedsDisplay];
}

-(void)setNeedsDisplay {
    [self clear];
    [super setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
		// Get the underlying layer and set it up.
		
		CATiledLayer * layer = (CATiledLayer *)[self layer];
		[layer setTileSize:frame.size];
		[layer setLevelsOfDetail:4];
		[layer setLevelsOfDetailBias:3];
		
    }
    return self;
}


@end
