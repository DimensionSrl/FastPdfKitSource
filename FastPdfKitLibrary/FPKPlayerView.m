//
//  FPKPlayerView.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 02/12/14.
//
//

#import "FPKPlayerView.h"


@implementation FPKPlayerView

+(Class)layerClass {
    return [AVPlayerLayer class];
}

-(AVPlayer *)player {
    return [(AVPlayerLayer *)self.layer player];
}

-(void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
