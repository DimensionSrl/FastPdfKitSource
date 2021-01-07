//
//  MFEmbeddedRemoteAudioProvider.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 6/9/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFEmbeddedRemoteAudioProvider.h"
#import <AVFoundation/AVFoundation.h>

@implementation MFEmbeddedRemoteAudioProvider
@synthesize audioPlayerView;
@synthesize autoplay,audioFrame,audioURL, showView;

- (void)destroyStreamer
{
	if (audioStreamer)
	{
		[[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:ASStatusChangedNotification
         object:audioStreamer];
		
		[audioStreamer stop];
		[audioStreamer release],audioStreamer = nil;
	}
}

- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([audioStreamer isWaiting])
	{
		//[self setButtonImage:[UIImage imageNamed:@"loadingbutton.png"]];
	}
	else if ([audioStreamer isPlaying])
	{
		//[self setButtonImage:[UIImage imageNamed:@"stopbutton.png"]];
	}
	else if ([audioStreamer isIdle])
	{
		[self destroyStreamer];
		//[self setButtonImage:[UIImage imageNamed:@"playbutton.png"]];
	}
}

-(void)willAddOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView {
    // Not needed.
}

-(void)didAddOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView {
    
    if((!paused) && autoplay) {
        [audioStreamer start];
        [audioPlayerView audioProviderDidStart:self];
    }
}

-(void)willRemoveOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView {
    
    if([audioStreamer isPlaying]) {
        [audioStreamer stop];
        [audioPlayerView audioProviderDidStop:self];
    }
}

-(void)didRemoveOverlayView:(UIView *)view  pageView:(FPKPageView *)pageView {
    // Not needed.
}

-(BOOL)isPlaying {
    return [audioStreamer isPlaying];
}

-(float)volumeLevel {
    return 1.0;
}

-(void)setVolumeLevel:(float)volume {
    
    //[audioPlayer setVolume:volume];
    
    [audioPlayerView audioProvider:self volumeAdjustedTo:1.0];
}

-(void)togglePlay {
    
    if(![audioStreamer isPlaying]) {
        
        paused = NO;
        [audioStreamer start];
        [audioPlayerView audioProviderDidStart:self];
        
    } else {
        
        paused = YES;
        [audioStreamer pause];
        [audioPlayerView audioProviderDidStop:self];
    }
}

-(void)setAudioPlayerView:(id<MFAudioPlayerViewProtocol>)anAudioPlayerView {
    
    if(!audioStreamer) {
        
        [self destroyStreamer]; // Cleanup, just in case.
        
        audioStreamer = [[AudioStreamer alloc]initWithURL:self.audioURL];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(playbackStateChanged:)
         name:ASStatusChangedNotification
         object:audioStreamer];
        
        //audioStreamer.delegate = self;
        //[audioPlayer prepareToPlay];
    }
    
    if(audioPlayerView != anAudioPlayerView) {
        
        [audioPlayerView release];
        audioPlayerView = [anAudioPlayerView retain];
        [audioPlayerView setAudioProvider:self];
        
    }
}

-(void)dealloc {
    
#if FPK_DEALLOC
    NSLog(@"%@ - dealloc", NSStringFromClass([self class]));
#endif
    
    [self destroyStreamer];
    
    [audioPlayerView release];
    [audioURL release];
    
    [super dealloc];
}

@end
