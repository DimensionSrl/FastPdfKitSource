//
//  MFEmbeddedVideoProviderManager.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFEmbeddedVideoProviderManager.h"

@interface MFEmbeddedVideoProviderManager () {
    
    NSMutableSet * controllers;
    NSMutableSet * unusedControllers;
}

@property (strong, nonatomic) NSMutableSet * controllers;
@property (strong, nonatomic) NSMutableSet * unusedControllers;

@end

@implementation MFEmbeddedVideoProviderManager
@synthesize controllers, unusedControllers;

+(MFEmbeddedVideoProviderManager *)sharedInstance {
    
    static MFEmbeddedVideoProviderManager * sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!sharedInstance) {
            sharedInstance = [[MFEmbeddedVideoProviderManager alloc]init];
        }
    });
    
    return sharedInstance;
}

-(id)init {
    
    self = [super init];
    
    if(self) {
        
        NSMutableSet * set = nil;
        set = [[NSMutableSet alloc]init];
        self.unusedControllers = set;
        [set release];
        
        set = [[NSMutableSet alloc]init];
        self.controllers = set;
        [set release];
    }
    
    return self;
}

-(void)handleMoviePlayerControllerNotification:(NSNotification *)notification {
    
    if([notification.object isKindOfClass:[MPMoviePlayerController class]]) {
    
        MPMoviePlayerController * controller = (MPMoviePlayerController *)notification.object;
        
        [controller.view removeFromSuperview];
        
        [unusedControllers removeObject:notification.object];
        
        
//    if([unusedControllers count] > 0) {
//    
//        NSLog(@"Releasing controller");
//        
//        [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notification.object];
//        
//        [controllers removeObject:notification.object];
//    
//    } else {
//        
//        NSLog(@"Enquequing controller for reuse");
//        
//        [unusedControllers addObject:notification.object];
//    }
    }
}

-(MPMoviePlayerController *)controller {
    
    MPMoviePlayerController * controller = [[MPMoviePlayerController alloc]init];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleMoviePlayerControllerNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:controller];
    [self.controllers addObject:controller];
    [controller release];
    return controller;
    
//    MPMoviePlayerController * controller = nil;
//    
//    if([unusedControllers count] > 0) {
//        
//        NSLog(@"Dequequing controller");
//        
//        controller = [unusedControllers anyObject];
//        
//        [unusedControllers removeObject:controller];
//    
//    } else {
//        
//        NSLog(@"Prepping a new MPMoviePlayerController");
//    
//        controller = [[MPMoviePlayerController alloc]init];
//        
//        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleMoviePlayerControllerNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:controller];
//        
//        [controllers addObject:controller];
//        
//        [controller release];
//    }
//    
//    return controller;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    [controllers release];
    [unusedControllers release];
    
    [super dealloc];
}

@end
