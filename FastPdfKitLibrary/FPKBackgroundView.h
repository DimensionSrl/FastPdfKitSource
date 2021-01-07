//
//  FPKBackgroundView.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 26/11/14.
//
//

#import <UIKit/UIKit.h>
#import "FPKSharedSettings.h"
#import "FPKOperationsSharedData.h"
#import "FPKThumbnailCache.h"
#import "FPKOperationCenter.h"
#import "FPKThumbnailDataStore.h"

@protocol FPKBackgroundViewDelegate;

@class FPKSharedSettings;

@interface FPKBackgroundView : UIView

@property (nonatomic, weak) UIView * leftView;
@property (nonatomic, weak) UIView * rightView;

@property (nonatomic, readwrite) NSUInteger leftPage;
@property (nonatomic, readwrite) NSUInteger rightPage;
@property (nonatomic, readwrite) MFDocumentMode mode;

@property (weak, nonatomic) id<FPKBackgroundViewDelegate> delegate;

@property (nonatomic,strong) FPKThumbnailCache * cache;
@property (strong, nonatomic) id<FPKThumbnailDataStore> thumbnailDataStore;
@property (nonatomic, weak) FPKSharedSettings * settings;

@property (nonatomic,strong) FPKOperationCenter * operationCenter;
@end

@protocol FPKBackgroundViewDelegate <NSObject>

-(NSString *)thumbnailsDirectoryForBackgroundView:(FPKBackgroundView *)view;
-(NSString *)imagesDirectoryForBackgroundView:(FPKBackgroundView *)view;
-(FPKOperationsSharedData *)sharedDataForBackgroundView:(FPKBackgroundView *)view;
-(MFDocumentManager *)documentForBackgroundView:(FPKBackgroundView *)view;

@end