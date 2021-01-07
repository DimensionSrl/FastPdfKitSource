//
//  MFFakeVideoProvider.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 3/9/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MFDocumentOverlayDataSource.h"
#import "FPKPrivateOverlayWrapper.h"

@class MFVideoAnnotation;

@protocol FPKEmbeddedVideoProviderDelegate;

@interface MFLegacyEmbeddedVideoProvider : FPKPrivateOverlayWrapper <MPMediaPickerControllerDelegate,MFDocumentOverlayDataSource>

@property (nonatomic, strong) MPMoviePlayerController * moviePlayerController;
@property (nonatomic, readwrite) MPMoviePlaybackState state;
@property (nonatomic, strong) NSURL * videoURL;
@property (nonatomic, readonly) UIView * videoPlayerView;
@property (nonatomic, readwrite) CGRect videoFrame;
@property (nonatomic, readwrite) BOOL autoplay;
@property (nonatomic, readwrite) BOOL loop;
@property (nonatomic, readwrite) BOOL controls;

@property (nonatomic,weak) id<FPKEmbeddedVideoProviderDelegate>delegate; // Unused

+(MFLegacyEmbeddedVideoProvider *)providerForAnnotation:(MFVideoAnnotation *)annotation delegate:(id<FPKEmbeddedVideoProviderDelegate>)delegate;

@end

@protocol FPKEmbeddedVideoProviderDelegate

-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldAutoplayVideo:(NSString *)uri;
-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldLoopVideo:(NSString *)uri;
-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldShowControlsOnVideo:(NSString *)uri;

@end

