//
//  FPKChildViewControllerHelper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 15/12/14.
//
//

#import "FPKChildViewControllersHelper.h"
#import "MFDocumentManager_private.h"
#import "FPKBaseDocumentViewController_private.h"
#import "MFVideoAnnotation.h"
#import "FPKChildViewControllersWrapper.h"
#import "MFEmbeddedVideoProvider.h"

@interface FPKChildViewControllersHelper()

@property (nonatomic,strong) NSCache * cache;

@end

@implementation FPKChildViewControllersHelper

-(instancetype)init {
    self = [super init];
    if(self) {
        self.cache = [NSCache new];
        self.cache.countLimit = 2;
    }
    return self;
}

-(void)removeAllObjects {
    [self.cache removeAllObjects];
}

-(NSArray *)embeddedViewProvidersForPage:(NSUInteger)page {
    
    // For embedded video on pre iOS 8 overlay views are used instead
        if((self.supportedEmbeddedAnnotations & FPKEmbeddedAnnotationsVideo) == FPKEmbeddedAnnotationsVideo) {
    if([[[UIDevice currentDevice]systemVersion]compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        
        NSMutableArray * providers = [NSMutableArray new];
        NSArray * videoAnnotations = [self.document videoAnnotationsForPageNumber:page];
        
        for(MFVideoAnnotation * annotation in videoAnnotations) {
            
            MFEmbeddedVideoProvider * provider = [MFEmbeddedVideoProvider new];
            provider.rect = annotation.rect;
            provider.URL = annotation.url;
            provider.loop = annotation.loop.boolValue;
            provider.autoplay = annotation.autoplay.boolValue;
            provider.controls = annotation.controls.boolValue;
            
            if(!annotation.autoplay && !annotation.controls) {
                provider.autoplay = YES;
            }
            
            [providers addObject:provider];
        }
        
        return providers;
    }
        }
    
    return @[];
}

-(NSArray *)childViewControllersForPage:(NSUInteger)page {
    
    id key = @(page);
    NSArray * controllers = [self.cache objectForKey:key];
    if(controllers == nil) {
        
        controllers = [self embeddedViewProvidersForPage:page];
        [self.cache setObject:controllers forKey:key];
    }
    
    return controllers;
}

@end
