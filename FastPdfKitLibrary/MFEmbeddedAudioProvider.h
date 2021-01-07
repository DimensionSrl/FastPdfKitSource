//
//  MFEmbeddedAudioProvider.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MFDocumentOverlayDataSource.h"
#import "MFAudioPlayerViewProtocol.h"
#import "MFAudioProvider.h"
#import "FPKPrivateOverlayWrapper.h"
#import "MFAudioAnnotation.h"

@protocol FPKEmbeddedAudioProviderDelegate;

@interface MFEmbeddedAudioProvider : FPKPrivateOverlayWrapper <AVAudioPlayerDelegate, MFDocumentOverlayDataSource, MFAudioProvider>

@property (nonatomic,strong) AVAudioPlayer * audioPlayer;
@property (nonatomic,strong) NSURL * audioURL;
@property (nonatomic,readwrite) BOOL autoplay;
@property (nonatomic,readwrite) BOOL showView;


@property (nonatomic,readwrite) BOOL paused;

+(MFEmbeddedAudioProvider *)providerForAnnotation:(MFAudioAnnotation *)annotation delegate:(id<FPKEmbeddedAudioProviderDelegate>)delegate;


@property(nonatomic,strong) UIView<MFAudioPlayerViewProtocol>* audioPlayerView;
@property (nonatomic,strong) Class audioPlayerViewClass;

@end

@protocol FPKEmbeddedAudioProviderDelegate
-(BOOL)provider:(MFEmbeddedAudioProvider *)provider shouldAutoplayAudio:(NSString *)audio;
@end
