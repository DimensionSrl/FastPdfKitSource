//
//  MFAudioPlayerViewImpl.h
//  FastPdfKit Sample
//
//  Created by Mac Book Pro on 19/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFAudioPlayerViewProtocol.h"
#import "MFAudioProvider.h"


@interface MFAudioPlayerViewImpl : UIView <MFAudioPlayerViewProtocol>

@property (nonatomic, weak) UIButton *startStopButton;
@property (nonatomic, weak) UISlider *volumeSlider;
@property (nonatomic, weak) UIButton *volumeUpButton;
@property (nonatomic, weak) UIButton *volumeDownButton;
@property (nonatomic, weak) id<MFAudioProvider> audioProvider;

@end
