//
//  MFAudioPlayerControllerView.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFAudioPlayerViewProtocol.h"
#import "MFAudioProvider.h"

@interface MFAudioPlayerView : UIView <MFAudioPlayerViewProtocol> {
    
    UIButton * playButton;
    id<MFAudioProvider> audioProvider;
}

@property (nonatomic,retain) UIButton * playButton;
@property (nonatomic,assign) id<MFAudioProvider> audioProvider;


@end
