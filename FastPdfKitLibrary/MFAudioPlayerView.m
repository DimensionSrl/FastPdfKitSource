//
//  MFAudioPlayerControllerView.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFAudioPlayerView.h"
#import "MFEmbeddedAudioProvider.h"

@implementation MFAudioPlayerView

@synthesize audioProvider,playButton;

+(UIView *)audioPlayerViewInstance {

    // Here we create an instance of the view of the appropriate dimensions and return it to the caller.
    
    MFAudioPlayerView * instance = [[MFAudioPlayerView alloc]initWithFrame:CGRectMake(0, 0, 100, 50)];
    
    return [instance autorelease];
}

-(void)audioProvider:(id<MFAudioProvider>)mfap volumeAdjustedTo:(float)volume {
    // Nothing to do
}

-(void)audioProviderDidStart:(id<MFAudioProvider>)mfeap {
    
    // Update the UI.
    
    [playButton setTitle:@"Stop" forState:UIControlStateNormal];
}

-(void)audioProviderDidStop:(id<MFAudioProvider>)mfeap {
 
    // Update the UI.
    
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
}

-(void)actionPlayOrStop:(id)sender {
    
    // The provider has only a single method.
    
    [audioProvider togglePlay];
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        // Initialization code.
        
        UIButton * aButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [aButton setFrame:CGRectMake(10, 10, 60, 30)];
        [aButton addTarget:self action:@selector(actionPlayOrStop:) forControlEvents:UIControlEventTouchUpInside];
        [aButton setTitle:@"Play" forState:UIControlStateNormal];
        
        [self addSubview:aButton];
        self.playButton = aButton;
        self.opaque = NO;
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    // Draw the background.
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextSetRGBStrokeColor(ctx, 0.8, 0.8, 0.8, 1.0);
    
    CGFloat radius = 10.0; 
   
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect); 
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect); 
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, minx, midy); 
    CGContextAddArcToPoint(ctx, minx, miny, midx, miny, radius); 
    CGContextAddArcToPoint(ctx, maxx, miny, maxx, midy, radius); 
    CGContextAddArcToPoint(ctx, maxx, maxy, midx, maxy, radius); 
    CGContextAddArcToPoint(ctx, minx, maxy, minx, midy, radius); 
    CGContextClosePath(ctx); 
    CGContextDrawPath(ctx, kCGPathFillStroke); 
    
    CGContextRestoreGState(ctx);
}


- (void)dealloc {
    
    audioProvider = nil;
    
    [playButton release];
    [super dealloc];
}

@end
