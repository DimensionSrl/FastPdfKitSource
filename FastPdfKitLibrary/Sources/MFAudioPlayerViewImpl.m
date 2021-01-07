//
//  MFAudioPlayerViewImpl.m
//  FastPdfKit Sample
//
//  Created by Gianluca Orsini on 19/04/11.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFAudioPlayerViewImpl.h"
#import "MFAudioProvider.h"

@interface MFAudioPlayerViewImpl()

@property (nonatomic, weak) UIView * backgroundView;

@end

@implementation MFAudioPlayerViewImpl

+(UIImage *)volumeUpImage {
    static UIImage * image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[UIImage imageNamed:@"volumeUp"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+(UIImage *)volumeDownImage {
    static UIImage * image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[UIImage imageNamed:@"volumeDown"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+(UIImage *)playButtonImage {
    static UIImage * image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[UIImage imageNamed:@"play"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+(UIImage *)pauseButtonImage {
    static UIImage * image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[UIImage imageNamed:@"pause"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+(UIImage *)stopButtonImage {
    static UIImage * image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [[UIImage imageNamed:@"stop"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+(UIView *)backgroundImageView {
    UIImageView *backgroundImageView = [UIImageView new];
    backgroundImageView.backgroundColor = [UIColor colorWithRed:251/255.0 green:0 blue:77/255.0 alpha:1.0];
    backgroundImageView.layer.cornerRadius = 8.0;
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO; // Facciamo a mano!
    return backgroundImageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        // Background
//        UIView *backgroundImageView = [MFAudioPlayerViewImpl backgroundImageView];
//        backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
//        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
//        backgroundImageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
//        [self addSubview:backgroundImageView];
//        self.backgroundView = backgroundImageView;

        // Button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [button setImage:[MFAudioPlayerViewImpl playButtonImage] forState:UIControlStateNormal];
        button.tintColor = [UIColor whiteColor];
        [button addTarget:self action:@selector(actionTogglePlay:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        self.startStopButton = button;
        
//        // Button
//        UIButton *volDownButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        volDownButton.frame = CGRectMake(0, 0, 33, 33);
//        volDownButton.translatesAutoresizingMaskIntoConstraints = NO;
//        [volDownButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
//        [volDownButton setImage:[MFAudioPlayerViewImpl volumeDownImage] forState:UIControlStateNormal];
//        volDownButton.tintColor = [UIColor whiteColor];
//        [volDownButton addTarget:self action:@selector(volumeDown:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:volDownButton];
//        self.volumeDownButton = volDownButton;
//        
//        // Button
//        UIButton *volUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        volUpButton.frame = CGRectMake(0, 0, 33, 33);
//        volUpButton.translatesAutoresizingMaskIntoConstraints = NO;
//        [volUpButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
//        [volUpButton setImage:[MFAudioPlayerViewImpl volumeUpImage] forState:UIControlStateNormal];
//        volUpButton.tintColor = [UIColor whiteColor];
//        [volUpButton addTarget:self action:@selector(volumeUp:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:volUpButton];
//        self.volumeUpButton = volUpButton;
    }
    return self;
}

static const float kVolumeStep = 0.25;

-(void)volumeUp:(id)sender {
    
    float volumeLevel = [_audioProvider volumeLevel];
    
    volumeLevel+=kVolumeStep;
    
    [_audioProvider setVolumeLevel:volumeLevel];
}

-(void)volumeDown:(id)sender {
    float volumeLevel = [_audioProvider volumeLevel];
    
    volumeLevel-=kVolumeStep;
    
    [_audioProvider setVolumeLevel:volumeLevel];
}

-(void)actionTogglePlay:(id)sender{
     
    [self.audioProvider togglePlay];
}

-(void)actionAdjustVolume:(id)sender{
    
    [self.audioProvider setVolumeLevel:[self.volumeSlider value]];
}

+(UIView *)audioPlayerViewInstance{
    
    MFAudioPlayerViewImpl *view = [[MFAudioPlayerViewImpl alloc] initWithFrame:CGRectMake(0, 0, 272, 40)];
    return view;
}

-(void)setAudioProvider:(id<MFAudioProvider>)provider{
    
    float volumeLevel = 0;
    
    if(provider!=_audioProvider) {
        _audioProvider = provider;
        
        if([_audioProvider isPlaying]) {
            [_startStopButton setImage:[MFAudioPlayerViewImpl pauseButtonImage] forState:UIControlStateNormal];
        } else {
            [_startStopButton setImage:[MFAudioPlayerViewImpl playButtonImage] forState:UIControlStateNormal];
        }
        
        volumeLevel = [_audioProvider volumeLevel];
        
        if(volumeLevel == 1) {
            self.volumeDownButton.enabled = true;
            self.volumeUpButton.enabled = false;
        } else if (volumeLevel == 0) {
            self.volumeDownButton.enabled = false;
            self.volumeUpButton.enabled = true;
        } else {
            self.volumeDownButton.enabled = true;
            self.volumeUpButton.enabled = true;
        }
        
        [_volumeSlider setValue:volumeLevel];
    }
}

-(void)layoutSubviews {
    
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    
    CGFloat buttonWidth = 33;
    CGFloat padding = 10;
    
    CGPoint buttonCenter = CGPointMake(padding + buttonWidth/2, bounds.size.height/2);
    
    CGSize buttonSize = CGSizeMake(buttonWidth, 33);
    
    self.startStopButton.bounds = CGRectMake(0, 0, buttonSize.width, buttonSize.height);
    self.startStopButton.center = buttonCenter;

    CGSize sliderSize = CGSizeMake(bounds.size.width - buttonWidth - padding * 2, 33);
    CGPoint sliderCenter = CGPointMake(buttonWidth + (bounds.size.width-buttonWidth)/2, bounds.size.height/2);
    
    self.volumeSlider.bounds = CGRectMake(0, 0, sliderSize.width, sliderSize.height);
    self.volumeSlider.center = sliderCenter;
    
    self.volumeUpButton.frame = CGRectMake(bounds.size.width - padding - buttonWidth, (bounds.size.height-33)/2, 33, 33);
    self.volumeDownButton.frame = CGRectMake((bounds.size.width - buttonWidth)/2, (bounds.size.height - 33)/2, 33, 33);
    
    self.backgroundView.frame = bounds;
}

/**
 * Playback event methods.
 */
-(void)audioProviderDidStart:(id<MFAudioProvider>)mfeap{

    [_startStopButton setImage:[MFAudioPlayerViewImpl pauseButtonImage] forState:UIControlStateNormal];
}

-(void)audioProvider:(id<MFAudioProvider>)mfap volumeAdjustedTo:(float)volumeLevel {
    if(volumeLevel >= 1) {
        self.volumeDownButton.enabled = true;
        self.volumeUpButton.enabled = false;
    } else if (volumeLevel <= 0) {
        self.volumeDownButton.enabled = false;
        self.volumeUpButton.enabled = true;
    } else {
        self.volumeDownButton.enabled = true;
        self.volumeUpButton.enabled = true;
    }
}

-(void)audioProviderDidStop:(id<MFAudioProvider>)mfeap{
    
    [_startStopButton setImage:[MFAudioPlayerViewImpl playButtonImage] forState:UIControlStateNormal];
}

@end
