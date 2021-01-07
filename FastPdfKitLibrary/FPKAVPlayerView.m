//
//  FPKAVPlayerView.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 16/02/15.
//
//

#import "FPKAVPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@implementation FPKAVPlayerView

+(Class)layerClass {
    return [AVPlayerLayer class];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
