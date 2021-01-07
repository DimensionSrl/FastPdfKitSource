//
//  FPKEmbeddedAnnotationURIHandlerImpl.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 11/02/15.
//
//

#import "FPKBaseEmbeddedAnnotationURIHandler.h"

static NSString * fpkRemoteWebPrefix = @"fpkw://";
static NSString * fpkLocalWebPrefix = @"fpkh://";
static NSString * fpkLocalVideoPrefix = @"fpkv://";
static NSString * fpkRemoteVideoPrefix = @"fpky://";
static NSString * fpkRemoteAudioPrefix = @"fpkb://";
static NSString * fpkLocalAudioPrefix = @"fpka://";

static NSString * altRemoteWebPrefix = @"htmlremote://";
static NSString * altLocalWebPrefix = @"html://";
static NSString * altLocalVideoPrefix = @"video://";
static NSString * altRemoteVideoPrefix = @"videoremote://";
static NSString * altLocalAudioPrefix = @"sound://";
static NSString * altRemoteAudioPrefix = @"soundremote://";

static NSString * altRemoteWebPrefix2 = @"web://";
static NSString * altLocalAudioPrefix2 = @"audio://";

static NSString * altMultimediaPrefix = @"pspdfkit://";
static NSString * fpkMultimediaPrefix = @"fpk://";

static NSString * configPrefix = @"config://";

@implementation FPKBaseEmbeddedAnnotationURIHandler

+(BOOL)hasStringPrefix:(NSString *)string prefixes:(NSSet *)prefixes {
    for(NSString * prefix in prefixes) {
        if([string hasPrefix:prefix]) {
            return YES;
        }
    }
    return NO;
}

-(instancetype)init {
    self = [super init];
    if(self) {
        
        self.videoPrefixes = [NSSet setWithObjects:fpkLocalVideoPrefix,altLocalVideoPrefix, nil];
        self.remoteVideoPrefixes = [NSSet setWithObjects:fpkRemoteVideoPrefix,altRemoteVideoPrefix, nil];
        
        self.webPrefixes = [NSSet setWithObjects:fpkLocalWebPrefix,altLocalWebPrefix,nil];
        self.remoteWebPrefixes = [NSSet setWithObjects:fpkRemoteWebPrefix,altRemoteWebPrefix,altRemoteWebPrefix2, nil];
        
        self.audioPrefixes = [NSSet setWithObjects:fpkLocalAudioPrefix,altLocalAudioPrefix,altLocalAudioPrefix2, nil];
        self.remoteAudioPrefixes = [NSSet setWithObjects:fpkRemoteAudioPrefix,altRemoteAudioPrefix, nil];
        
        self.configPrefixes = [NSSet setWithObjects:configPrefix, nil];
        self.multimediaPrefixes = [NSSet setWithObjects:fpkMultimediaPrefix, altMultimediaPrefix, nil];
    }
    return self;
}

-(BOOL)isMultimediaURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.multimediaPrefixes];
}

-(BOOL)isConfigURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.configPrefixes];
}

-(BOOL)isRemoteAudioURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.remoteAudioPrefixes];
}

-(BOOL)isRemoteVideoURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.remoteVideoPrefixes];
}

-(BOOL)isRemoteWebURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.remoteWebPrefixes];
}

-(BOOL)isVideoURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.videoPrefixes];
}

-(BOOL)isAudioURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.audioPrefixes];
}

-(BOOL)isWebURI:(NSString *)uri {
    return [FPKBaseEmbeddedAnnotationURIHandler hasStringPrefix:uri prefixes:self.webPrefixes];
}

@end
