//
//  FPKSharedSettings_Private.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 24/03/15.
//
//

#import "FPKSharedSettings.h"

@interface FPKSharedSettings()

/**
 * Not used anymore.
 */
@property (readwrite, nonatomic) BOOL useNewEngine;

/**
 * Not used anymore.
 */
@property (readwrite, nonatomic) BOOL legacyModeEnabled;

/**
 * Not used anymore.
 */
@property (readwrite, nonatomic) CGFloat oversize;

/**
 * Factory method.
 */
+(FPKSharedSettings *)defaultSettings;

/**
 * Load settings from shared preferences.
 */
+(FPKSharedSettings *)loadSettings;

@end