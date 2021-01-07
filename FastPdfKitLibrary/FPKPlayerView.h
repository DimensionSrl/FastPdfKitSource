//
//  FPKPlayerView.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 02/12/14.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FPKPlayerView : UIView

-(AVPlayer *)player;
-(void)setPlayer:(AVPlayer *)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
