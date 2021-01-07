//
//  MFFakeVideoProvider.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 3/9/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFLegacyEmbeddedVideoProvider.h"
#import "MFEmbeddedVideoProviderManager.h"
#import "MFVideoAnnotation.h"

@implementation MFLegacyEmbeddedVideoProvider
@synthesize videoPlayerView = _videoPlayerView;

-(CGRect)videoFrame {
    return self.rect;
}

-(void)setVideoFrame:(CGRect)videoFrame {
    self.rect = videoFrame;
}

+(MFLegacyEmbeddedVideoProvider *)providerForAnnotation:(MFVideoAnnotation *)annotation
                                         delegate:(id<FPKEmbeddedVideoProviderDelegate>)delegate
{
    
    NSURL * url = annotation.url;
    
    MFLegacyEmbeddedVideoProvider * provider = [MFLegacyEmbeddedVideoProvider new];
    provider.videoURL = url;
    provider.videoFrame = annotation.rect;
    

        provider.loop = annotation.loop.boolValue;
    
    provider.autoplay = annotation.autoplay.boolValue;
    
    provider.controls = annotation.controls.boolValue;
    
    
    return provider;
}

-(UIView *)view {
    return self.videoPlayerView;
}

-(void)didAddOverlayView:(UIView *)ov pageView:(FPKPageView *)pageView {
    
    if(ov == [self view]) {
        
        if((self.state == MPMoviePlaybackStatePlaying && self.autoplay) || YES)
            
            [self.moviePlayerController play];
    }
}

-(void)willRemoveOverlayView:(UIView *)ov pageView:(FPKPageView *)pageView {
    
    if(ov == [self view]) {
        
        self.state = [self.moviePlayerController playbackState];
        
        [self.moviePlayerController stop];
    }
}

-(UIView *)videoPlayerView {
    
    if(!_videoPlayerView) {
        
        // If the movie player is not already allocated, allocate and intialize it.
        
        if((!_moviePlayerController)) {
            
            MPMoviePlayerController * controller = [MPMoviePlayerController new];
            controller.view.frame = CGRectMake(0, 0, self.videoFrame.size.width, self.videoFrame.size.height);
            controller.view.autoresizingMask = UIViewAutoresizingNone|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
                        controller.view.translatesAutoresizingMaskIntoConstraints = NO;
            controller.view.clipsToBounds = YES;
            controller.scalingMode = MPMovieScalingModeAspectFit;
            controller.contentURL = self.videoURL;

            [controller prepareToPlay];
            
            if(self.controls) {
                controller.controlStyle = MPMovieControlStyleEmbedded;
            } else {
                controller.controlStyle = MPMovieControlStyleEmbedded;
            }
            
            if(self.loop) {
                controller.repeatMode = MPMovieRepeatModeOne;
            } else {
                controller.repeatMode = MPMovieRepeatModeNone;
            }
            
            self.moviePlayerController = controller;
            
            if(self.moviePlayerController) {
                [self.moviePlayerController.backgroundView setBackgroundColor:[UIColor clearColor]];
                [self.moviePlayerController.view setBackgroundColor:[UIColor clearColor]];
            }
        }
    }
    
    return self.moviePlayerController.view;
}

-(void)dealloc {
    
#if FPK_DEALLOC || 1
    NSLog(@"%@ - dealloc", NSStringFromClass([self class]));
#endif
    
    [_moviePlayerController stop];
    [_moviePlayerController setCurrentPlaybackTime:-1];
}

@end
