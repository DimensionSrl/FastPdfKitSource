//
//  FPKPrivateOverlayViewHelper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import "FPKPrivateOverlayViewHelper.h"
#import "FPKPrivateOverlayWrapper.h"
#import "MFDocumentManager_private.h"
#import "MFVideoAnnotation.h"
#import "MFWebAnnotation.h"
#import "MFEmbeddedAudioProvider.h"
#import "MFLegacyEmbeddedVideoProvider.h"
#import "MFEmbeddedWebProvider.h"
#import "FPKBaseDocumentViewController_private.h"
#import "FPKConfigAnnotation.h"
#import "FPKEmbeddedConfigProvider.h"

@interface FPKOverlayCacheEntry : NSObject
@property (nonatomic,strong) NSArray * overlays;
@property (nonatomic,strong) NSNumber * page;
@end

@implementation FPKOverlayCacheEntry

@end

@interface FPKPrivateOverlayViewHelper() <FPKEmbeddedVideoProviderDelegate, FPKEmbeddedAudioProviderDelegate>

//@property (nonatomic,strong) NSArray * leftOverlays;
//@property (nonatomic,strong) NSArray * rightOverlays;

/**
 Keeps an N amount worth of cached pages of FPKPrivateOverlayWrapper.
 */
@property (nonatomic,strong) NSCache * cache;
@end

@implementation FPKPrivateOverlayViewHelper

-(void)removeAllObjects {
    [self.cache removeAllObjects];
}

-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldAutoplayVideo:(NSString *)uri {
    return [self.documentViewController doesHaveToAutoplayVideo:uri];
}

-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldLoopVideo:(NSString *)uri {
    return [self.documentViewController doesHaveToLoopVideo:uri];
}

-(BOOL)provider:(MFLegacyEmbeddedVideoProvider *)provider shouldShowControlsOnVideo:(NSString *)uri {
    return YES;
}

-(BOOL)provider:(MFEmbeddedAudioProvider *)provider shouldAutoplayAudio:(NSString *)audio {
    return [self.documentViewController doesHaveToAutoplayAudio:audio];
}

-(NSArray *)overlaysForPage:(NSUInteger)page {
    
    NSMutableArray * overlays = [NSMutableArray new]; // Retval
    
    // Video
    if((self.supportedEmbeddedAnnotations & FPKEmbeddedAnnotationsVideo) == FPKEmbeddedAnnotationsVideo) {
        
        // Overlay views are used on pre iOS 8. After iOS 8 we use embedded video controller.
        if([[[UIDevice currentDevice]systemVersion]compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
            
            NSArray * videoAnnotations = [self.document videoAnnotationsForPageNumber:page];
            for(MFVideoAnnotation * annotation in videoAnnotations) {
                MFLegacyEmbeddedVideoProvider * provider = [MFLegacyEmbeddedVideoProvider providerForAnnotation:annotation
                                                                                           delegate:self];
                provider.owner = provider;
                [overlays addObject:provider];
            }
        }
    }
    
    // Web
    if((self.supportedEmbeddedAnnotations & FPKEmbeddedAnnotationsWeb) == FPKEmbeddedAnnotationsWeb) {
        NSArray * webAnnotations = [self.document webAnnotationsForPageNumber:page];
        for(MFWebAnnotation * annotation in webAnnotations) {
            
            MFEmbeddedWebProvider * provider = [MFEmbeddedWebProvider providerForAnnotation:annotation];
            provider.owner = provider;
            [overlays addObject:provider];
        }
    }
    
    // Audio
    if((self.supportedEmbeddedAnnotations & FPKEmbeddedAnnotationsAudio) == FPKEmbeddedAnnotationsAudio) {
        NSArray * audioAnnotations = [self.document audioAnnotationsForPageNumber:page];
        for(MFAudioAnnotation * annotation in audioAnnotations) {
            MFEmbeddedAudioProvider * provider = [MFEmbeddedAudioProvider providerForAnnotation:annotation
                                                                                       delegate:self];
            provider.owner = provider;
            [provider setAudioPlayerViewClass:[self.documentViewController classForAudioPlayerView]];
            
            [overlays addObject:provider];
        }
    }
    
    // Config
    NSArray * configAnnotations = [self.document configAnnotationsForPageNumber:page];
    for(FPKConfigAnnotation * annotation in configAnnotations) {
        FPKEmbeddedConfigProvider * provider = [FPKEmbeddedConfigProvider providerForAnnotation:annotation delegate:self.documentViewController];
        provider.owner = provider;
        [overlays addObject:provider];
    }
    
    return overlays;
}

-(instancetype)init {
    self = [super init];
    if(self) {
        NSCache * cache = [NSCache new];
        cache.countLimit = 2;
        self.cache = cache;
    }
    return self;
}

-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page {
    
    NSNumber * key = @(page);
    FPKOverlayCacheEntry * entry = [self.cache objectForKey:key];
    if(!entry) {
        entry = [FPKOverlayCacheEntry new];
        entry.page = key;
        entry.overlays = [self overlaysForPage:page];
        [self.cache setObject:entry forKey:key];
    }
    
    return entry.overlays;
}

@end
