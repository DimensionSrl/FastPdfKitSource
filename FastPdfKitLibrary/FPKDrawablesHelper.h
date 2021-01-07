//
//  FPKDrawablesHelper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FPKDetailView.h"
#import "MFOverlayView.h"
#import "FlipContainer.h"

@class MFDocumentViewController;
@class MFDocumentManager;

@interface FPKDrawablesHelper : NSObject <FPKOverlayViewDataSource_Private, FPKOverlayViewDelegate_Private, FPKDrawablesDataSource_Private, NSCacheDelegate>

@property (nonatomic,weak) MFDocumentViewController * documentViewController;
@property (nonatomic,weak) MFDocumentManager * document;
@property (nonatomic, strong) NSCache * cache;
@property (nonatomic, strong) NSMutableArray * cachedObjects;

-(void)removeAllObjects;

@property (nonatomic, readwrite) BOOL flipCoordinates;

@end

