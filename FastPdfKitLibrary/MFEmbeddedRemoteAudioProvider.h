//
//  MFEmbeddedRemoteAudioProvider.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 6/9/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFAudioProvider.h"
#import <UIKit/UIKit.h>
#import "AudioStreamer.h"
#import "MFAudioPlayerViewProtocol.h"
#import "FPKPrivateOverlayWrapper.h"

@interface MFEmbeddedRemoteAudioProvider : FPKPrivateOverlayWrapper<MFAudioProvider> {

    AudioStreamer * audioStreamer;
    
    NSURL * audioURL;
    id<MFAudioPlayerViewProtocol> audioPlayerView;
    
    CGRect audioFrame;
    
    BOOL paused;
    BOOL autoplay;
    BOOL showView;
}

@property (nonatomic,retain) NSURL * audioURL;
@property (nonatomic,readwrite) CGRect audioFrame;
@property (nonatomic,readwrite) BOOL autoplay;
@property (nonatomic,readwrite) BOOL showView;

@property(nonatomic,retain) id<MFAudioPlayerViewProtocol> audioPlayerView;

@end
