//
//  MFEmbeddedVideoProviderManager.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MFEmbeddedVideoProviderManager : NSObject {
    
}

+(MFEmbeddedVideoProviderManager *)sharedInstance;

-(MPMoviePlayerController *)controller;

@end
