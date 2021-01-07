//
//  MFEmbeddedVideoProvider2.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 15/12/14.
//
//

#import "MFEmbeddedVideoProvider.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface MFEmbeddedVideoProvider()
@property (nonatomic, strong) AVPlayerViewController * playerViewController;
@property (nonatomic, readwrite) BOOL loaded;
@end

@implementation MFEmbeddedVideoProvider

-(void)didAddOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView  {
    MFEmbeddedVideoProvider __weak * provider = self;
    if(view == self.view) {
        [UIView animateWithDuration:0.25f delay:0.5f options:0 animations:^{
            view.alpha = 1.0;
        }completion:^(BOOL completed) {
            if(provider.autoplay) {
                [provider.playerViewController.player play];
            }
        }];
    }
}

-(void)willAddOverlayView:(UIView *)view pageView:(FPKPageView *)pageView {
    view.alpha = 0.0;
}

-(void)willRemoveOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView {
    
    [self.playerViewController.player pause];
}

-(UIView *)view {
    return self.controller.view;
}

-(AVPlayerViewController *)playerViewController {
    
    AVPlayerViewController * controller = (AVPlayerViewController *)[super controller];
    
    if(!controller) {
        
        controller = [AVPlayerViewController new];
        
        controller.player = [AVPlayer playerWithURL:self.URL];
        controller.showsPlaybackControls = self.controls;
        controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        
        if(self.loop) {
            [[NSNotificationCenter defaultCenter]addObserver:self
                                                    selector:@selector(rewind:)
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:controller.player.currentItem];
        }
        
        
        self.controller = controller;
        
        /*
         // Movie Player Controller
         if(self.moviePlayerController) {
         [self.moviePlayerController.backgroundView setBackgroundColor:[UIColor clearColor]];
         [self.moviePlayerController.view setBackgroundColor:[UIColor clearColor]];
         }
         */
    }
    return controller;
}

-(void)rewind:(NSNotification *)notification {
    AVPlayerItem * item = notification.object;
    [item seekToTime:kCMTimeZero];
    [self.playerViewController.player play];
}

-(UIViewController *)controller {
    
    return self.playerViewController;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
