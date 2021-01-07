//
//  FPKSharedSettings.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FPKSharedSettings_Private.h"

@implementation FPKSharedSettings

-(void)setCompressionLevel:(CGFloat)newCompressionLevel
{
        /* Ensure 0.0 <= level <= 1.0 */
        _compressionLevel = MIN(1.0,MAX(0,newCompressionLevel));
}

-(void)setPadding:(CGFloat)newPadding {
    
        /* Ensure 0 <= padding <= 100 */
        _padding = MIN(100,MAX(0,newPadding));
}

#pragma mark - Factory methods

+(FPKSharedSettings *)defaultSettings
{
    FPKSharedSettings * settings = [[FPKSharedSettings alloc]init];
    
    settings.cacheImageScale = FPKImageCacheScaleTrueToPixels;
    settings.useJPEG = YES;
    settings.compressionLevel = 0.75f;
    settings.forceTiles = NO;
    settings.useNewEngine = YES;
    settings.legacyModeEnabled = NO;
    settings.oversize = 0.05;
    settings.padding = 0;
    settings.foregroundEnabled = YES;
    
    return settings;
}

+(FPKSharedSettings *)loadSettings
{
    FPKSharedSettings * settings = [FPKSharedSettings defaultSettings];
    
    /* Preferred image cache scaling */
    static NSString * fpkImageCacheScaling = @"FPKImageCacheScaling";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheScaling]) 
    {
        FPKImageCacheScale imageCacheScaling = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheScaling]intValue]; // 0 = 1.0, 1 = 2.0, 2 = 1.5
        settings.cacheImageScale = imageCacheScaling;
    }
    
    /* Use JPEG instead of PNG */
    static NSString * fpkImageCacheCompressionKey = @"FPKImageCacheCompression";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheCompressionKey]) {
        BOOL useJPEG = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheCompressionKey]boolValue];
        settings.useJPEG = useJPEG;
    }
    
    /* Tiles */
    static NSString * fpkForceTilesKey = @"FPKForceTiles";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkForceTilesKey]) {
        FPKForceTiles forceTiles = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkForceTilesKey]unsignedIntValue];
        settings.forceTiles = forceTiles;
    }
    
    /* Use old engine */
    static NSString * fpkUseOldEngineKey = @"FPKUseOldEngine";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkUseOldEngineKey]) 
    {
        BOOL useOldEngine = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkUseOldEngineKey]boolValue];
        settings.useNewEngine = (!useOldEngine);
    }
    
    /* Legacy mode */
    static NSString * fpkLegacyModeKey = @"FPKLegacyModeEnabled";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkLegacyModeKey]) 
    {
        BOOL legacyModeEnabled = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkLegacyModeKey]boolValue];
        settings.legacyModeEnabled = legacyModeEnabled;
    }
    
    /* Oversize */
    static NSString * fpkImageCacheOversizeKey = @"FPKImageCacheOversize";
    if([[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheOversizeKey]) 
    {
        CGFloat oversize = [[[NSUserDefaults standardUserDefaults]valueForKey:fpkImageCacheOversizeKey]boolValue];
        settings.oversize = oversize;
    }
    
    return settings;
}


@end
