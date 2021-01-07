//
//  MFEmbeddedAudioProvider.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFEmbeddedAudioProvider.h"
#import "MFAudioPlayerView.h"
#import "MFAudioAnnotation.h"

@implementation MFEmbeddedAudioProvider

+(MFEmbeddedAudioProvider *)providerForAnnotation:(MFAudioAnnotation *)annotation
                                         delegate:(id<FPKEmbeddedAudioProviderDelegate>)delegate
{
    MFEmbeddedAudioProvider * provider = [MFEmbeddedAudioProvider new];
    provider.audioURL = annotation.url;
    provider.rect = annotation.rect;
    provider.showView = annotation.showView.boolValue;
    provider.autoplay = [delegate provider:provider
                       shouldAutoplayAudio:annotation.originalUri];
    return provider;
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                      successfully:(BOOL)flag
{
    // Update the interface?
}

-(void)didAddOverlayView:(UIView *)view
                pageView:(FPKPageView *)pageView
{
    if([view isEqual:_audioPlayerView]) {
        if((!self.paused) && self.autoplay) {
            [self.audioPlayer play];
            [self.audioPlayerView audioProviderDidStart:self];
        }
    }
}

-(void)willRemoveOverlayView:(UIView *)view
                    pageView:(FPKPageView *)pageView
{
    if([view isEqual:_audioPlayerView]) {
        if([self.audioPlayer isPlaying]) {
            [self.audioPlayer stop];
            self.audioPlayer.delegate = nil;
        }
    }
}

-(BOOL)isPlaying {
    return [self.audioPlayer isPlaying];
}

-(float)volumeLevel {
    return [self.audioPlayer volume];
}

-(void)setVolumeLevel:(float)volume {
    [self.audioPlayer setVolume:volume];
    [self.audioPlayerView audioProvider:self
                       volumeAdjustedTo:[self.audioPlayer volume]];
}

-(void)togglePlay {
    
    if(![self.audioPlayer isPlaying]) {
        
        self.paused = NO;
        [self.audioPlayer play];
        [self.audioPlayerView audioProviderDidStart:self];
        
    } else {
        
        self.paused = YES;
        [self.audioPlayer stop];
        [self.audioPlayerView audioProviderDidStop:self];
    }
}

-(UIView *)view {
    return self.audioPlayerView;
}

-(UIView<MFAudioPlayerViewProtocol> *)audioPlayerView
{
    if(!_audioPlayerView) {
        UIView<MFAudioPlayerViewProtocol>* audioPlayerView = [self.audioPlayerViewClass new];
        
        if(!self.audioPlayer) {
            AVAudioPlayer * audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:self.audioURL error:NULL];
            audioPlayer.delegate = self;
            [audioPlayer prepareToPlay];
            self.audioPlayer = audioPlayer;
        }
        
        [audioPlayerView setAudioProvider:self];
        
        self.audioPlayerView = audioPlayerView;
        
    }
    return _audioPlayerView;
}

-(void)dealloc {
    
    _audioPlayer.delegate = nil;
    [_audioPlayer stop];
}

@end
