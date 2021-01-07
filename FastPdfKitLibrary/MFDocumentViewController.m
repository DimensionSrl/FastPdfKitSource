    //
//  MainViewController.m
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/16/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFDocumentViewController.h"
#import "MFOffscreenRenderer.h"
#import "MFDeferredContentLayerWrapper.h"
#import "MFDocumentManager.h"
#import "resources.h"
#import "MFOverlayTouchable.h"
#import "FPKOverlayViewDataSource.h"
#import "FPKBaseDocumentViewController_private.h"
#import "MFDocumentManager_private.h"
#import "PrivateStuff.h"
#import "MFTextItem.h"
#import "TVThumbnailScrollView.h"
#import <pthread.h>
#import "FPKPageView.h"
#import "FPKPageMetricsCache.h"
#import "FPKThumbnailCache.h"
#import "FPKThumbnailFileStore.h"
#import "FPKSharedSettings_Private.h"

NSString * const FPKConfigurationDictionaryConfigKey = @"config";
NSString * const FPKConfigurationDictionaryPageKey = @"page";
NSString * const FPKConfigurationDictionaryOrientationKey = @"orientation";
NSString * const FPKConfigurationDictionaryModeKey = @"mode";
NSString * const FPKConfigurationDictionaryPaddingKey = @"padding";
NSString * const FPKConfigurationDictionaryEdgeFlipKey = @"edges";
NSString * const FPKConfigurationDictionaryAlternateEdgeFlipKey = @"sides";

int fpk_view_version = 1;       // Splash
int fpk_controller_version = 0; // Re-check flag

BOOL alreadyShown = NO;
BOOL isRotating = NO;
BOOL isAppearing = NO;


#define FPK_HIRES_PREVIEW_CONCURRENCY 2
#define FPK_LORES_PREVIEW_CONCURRENCY 4
#define FPK_DEF_THUMB_HEIGHT 80
#define FPK_TOOLBAR_HEIGHT_SLIDER 44
#define FPK_TOOLBAR_HEIGHT_THUMBS 88

unsigned char default_toolbar_background_png[] = {
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x73, 0x7a, 0x7a, 0xf4, 0x00, 0x00, 0x00,
    0x04, 0x73, 0x42, 0x49, 0x54, 0x08, 0x08, 0x08, 0x08, 0x7c, 0x08, 0x64,
    0x88, 0x00, 0x00, 0x00, 0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x0d,
    0xd7, 0x00, 0x00, 0x0d, 0xd7, 0x01, 0x42, 0x28, 0x9b, 0x78, 0x00, 0x00,
    0x00, 0x19, 0x74, 0x45, 0x58, 0x74, 0x53, 0x6f, 0x66, 0x74, 0x77, 0x61,
    0x72, 0x65, 0x00, 0x77, 0x77, 0x77, 0x2e, 0x69, 0x6e, 0x6b, 0x73, 0x63,
    0x61, 0x70, 0x65, 0x2e, 0x6f, 0x72, 0x67, 0x9b, 0xee, 0x3c, 0x1a, 0x00,
    0x00, 0x00, 0x2f, 0x49, 0x44, 0x41, 0x54, 0x58, 0x85, 0xed, 0xce, 0x31,
    0x01, 0x00, 0x30, 0x0c, 0x80, 0x30, 0x5a, 0xff, 0xd2, 0x26, 0x6a, 0x32,
    0xfa, 0x04, 0x03, 0x64, 0xaa, 0xd7, 0x61, 0x7b, 0x39, 0x07, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xa8, 0xfa, 0xeb, 0x42, 0x01, 0x0c, 0x30, 0xfd, 0xf9, 0xee, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int default_toolbar_background_png_len = 178;

int newLayerPosition(int currentLayerPosition, int currentPosition, int nextBias, int prevBias, int count, int max) {
    
    int newLayerPosition = currentLayerPosition;
    
    int minPos, maxPos;
    minPos = 0;
    maxPos = max - 1;
    
    int lowerLimit = currentPosition + prevBias;
    int upperLimit = currentPosition + nextBias;
    
    if(lowerLimit < minPos) {
        int shift = (minPos-lowerLimit);
        lowerLimit+=shift;
        upperLimit+=shift;
    }
    if(upperLimit > maxPos) {
        int shift = (maxPos-upperLimit);
        lowerLimit+=shift;
        upperLimit+=shift;
    }
    
    if(!(lowerLimit <= currentLayerPosition && currentLayerPosition <= upperLimit)) {
        
        while(newLayerPosition < lowerLimit)
            newLayerPosition+=count;
        
        while(newLayerPosition > upperLimit)
            newLayerPosition-=count;
    }
    
    return newLayerPosition;
}
static inline int checkSignature() {
    fpk_view_version = 0;
    return 3;
}

// Public stuff
@implementation MFDocumentViewController

@synthesize showShadow=_showShadow;

#pragma mark -

-(FPKChildViewControllersHelper *)childViewControllersHelper {
    if(!_childViewControllersHelper) {
        _childViewControllersHelper = [FPKChildViewControllersHelper new];
        _childViewControllersHelper.document = self.document;
        _childViewControllersHelper.documentViewController = self;
        _childViewControllersHelper.supportedEmbeddedAnnotations = self.supportedEmbeddedAnnotations;
    }
    return _childViewControllersHelper;
}

-(FPKPrivateOverlayViewHelper *)privateOverlayViewHelper {
    if(!_privateOverlayViewHelper) {
        _privateOverlayViewHelper = [FPKPrivateOverlayViewHelper new];
        _privateOverlayViewHelper.documentViewController = self;
        _privateOverlayViewHelper.document = self.document;
        _privateOverlayViewHelper.supportedEmbeddedAnnotations = self.supportedEmbeddedAnnotations;
    }
    return _privateOverlayViewHelper;
}

-(FPKDrawablesHelper *)drawablesHelper {
    if(!_drawablesHelper) {
        _drawablesHelper = [FPKDrawablesHelper new];
        _drawablesHelper.documentViewController = self;
    }
    return _drawablesHelper;
}

-(FPKOverlayViewHelper *)overlayViewHelper {
    if(!_overlayViewHelper) {
        _overlayViewHelper = [FPKOverlayViewHelper new];
        _overlayViewHelper.documentViewController = self;
    }
    return _overlayViewHelper;
}

#pragma mark - FPKPageViewDelegate

-(BOOL)pageViewShouldEdgeFlip:(FPKPageView *)pageView {
    return self.pageFlipOnEdgeTouchEnabled;
}

-(BOOL)pageViewShouldZoomOnDoubleTap:(FPKPageView *)pageView {
    return self.zoomInOnDoubleTapEnabled;
}

-(void)pageView:(FPKPageView *)pageView didReceiveTapOnTouchable:(id<MFOverlayTouchable>)touchable page:(NSUInteger)page {
    
    [self didReceiveTapOnTouchable:touchable];
}

-(BOOL)pageView:(FPKPageView *)pageView wantsDestination:(NSString *)destination file:(NSString *)file annotationRect:(CGRect)rect {
    
    return [self didReceiveTapOnAnnotationRect:rect destination:destination file:file];
}

-(BOOL)pageView:(FPKPageView *)pageView wantsPage:(NSUInteger)page file:(NSString *)file annotationRect:(CGRect)rect {
    
    return [self didReceiveTapOnAnnotationRect:rect page:page file:file];
}

-(BOOL)pageView:(FPKPageView *)pageView wantsPage:(NSUInteger)page {
    
    [self willFollowLinkToPage:page];
    
    [self goToPage:page];
    
    return YES;
}

-(FPKSharedSettings *)sharedSettingsForPageView:(FPKPageView *)pageView {
    return self.settings;
}
-(FPKOperationsSharedData *)sharedDataForPageView:(FPKPageView *)pageView {
    return self.operationsSharedData;
}

-(void)pageViewWantsToFlipRight:(FPKPageView *)pageView {
    [self moveToNextPage];
}

-(void)pageViewWantsToFlipLeft:(FPKPageView *)pageView {
    [self moveToPreviousPage];
}

-(CGFloat)maxZoomScaleForPageView:(FPKPageView *)pageView {
    return [self defaultMaxZoomScale];
}

-(CGFloat)edgeFlipWidthForPageView:(FPKPageView *)pageView {
    return self.edgeFlipWidth;
}

-(BOOL)documentInteractionEnabledForPageView:(FPKPageView *)pageView {
    return self.documentInteractionEnabled;
}

-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapOnAnnotationRect:(CGRect)rect uri:(NSString *)uri page:(NSUInteger)page {
    [self didReceiveTapOnAnnotationRect:rect withUri:uri onPage:page];
    return NO;
}

-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapAtPoint:(CGPoint)point
{
    NSValue * pointValue = [NSValue valueWithCGPoint:point];
    [self didReceiveTapAtPoint:pointValue];
    
    return NO;
}

-(BOOL)pageView:(FPKPageView *)pageView didReceiveTapAtPoint:(CGPoint)point
           page:(NSUInteger)page
{
    [self didReceiveTapOnPage:page atPoint:point];
    
    return NO;
}

-(NSString *)thumbnailsDirectoryForPageView:(id)pageView
{
    return self.thumbsCacheDirectory;
}

-(NSString *)imagesDirectoryForPageView:(id)pageView
{
    return self.imagesCacheDirectory;
}

#pragma mark - Image cache settings

-(void)setImageCacheScaling:(FPKImageCacheScale)scale
{
    [self.settings setCacheImageScale:scale];
}

-(FPKImageCacheScale)imageCacheScaling
{
    return self.settings.cacheImageScale;
}

-(void)setUseJPEG:(BOOL)useJPEGOrNot
{
    self.settings.useJPEG = useJPEGOrNot;
}

-(BOOL)useJPEG
{
    return self.settings.useJPEG;
}

-(void)setImageCacheCompression:(CGFloat)level
{
    self.settings.compressionLevel = level;
}

-(CGFloat)imageCacheCompression
{
    return self.settings.compressionLevel;
}

-(void)setForceTiles:(FPKForceTiles)force
{
    self.settings.forceTiles = force;
}

-(FPKForceTiles)forceTiles
{
    return self.settings.forceTiles;
}

#pragma mark - Cache paths handling

-(NSString *)thumbsCacheDirectory
{
    /*
     If there is not an associated documentId use the <APPLICATION_HOME>/tmp
     folder to store the thumbnail. Be sure that the folder is deleted when the
     documentview controller is loaded with a different document manager.
     Otherwise, if there's a valid documentId, it tries to reuse the appropriate
     folder in the <APPLICATION_HOME>/Library/Caches a folder that will be kept
     between application launches but will not be backed up by iTunes.
     */
    
    NSString * retval = nil;
    
        pthread_mutex_lock(&_optionsMutex);
        
        if(!_thumbsCacheDirectory)
        {   
            if(self.thumbnailsCachePath)
            {
                self.thumbsCacheDirectory = self.thumbnailsCachePath;
            }
            else
            {
        
                NSFileManager * fileManager = [NSFileManager defaultManager];
                BOOL isDirectory = NO;
                NSString * docId = nil;
                
                if((docId = self.documentId))
                {
                    
                    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                    NSString * path = [paths objectAtIndex:0]; // <APPLICATION_HOME>/Library/Cache
                    
                    self.thumbsCacheDirectory = [[path stringByAppendingPathComponent:docId]stringByAppendingPathComponent:@"thumbs"];
                    
                    /*
                     If an item already exist at path and the cleanUpCacheAtLaunch is set
                     to YES, destroy the item and recreate a folder. If it does 
                     not exist, create a new folder.
                     */
                    
                    if([fileManager fileExistsAtPath:_thumbsCacheDirectory isDirectory:&isDirectory]) // Already exist.
                    {
                        if(self.cleanUpCacheAtLaunch)
                        {
                            if([fileManager removeItemAtPath:_thumbsCacheDirectory error:NULL])
                            {
                                if(![fileManager createDirectoryAtPath:_thumbsCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                                {
                                    NSLog(@"Unable to recreate cache directory at %@", _thumbsCacheDirectory);
                                }
                            }
                            else
                            {
                                NSLog(@"Unable to delete existing item at %@", _thumbsCacheDirectory);
                            }
                        }
                    }
                    else // Doesn't exist yet.
                    {
                        if(![fileManager createDirectoryAtPath:_thumbsCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                        {
                            NSLog(@"Unable to create cache directory at %@", _thumbsCacheDirectory);
                        }
                    }
                }
                else
                {
                    /**
                     Always destroy the item if already exist, then create a new one.
                     */
                    
                    NSString * path = NSTemporaryDirectory(); // <APPLICATION_HOME>/tmp
                    
                    self.thumbsCacheDirectory = [[path stringByAppendingPathComponent:@"shared"]stringByAppendingPathComponent:@"thumbs"];
                    
                    if([fileManager fileExistsAtPath:_thumbsCacheDirectory isDirectory:&isDirectory])
                    {
                        if(![fileManager removeItemAtPath:_thumbsCacheDirectory error:NULL])
                        {
                            NSLog(@"Unable to delete existing item at %@", _thumbsCacheDirectory);
                        }
                    }

                    if(![fileManager createDirectoryAtPath:_thumbsCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                    {
                        NSLog(@"Unable to create cache directory at %@", _thumbsCacheDirectory);
                    }
                }
            }
        }
    
    retval = _thumbsCacheDirectory;
    
    pthread_mutex_unlock(&_optionsMutex);
    
    return retval;
}

-(NSString *)imagesCacheDirectory
{
    
    NSString * retval = nil;
    
    pthread_mutex_lock(&_optionsMutex);
        
        if(!_imagesCacheDirectory)
        {
            
            if(self.imagesCachePath)
            {
                self.imagesCacheDirectory = self.imagesCachePath;
            }
            else {
                
                NSArray * cacheDirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString * cacheDir = [cacheDirs objectAtIndex:0];
                
                if(self.documentId)
                {
                    self.imagesCacheDirectory = [[cacheDir stringByAppendingPathComponent:self.documentId]stringByAppendingPathComponent:@"pages"];
                    
                    NSFileManager * fileManager = [[NSFileManager alloc]init];
                    
                    if([fileManager fileExistsAtPath:_imagesCacheDirectory isDirectory:NULL])
                    {
                        if(self.cleanUpCacheAtLaunch)
                        {
                            if(![fileManager removeItemAtPath:_imagesCacheDirectory error:NULL])
                            {
                                NSLog(@"Unable to delete item at %@", _imagesCacheDirectory);    
                            }
                            if(![fileManager createDirectoryAtPath:_imagesCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                            {
                                NSLog(@"Unable to recreate directory at %@", _imagesCacheDirectory);    
                            }
                        }
                    }
                    else
                    {
                        if(![fileManager createDirectoryAtPath:_imagesCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                        {
                            NSLog(@"Unable to create directory at %@", _imagesCacheDirectory);    
                        }
                    }
                }
                else
                {
                    
                    self.imagesCacheDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"shared/pages"];
                    
                    NSFileManager * fileManager = [[NSFileManager alloc]init];
                    
                    if([fileManager fileExistsAtPath:_imagesCacheDirectory isDirectory:NULL])
                    {
                        if(![fileManager removeItemAtPath:_imagesCacheDirectory error:NULL])
                        {
                            NSLog(@"Unable to delete item at %@", _imagesCacheDirectory);
                        }
                    }
                    
                    if(![fileManager createDirectoryAtPath:_imagesCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
                    {
                        NSLog(@"Unable to create directory at %@", _imagesCacheDirectory);
                    }
                }
            }
        }
        
    retval = _imagesCacheDirectory;
    
    pthread_mutex_unlock(&_optionsMutex);
    
    return retval;
}


-(void)addDocumentDelegate:(NSObject<MFDocumentViewControllerDelegate> *)delegate {
    
    for(id pointer in self.delegates) {
        if([pointer isEqual:delegate]) {
            return;
        }
    }
    
    [self.delegates addPointer:(__bridge void *)(delegate)];
    
//    CFRange range;
//    range.location = 0;
//    range.length = CFArrayGetCount(documentDelegates);
//
//    if(!CFArrayContainsValue(documentDelegates, range, (__bridge const void *)(delegate)))
//    {
//        CFArrayAppendValue(documentDelegates, (__bridge const void *)(delegate));
//    }
}

-(void)removeDocumentDelegate:(NSObject<MFDocumentViewControllerDelegate> *)delegate {

    NSUInteger count = self.delegates.count;
    for(NSUInteger index = 0; index < count; index++) {
        id pointer = [self.delegates pointerAtIndex:index];
        if(pointer == delegate) {
            [self.delegates removePointerAtIndex:index];
            count--;
        }
    }
    
//    CFRange range;
//    CFIndex index;
//    range.location = 0;
//    range.length = CFArrayGetCount(documentDelegates);
//
//    index = CFArrayGetFirstIndexOfValue(documentDelegates, range, (__bridge const void *)(delegate));
//    
//    if(index >= 0)
//    {
//        CFArrayRemoveValueAtIndex(documentDelegates, index);
//    }
}

-(void)setMaximumZoomScale:(NSNumber *)scale {
    //[[detailView scrollDetailView] setMaximumZoomScale:[scale floatValue]];
}

-(void)setScrollEnabled:(BOOL)lock{
    [_pagedScrollView setScrollEnabled:lock];
}

-(BOOL)gesturesDisabled{
    // Override in your sublclass to manage gesture recognizers on Overlays
    return NO;
}

-(void)moveLayer:(FPKPageView *)wrapper toFrame:(CGRect)frame {
    
    wrapper.frame = frame;
    
    /*
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    wrapper.layer.frame = frame;
    [CATransaction commit];
     */
}

int indexForOffset(int offset) {
    
    if(offset == 0)
        return 0;
    if(offset > 0)
        return (offset*2)-1;
    return (-offset)*2;
    
}

int priorityForOffset(int offset) {
    if(offset == 0)
        return 1;
    return 0;
}

-(void)checkAndUpdateLayers:(BOOL)forceFrame {
    
    if(forceFrame)
    {
        /* Riposiziona tutte le view */
        
        for(FPKPageView * pageView in _wrappers)
        {
            NSInteger currentLayerPosition = pageView.position;
            NSInteger newPosition = newLayerPosition((int)currentLayerPosition,(int)_currentPosition,_fpk_preview_next_bias,_fpk_preview_prev_bias,_fpk_preview_count,(int)_currentNumberOfPositions); // 2,-1,4
            
            CGRect frame = [self frameForLayer:newPosition withBuffering:forceFrame];
            
            pageView.position = newPosition;
            pageView.pageMode = self.mode;
            pageView.leftPage = leftPageForPosition(newPosition, self.mode, self.lead, self.direction, _maxNumberOfPages);
            pageView.rightPage = rightPageForPosition(newPosition, self.mode, self.lead, self.direction, _maxNumberOfPages);
            
            [self moveLayer:pageView toFrame:frame];
            
            if(newPosition == _currentPosition)
            {
                self.current = pageView;
            }
        }
    }
    else
    {
        
        for(FPKPageView * wrapper in _wrappers)
        {
            NSInteger currentLayerPosition = wrapper.position;
            NSInteger newPosition = newLayerPosition((int)currentLayerPosition,(int)_currentPosition, _fpk_preview_next_bias, _fpk_preview_prev_bias, _fpk_preview_count,(int)_currentNumberOfPositions);
            
            if(newPosition == _currentPosition)
            {
                self.current = wrapper;
            }
            
            if(newPosition != currentLayerPosition)
            {
                CGRect newFrame = [self frameForLayer:newPosition withBuffering:forceFrame];
                
#if FPK_DEBUG_FRAMES
                NSLog(@"Updating frame of %@ to %@ (forced %d)",[wrapper name], NSStringFromCGRect(newFrame),forceFrame);
#endif
                
                wrapper.position = newPosition;
                wrapper.pageMode = self.mode;
                wrapper.leftPage = leftPageForPosition(newPosition, self.mode, self.lead, self.direction, _maxNumberOfPages);
                wrapper.rightPage = rightPageForPosition(newPosition, self.mode, self.lead, self.direction, _maxNumberOfPages);
                
                [self moveLayer:wrapper toFrame:newFrame];
            }    
        }        
    }
}

-(int)numberOfPositions
{
    if(_currentMode == MFDocumentModeOverflow)
    {
        return (int)_maxNumberOfPages;
    }
    else
    {
        return (int)numberOfPositions(_maxNumberOfPages, _currentMode, _currentLead);
    }
}

-(CGRect)frameForLayer:(NSInteger)pos withBuffering:(BOOL)buffering {
    
    return rectForPosition(pos, _currentSize);
}

-(CGPoint)convertPoint:(CGPoint)point fromViewtoPage:(NSUInteger)page
{
    return [self.current convertPoint:point fromViewToPage:page];
}

-(CGPoint)convertPoint:(CGPoint)point toViewFromPage:(NSUInteger)page
{
    return [self.current convertPoint:point toViewFromPage:page];
}

-(CGRect)convertRect:(CGRect)rect fromViewToPage:(NSUInteger)page
{
    return [self.current convertRect:rect fromViewToPage:page];
}

-(CGRect)convertRect:(CGRect)rect toViewFromPage:(NSUInteger)page
{
     return [self.current convertRect:rect toViewFromPage:page];
}

-(CGPoint)convertPoint:(CGPoint)point fromOverlayToPage:(NSUInteger)page
{
    //TODO:fix this
    return CGPointZero;
}

-(CGPoint)convertPoint:(CGPoint)point toOverlayFromPage:(NSUInteger)page
{
        //TODO: fix this
    //return [detailView convertPoint:point toOverlayFromPage:page]; // Point from page coordinates to overlay space.
    return CGPointZero;
}

-(CGRect)convertRect:(CGRect)rect fromOverlayToPage:(NSUInteger)page
{
        //TODO: fix this
    //return [detailView convertRect:rect fromOverlayToPage:page];
    return CGRectZero;
}

-(CGRect)convertRect:(CGRect)rect toOverlayFromPage:(NSUInteger)page
{
        //TODO: fix this
    //return [detailView convertRect:rect toOverlayFromPage:page];
    return CGRectZero;
}

-(BOOL)isDirectionalLockEnabled
{
    //TODO:fix this
    //return [detailView.scrollDetailView isDirectionalLockEnabled];
    return false;
}

-(void)setDirectionalLockEnabled:(BOOL)yesOrNo
{
    //TODO: fix this
    //[detailView.scrollDetailView setDirectionalLockEnabled:yesOrNo];
}

-(NSUInteger)leftPage
{
    return leftPageForPosition(_currentPosition, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
}

-(NSUInteger)rightPage
{
    return rightPageForPosition(_currentPosition, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
}

-(CGFloat)padding {
    return self.settings.padding;
}

-(void)setPadding:(CGFloat)p
{
    /* Clip padding value between 0 and 100 */
    self.settings.padding = p;
}

-(BOOL)isPageOnScreen:(NSUInteger)page {
    
    // Check if the position for the page passed is the current position. If so, it means we are on the right
    // position already and there's no need to change the page.
    
    NSInteger position = positionForPage(page, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
    
    return (position == _currentPosition);
}

#pragma mark - Interaction 

-(NSArray *)annotationsAtLocation:(CGPoint)location {
    return nil;
}

-(NSArray *)overlayViewsAtLocation:(CGPoint)location {
    return nil;
}

#pragma mark - Caches

-(FPKPageZoomCache *)pageZoomCache {
    if(!_pageZoomCache) {
        _pageZoomCache = [FPKPageZoomCache new];
    }
    return _pageZoomCache;
}

#pragma mark - Overlay views

-(Class<MFAudioPlayerViewProtocol>)classForAudioPlayerView {
    
    if([_documentDelegate respondsToSelector:@selector(classForAudioPlayerView)]) {
        return [_documentDelegate classForAudioPlayerView];
    }
    return nil;
}


-(void)reloadOverlay {
    
    // Clear the caches first!
    [self.childViewControllersHelper removeAllObjects];
    [self.privateOverlayViewHelper removeAllObjects];
    [self.drawablesHelper removeAllObjects];

    // Non-current page views will automatically reload overlays when current.
    [self.current reloadOverlays];
}

#pragma mark - OverlayViews

-(void)willRemoveOverlayView:(FPKOverlayViewHolder *)ov {
    
        if([ov.dataSource respondsToSelector:@selector(documentViewController:willRemoveOverlayView:)]) {
            [ov.dataSource documentViewController:self willRemoveOverlayView:ov.view];
        }
}

-(void)didRemoveOverlayView:(FPKOverlayViewHolder *)ov
{
        if([ov.dataSource respondsToSelector:@selector(documentViewController:didRemoveOverlayView:)]) {
        [ov.dataSource documentViewController:self didRemoveOverlayView:ov.view];
        }
}

-(void)willAddOverlayView:(FPKOverlayViewHolder *)ov
{
    if([ov.dataSource respondsToSelector:@selector(documentViewController:willAddOverlayView:)]) {
        [ov.dataSource documentViewController:self willAddOverlayView:ov.view];
    }
}

-(void)didAddOverlayView:(FPKOverlayViewHolder *)ov {
    
        if([ov.dataSource respondsToSelector:@selector(documentViewController:didAddOverlayView:)]) {
            [ov.dataSource documentViewController:self didAddOverlayView:ov.view];
        }
}

-(NSArray *)overlayViewsForPage:(NSUInteger)page {
    
    NSMutableArray * overlayViews = [[NSMutableArray alloc]init];
   
    if(YES || (!fpk_view_version)) {
        
        MFDocumentViewController * __weak this = self;
        [self.overlayViewDataSources enumerateKeysAndObjectsUsingBlock:^(id key, id<FPKOverlayViewDataSource> obj, BOOL *stop) {
            
            NSArray * views = [obj documentViewController:this overlayViewsForPage:page];
            
            [views enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
               
                FPKOverlayViewHolder * holder = [FPKOverlayViewHolder new];
                holder.view = view;
                holder.dataSource = obj;
                [overlayViews addObject:holder];
            }];
        }];
    }
    
    return overlayViews; 
}

-(CGRect)collectRectForOverlayView:(FPKOverlayViewHolder *)ov page:(NSUInteger)page {
    
    // 1. Ask for the frame (UI coordinates)
    if([ov.dataSource respondsToSelector:@selector(documentViewController:frameForOverlayView:onPage:)]) {
        CGRect rect = [ov.dataSource documentViewController:self frameForOverlayView:ov.view onPage:page];
        if(!CGRectIsNull(rect)) {
            ov.pdfCoordinates = NO;
            return rect;
        }
    }
    
    // 2. If the rect is still CGRectNull, ask for the rect (PDF coordinates)
    if ([ov.dataSource respondsToSelector:@selector(documentViewController:rectForOverlayView:onPage:)]) {
        CGRect rect = [ov.dataSource documentViewController:self rectForOverlayView:ov.view onPage:page];
        if(!CGRectIsNull(rect)) {
            ov.pdfCoordinates = YES;
            return rect;
        }
    }
    
    return CGRectNull;
}

-(id<FPKOverlayViewDataSource>)overlayViewDataSourceWithName:(NSString *)name {
    return self.overlayViewDataSources[name];
}

-(void)addOverlayViewDataSource:(id<FPKOverlayViewDataSource>)ovds name:(NSString *)name {
    
    if([ovds respondsToSelector:@selector(documentViewController:overlayViewsForPage:)]) {
        self.overlayViewDataSources[name] = ovds;
        [self reloadOverlay];
    }
}

-(NSString *)addOverlayViewDataSource:(id<FPKOverlayViewDataSource>)ovds {
    if(ovds) {
        NSString * randomName = [[NSUUID UUID] UUIDString];
        [self addOverlayViewDataSource:ovds name:randomName];
        return randomName;
    }
    return nil;
}

-(id<FPKOverlayViewDataSource>)removeOverlayViewDataSourceWithName:(NSString *)name {
    
    id<FPKOverlayViewDataSource> dataSource = self.overlayViewDataSources[name];
    if(dataSource) {
        [self.overlayViewDataSources removeObjectForKey:name];
        [self reloadOverlay];
    }
    return dataSource;
}

-(void)removeOverlayViewDataSource:(id<FPKOverlayViewDataSource>)ovds {
    
    NSArray * keys = [self.overlayViewDataSources allKeysForObject:ovds];
    if(keys.count > 0) {
        [self.overlayViewDataSources removeObjectsForKeys:keys];
        [self reloadOverlay];
    }
}

#pragma mark - Internal Overlay Views

-(BOOL)doesHaveToLoopVideo:(NSString *)videoUri {
    if([_documentDelegate respondsToSelector:@selector(documentViewController:doesHaveToLoopVideo:)]) {
        return [_documentDelegate documentViewController:self doesHaveToLoopVideo:videoUri];
    }
    return NO;
}

-(BOOL)doesHaveToAutoplayVideo:(NSString*)videoUri {
    
    if([_documentDelegate respondsToSelector:@selector(documentViewController:doesHaveToAutoplayVideo:)]) {
        return [_documentDelegate documentViewController:self doesHaveToAutoplayVideo:videoUri];
    }
    return NO;
}

-(BOOL)doesHaveToAutoplayAudio:(NSString*)audioUri {
    
    if([_documentDelegate respondsToSelector:@selector(documentViewController:doesHaveToAutoplayAudio:)]) {
        return [_documentDelegate documentViewController:self doesHaveToAutoplayAudio:audioUri];
    }
    return NO;
}

#pragma mark -

-(float)zoomLevelForAnnotationRect:(CGRect)rect ofPage:(NSUInteger)page {
    
    //TODO:fix this
    //return [detailView zoomLevelForAnnotationRect:rect ofPage:page];
    
    return 1.0;
}

-(float)zoomScale {

    //TODO:fix this
    //return [detailView zoomScale];
    return 1.0;
}

-(CGPoint)zoomOffset {
    
    //TODO: fix this
    //return [detailView zoomOffset];
    return CGPointZero;
}


-(void)setStartingPage:(NSUInteger)startingpage {

	_startingPage = startingpage;
	// currentPage = startingpage; // Will be set in viewWillAppear
}

#pragma mark - Overlay touchables and drawables

-(void)addOverlayDataSource:(id<MFDocumentOverlayDataSource>)ods {
    if(![self.overlayDataSources containsObject:ods]) {
        [self.overlayDataSources addObject:ods];
        [self reloadOverlay];
    }
}

-(void)removeOverlayDataSource:(id<MFDocumentOverlayDataSource>)ods {
    if([self.overlayDataSources containsObject:ods]) {
        [self.overlayDataSources removeObject:ods];
        [self reloadOverlay];
    }
}

-(void)didReceiveTapOnTouchable:(id<MFOverlayTouchable>)touchable {
    
    MFDocumentViewController * __weak this = self;
    [self.overlayDataSources enumerateObjectsUsingBlock:^(id<MFDocumentOverlayDataSource> obj, BOOL *stop) {
        if([obj respondsToSelector:@selector(documentViewController:didReceiveTapOnTouchable:)]) {
            [obj documentViewController:this didReceiveTapOnTouchable:touchable];
        }
    }];
}

-(FlipContainer *)touchablesForPage:(NSUInteger)page {
    
    FlipContainer * container = [FlipContainer new];
    
    [self.overlayDataSources enumerateObjectsUsingBlock:^(id<MFDocumentOverlayDataSource> obj, BOOL *stop) {
        if([obj respondsToSelector:@selector(documentViewController:touchablesForPage:)]) {
            NSArray * touchies = [obj documentViewController:self touchablesForPage:page];
            [container.pdf addObjectsFromArray:touchies];
            return;
        }
        
        if([obj respondsToSelector:@selector(documentViewController:touchablesForPage:pdfCoordinates:)]) {
            BOOL flip = false;
            NSArray * t = [obj documentViewController:self touchablesForPage:page pdfCoordinates:&flip];
            if(flip) {
                [container.pdf addObjectsFromArray:t];
            } else {
                [container.ui addObjectsFromArray:t];
            }
        }
    }];
    
    return container;
}

-(FlipContainer *)drawablesForPage:(NSUInteger)page {

    FlipContainer * container = [FlipContainer new];
    
    [self.overlayDataSources enumerateObjectsUsingBlock:^(id<MFDocumentOverlayDataSource> obj, BOOL *stop) {
        
        if([obj respondsToSelector:@selector(documentViewController:drawablesForPage:)]) {
                NSArray * drawies = [obj documentViewController:self drawablesForPage:page];
                [container.pdf addObjectsFromArray:drawies];
                return;
        }
        
        if([obj respondsToSelector:@selector(documentViewController:drawablesForPage:pdfCoordinates:)]) {
            
            BOOL flip = false; // Reset this each iteration
            NSArray * d = [obj documentViewController:self drawablesForPage:page pdfCoordinates:&flip];
            if(flip) {
                [container.pdf addObjectsFromArray:d];
            } else {
                [container.ui addObjectsFromArray:d];
            }
        }
    }];
    
    return container;
}

#pragma mark -

-(void)resizeContentOfScrollView:(UIScrollView *)scrollView toContainPages:(NSUInteger)nrOfPages {
	
	CGSize contentSize = sizeForContent(_currentNumberOfPositions, _currentSize);
	[scrollView setContentSize:contentSize];
}

-(void)setCurrent:(FPKPageView *)current {
    if(current != _current) {
        _current.inFocus = NO;
        _current = current;
        _current.inFocus = YES;
    }
}

-(void)updatePosition:(NSInteger)position {
    
    [self checkAndUpdateLayers:NO];
}

#pragma mark -
#pragma mark DocumentDelegate callback accessors

/**
    If rect is CGRectNull, it will return whether the document delegate respond to the appropriate selector. Otherwise, will invoke the delegate
 method and return NO.
 */
-(BOOL)didReceiveDoubleTapOnAnnotationRect:(CGRect)rect withUri:(NSString *)uri onPage:(NSUInteger)page {
    
    if(CGRectIsNull(rect)) {
        
        return [_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveDoubleTapOnAnnotationRect:withUri:onPage:)];
        
    } else {
        
        if([_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveDoubleTapOnAnnotationRect:withUri:onPage:)]) {
            
            [_documentDelegate documentViewController:self didReceiveDoubleTapOnAnnotationRect:rect withUri:uri onPage:page];
        }
    }
    return NO;    
}


-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect page:(NSUInteger)pageNumber file:(NSString *)fileName {
    
    if([self.documentDelegate respondsToSelector:@selector(documentViewController:didReceiveRequestToGoToPage:ofFile:)]) {
        [self.documentDelegate documentViewController:self didReceiveRequestToGoToPage:pageNumber ofFile:fileName];
        return YES;
    }
    return NO;
}

-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect destination:(NSString *)destinationName file:(NSString *)fileName {
 
        if([self.documentDelegate respondsToSelector:@selector(documentViewController:didReceiveRequestToGoToDestinationNamed:ofFile:)]) {
            [self.documentDelegate documentViewController:self didReceiveRequestToGoToDestinationNamed:destinationName ofFile:fileName];
            return YES;
        }
    return NO;
}

-(void)playVideo:(NSString *)path local:(BOOL)local {
    
}

-(void)showWebView:(NSString *)uri local:(BOOL)local {
    
}

-(void)didReceiveURIRequest:(NSString *)uri {
    
    // TODO: add default implementation
    
    /*
    if ([uri hasPrefix:@"#page="]) {
        
        // Chop the page parameters into an array and set is as current page parameters
        
        NSArray *arrayParameter = nil;
        
        arrayParameter = [uri componentsSeparatedByString:@"="];
        
        [self setPage:[[arrayParameter objectAtIndex:1]intValue]];
        
        return;
        
    }
    
    if([uri hasPrefix:@"mailto:"]) {
        
        return;
    }
    
    NSString *uriType = nil;
    NSString *uriResource = nil;
    
    NSRange separatorRange = [uri rangeOfString:@"://"];
    
    if(separatorRange.location!=NSNotFound) {

        uriType = [uri substringToIndex:separatorRange.location];
        
        uriResource = [uri substringFromIndex:separatorRange.location + separatorRange.length];
        
        if ([uriType isEqualToString:@"fpke"]||[uriType isEqualToString:@"videomodal"])
        {
            NSString * documentPath = [self.document.resourceFolder stringByAppendingPathComponent:uriResource];
            [self playVideo:documentPath local:YES];
        }
        
        if ([uriType isEqualToString:@"fpkz"]||[uriType isEqualToString:@"videoremotemodal"])
        {
            NSString * documentPath = [@"http://" stringByAppendingString:uriResource];
            [self playVideo:documentPath local:NO];
        }
        
        if ([uriType isEqualToString:@"fpki"]||[uriType isEqualToString:@"htmlmodal"])
        {
            NSString * documentPath = [self.document.resourceFolder stringByAppendingPathComponent:uriResource];
            [self showWebView:documentPath local:YES];
        }
        
        if ([uriType isEqualToString:@"http"]){
            [self showWebView:uri local:NO];
        }
    }*/
}


-(BOOL)didReceiveTapOnAnnotationRect:(CGRect)rect withUri:(NSString *)uri onPage:(NSUInteger)page {
    
    if(CGRectIsNull(rect)) {
        
        return [_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveTapOnAnnotationRect:withUri:onPage:)];
        
    } else {
     
        if([self.documentDelegate respondsToSelector:@selector(documentViewController:didReceiveTapOnAnnotationRect:withUri:onPage:)]) {
            [self.documentDelegate documentViewController:self didReceiveTapOnAnnotationRect:rect withUri:uri onPage:page];
        }
        
        // Other delegates handling
        NSUInteger count = self.delegates.count;
        
        for(NSUInteger index = 0; index < count; index++) {
         
            id<MFDocumentViewControllerDelegate> dlgt = [self.delegates pointerAtIndex:index];
            
            if(dlgt && [dlgt respondsToSelector:@selector(documentViewController:didReceiveTapOnAnnotationRect:withUri:onPage:)]) {
                [dlgt documentViewController:self didReceiveTapOnAnnotationRect:rect withUri:uri onPage:page];
            }
        } // End of other delegates handling
        
        if([_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveURIRequest:)]) {
            if(![_documentDelegate documentViewController:self didReceiveURIRequest:uri]) {
                [self didReceiveURIRequest:uri];
            }
        }
    }
    return NO;
}

-(void)didEndZoomAtScale:(float)level {
    
    if([_documentDelegate respondsToSelector:@selector(documentViewController:didEndZoomingAtScale:)]) {
		[_documentDelegate documentViewController:self didEndZoomingAtScale:level];
	}
}

-(void)didReceiveTapOnPage:(NSUInteger)page atPoint:(CGPoint)point {

	if([_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveTapOnPage:atPoint:)]) {
		[_documentDelegate documentViewController:self didReceiveTapOnPage:page atPoint:point];
	}
}

-(void)didReceiveTapAtPoint:(NSValue *)pv {
	
	NSValue *value = pv;
	
	CGPoint point; 
	[value getValue:&point];
	
	if([_documentDelegate respondsToSelector:@selector(documentViewController:didReceiveTapAtPoint:)]) {
		[_documentDelegate documentViewController:self didReceiveTapAtPoint:point];
	}
	
}

-(void)willFollowLinkToPage:(NSUInteger)page {
    if([_documentDelegate respondsToSelector:@selector(documentViewController:willFollowLinkToPage:)]) {
        [_documentDelegate documentViewController:self willFollowLinkToPage:page];
    }
}

#pragma mark - Internal status management

-(MFDocumentLead)currentLead {
	return _currentLead;
}
-(MFDocumentMode)currentMode {
	return _currentMode;
}
-(MFDocumentDirection)currentDirection {
	return _currentDirection;
}

-(void)nextVisitedPage {
    
    if([self nextVisitedPagesCount] > 0) {
        _visitPage = YES;
        [self setPage:cb_nextPage(&_visitedPages)];
    }
}

-(void)previousVisitedPage {
    
    if([self previousVisitedPagesCount] > 0) {
        _visitPage = YES;
        [self setPage:cb_prevPage(&_visitedPages)];
    }
}

-(NSInteger)nextVisitedPagesCount {
    
    return cb_nextCount(&_visitedPages);
}

-(NSInteger)previousVisitedPagesCount {
    
    return cb_prevCount(&_visitedPages);
}

-(void)pageSliderCancel:(UISlider *)slider {
    
    [_pageSlider setValue:[self page] animated:NO]; // Reset the slider
    [_pageSliderLabel setText:[self pageSliderTitleForPage:_currentPage]]; // Reset the label
}

-(void)pageSliderSlided:(UISlider *)slider {

	// When the user move the slider, we update the label.

	// Get the slider value.
	NSNumber *number = [NSNumber numberWithFloat:[slider value]];
	NSUInteger pageNumber = [number unsignedIntValue];

    self.pageSliderLabel.text = [self pageSliderTitleForPage:pageNumber];
}

-(void)pageSliderStopped:(UISlider *)slider {

	// Get the requested page number from the slider.
	NSNumber *number = [NSNumber numberWithFloat:[slider value]];
	NSUInteger pageNumber = [number unsignedIntValue];

	// Go to the page.
	[self setPage:pageNumber];
}

-(NSString *)pageSliderTitleForPage:(NSUInteger)page {
    return [NSString stringWithFormat:@"%lu", (unsigned long)page];
}

-(void)updateStatusViews
{
    [_pageSlider setValue:[[NSNumber numberWithUnsignedInteger:_currentPage]floatValue] animated:YES];
    
    [_thumbnailScrollView setPage:_currentPage animated:YES];
    
    [_pageSliderLabel setText:[self pageSliderTitleForPage:_currentPage]];
}


-(void)setCurrentPage:(NSUInteger)newPage {
    
    if(_visitPage) {
        
        _visitPage = NO;
        
    } else {
        
        if(cb_currentPage(&_visitedPages)!=newPage)
            cb_addPage(&_visitedPages, newPage);
    }
    
	if(_currentPage != newPage) {
		_currentPage = newPage;
        
        [self updateStatusViews];
        
		if([_documentDelegate respondsToSelector:@selector(documentViewController:didGoToPage:)]) {
			[_documentDelegate documentViewController:self didGoToPage:newPage];
		}
	}
}

-(void)setCurrentLead:(MFDocumentLead)newLead {
	
	if(_currentLead != newLead) {
		_currentLead = newLead;
		
		if([_documentDelegate respondsToSelector:@selector(documentViewController:didChangeLeadTo:)]) {
			[_documentDelegate documentViewController:self didChangeLeadTo:newLead];
		}
	}
}

-(void)setCurrentAutoMode:(MFDocumentAutoMode)newAutoMode {
    if(_currentAutoMode != newAutoMode) {
        _currentAutoMode = newAutoMode;
        if([_documentDelegate respondsToSelector:@selector(documentViewController:didChangeAutoModeTo:)]) {
            [_documentDelegate documentViewController:self didChangeAutoModeTo:_currentAutoMode];
        }
    }
}

-(void)setCurrentMode:(MFDocumentMode)newMode {
	if(_currentMode != newMode) {
		_currentMode = newMode;
		if([_documentDelegate respondsToSelector:@selector(documentViewController:didChangeModeTo:automatic:)]) {
			[_documentDelegate documentViewController:self didChangeModeTo:newMode automatic:_autoMode];
		}
	}
}

-(void)setCurrentDirection:(MFDocumentDirection)newDirection {
	if(_currentDirection != newDirection) {
		_currentDirection = newDirection;
		
		if([_documentDelegate respondsToSelector:@selector(documentViewController:didChangeDirectionTo:)]) {
			[_documentDelegate documentViewController:self didChangeDirectionTo:newDirection];
		}
	}
}


-(BOOL)showHorizontalScroller {
    return [_pagedScrollView showsHorizontalScrollIndicator];
}

-(void)setShowHorizontalScoller:(BOOL)show {
    [_pagedScrollView setShowsHorizontalScrollIndicator:show];
}

-(void)changePageDirection {
	
	// Noew we can cancel pending rendering ops
    //[self.operationCenter cancelAllOperations];
	
	NSInteger newPosition = positionForPage(_currentPage, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
	_currentPosition = newPosition;
	
	// Disable scrolling check to avoid nasty things!
	_pageControlUsed = YES;
	
//	// Unfocus the detail view if necessary
//	if([current focused]) {
//        
//		[self unfocusFrom:current];
//	}
//    
    //[detailView isOutOfSight:NO];
    //[detailView setHidden:YES];
    
    [self hideAllLayers];
    
    [_pagedScrollView setContentOffset:CGPointMake(newPosition * _currentSize.width, 0) animated:NO];
    
    [self checkAndUpdateLayers:YES];
    
    [self showAllLayers];
	
//	// Calculate new frames for the layers
//	CGRect newCurrentFrame = [self frameForLayer:newPosition];
//	CGRect newNextFrame = [self frameForLayer:newPosition+1];
//	CGRect newPrevFrame = [self frameForLayer:newPosition-1];
//	CGRect newFormerFrame = [self frameForLayer:newPosition+2];
//	
//	[current setPosition:newPosition];
//	[current updateWithContentOfSize:[NSValue valueWithCGSize:newCurrentFrame.size]];
//	
//	[next setPosition:newPosition+1];
//	[next updateWithContentOfSize:[NSValue valueWithCGSize:newNextFrame.size]];
//	
//	[previous setPosition:newPosition-1];
//	[previous updateWithContentOfSize:[NSValue valueWithCGSize:newPrevFrame.size]];
//	
//	[former setPosition:newPosition+2];
//	[former updateWithContentOfSize:[NSValue valueWithCGSize:newFormerFrame.size]];
//	
//	// Perform update
//	[CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[current layer]setFrame:newCurrentFrame];
//	[[current layer]setHidden:YES];
//	[[next layer]setFrame:newNextFrame];
//	[[next layer]setHidden:YES];
//	[[previous layer]setFrame:newPrevFrame];
//	[[previous layer]setHidden:YES];
//	[[former layer]setFrame:newFormerFrame];
//	[[former layer]setHidden:YES];
//	[CATransaction commit];
	

	
//	// Unhide
//	[CATransaction begin]; 
//	[[current layer]setHidden:NO];
//	[[next layer]setHidden:NO];
//	[[previous layer]setHidden:NO];
//	[[former layer]setHidden:NO];
//	[CATransaction commit];
	
	// Refocus
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
    //[detailView setHidden:NO];
}

-(void)setEdgeFlipWidth:(CGFloat)edgeFlipWidth {
    CGFloat clipped = MAX(MIN(edgeFlipWidth,0.5), 0.0);
    _edgeFlipWidth = clipped;
}

-(void)moveDetailToPosition:(NSInteger)position {
    
    //TODO: fix this
    //CGRect detailRect = rectForPosition(position, currentSize);
    //detailView.frame = detailRect;
    
    _currentDetailPosition = position;
}


-(void)moveLayerToDetail {
    
    //N.B. Questo non fa più nulla
}

-(void)removeLayerFromDetail {
    
    /* Do nothing! */
}

-(void)changePageMode {
	
    //[self.operationCenter cancelAllOperations];
	
	// Save the position & page
	NSInteger newPosition = positionForPage(_currentPage, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
	_currentPosition = newPosition;
	
	// ... but since we re not, let's move (without triggering any scroll)!
	_pageControlUsed = YES;
    
    [self hideAllLayers];
    
    _currentNumberOfPositions = [self numberOfPositions];
	
    [_pagedScrollView setContentSize:sizeForContent(_currentNumberOfPositions, _currentSize)];
	[_pagedScrollView setContentOffset:CGPointMake(newPosition * _currentSize.width, 0) animated:NO];
	
    [self checkAndUpdateLayers:YES];
    
    [self showAllLayers];
    
	// Refocus
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
    //[detailView setHidden:NO];
}

-(void)changePageLead {
	
    //[self.operationCenter cancelAllOperations];
	
	// Since a change in the lead can change the number of position, check for it and change the current position accordingly
	_currentNumberOfPositions = [self numberOfPositions];
	
	if(_currentPosition>(_currentNumberOfPositions-1))
		_currentPosition--;
	
	
	// There are chances a change of current page is need, since the current page will go out of the screen.
	// This is actually an error and page should be maintained
	NSUInteger newPage = pageForPosition(_currentPosition, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages); // Recalculate current page
	if(newPage!=_currentPage) {
		[self setCurrentPage:newPage];
	}
	
	// Disable scrolling check to avoid nasty things!
	_pageControlUsed = YES;
	
//	// Unfocus the detail view if necessary
//	if([current focused]) {
//		[self unfocusFrom:current];
//	}
    
    //[detailView isOutOfSight:NO];
    //[detailView setHidden:YES];
    
    [self hideAllLayers];
    
	// NSInteger newPosition = currentPosition; // Just to not rename the position variable in copypaste code...
	
//	// Calculate new frames for the layers
//	CGRect newCurrentFrame = [self frameForLayer:newPosition];
//	CGRect newNextFrame = [self frameForLayer:newPosition+1];
//	CGRect newPrevFrame = [self frameForLayer:newPosition-1];
//	CGRect newFormerFrame = [self frameForLayer:newPosition+2];
//	
//	[current setPosition:newPosition];
//	[current updateWithContentOfSize:[NSValue valueWithCGSize:newCurrentFrame.size]];
//	
//	[next setPosition:newPosition+1];
//	[next updateWithContentOfSize:[NSValue valueWithCGSize:newNextFrame.size]];
//	
//	[previous setPosition:newPosition-1];
//	[previous updateWithContentOfSize:[NSValue valueWithCGSize:newPrevFrame.size]];
//	
//	[former setPosition:newPosition+2];
//	[former updateWithContentOfSize:[NSValue valueWithCGSize:newFormerFrame.size]];
//	
//	// Perform update
//	[CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[current layer]setFrame:newCurrentFrame];
//	[[current layer]setHidden:YES];
//	[[next layer]setFrame:newNextFrame];
//	[[next layer]setHidden:YES];
//	[[previous layer]setFrame:newPrevFrame];
//	[[previous layer]setHidden:YES];
//	[[former layer]setFrame:newFormerFrame];
//	[[former layer]setHidden:YES];
//	[CATransaction commit];
	
	// Recalculate number of positions and content size of the scroll view
	_currentNumberOfPositions = [self numberOfPositions];
	[_pagedScrollView setContentSize:sizeForContent(_currentNumberOfPositions, _currentSize)];
	[_pagedScrollView setContentOffset:CGPointMake(_currentPosition * _currentSize.width, 0) animated:NO];
	
    [self checkAndUpdateLayers:YES];
    
    [self showAllLayers];
    
//	// Unhide
//	[CATransaction begin]; 
//	[[current layer]setHidden:NO];
//	[[next layer]setHidden:NO];
//	[[previous layer]setHidden:NO];
//	[[former layer]setHidden:NO];
//	[CATransaction commit];
	
	// Refocus
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
    //[detailView setHidden:NO];
}

-(void)goToPage:(NSUInteger)page withZoomOfLevel:(float)zoomLevel onRect:(CGRect)rect {

    // TODO: qui c'è qualcosa che non va quando si navigano i risultati della ricerca. La preview finisce sopra...
    
	if(![self isPageOnScreen:page]) {
	
        // NSLog(@"On different page");
        
        // Noew we can cancel pending rendering ops
        //[self.operationCenter cancelAllOperations];
		
		// Save the position
		NSInteger position = positionForPage(page, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
		_currentPosition = position;

		// ... but since we re not, let's move (without triggering any scroll)!
		_pageControlUsed = YES;
		
//		// Unfocus the detail view if necessary
//		if([current focused]) {
//			[self unfocusFrom:current];
//		}
        
        //[detailView isOutOfSight:NO];
        //[detailView setHidden:YES];
        
        [self hideAllLayers];
        
        [self checkAndUpdateLayers:YES];
		
//		// Calculate new frames for the layers
//        CGRect newCurrentFrame = [self frameForLayer:position];
//        CGRect newNextFrame = [self frameForLayer:position+1];
//        CGRect newPrevFrame = [self frameForLayer:position-1];
//        CGRect newFormerFrame = [self frameForLayer:position+2];
//        
//        [current setPosition:position];
//        [current updateWithContentOfSize:[NSValue valueWithCGSize:newCurrentFrame.size]];
//        
//        [next setPosition:position+1];
//        [next updateWithContentOfSize:[NSValue valueWithCGSize:newNextFrame.size]];
//        
//        [previous setPosition:position-1];
//        [previous updateWithContentOfSize:[NSValue valueWithCGSize:newPrevFrame.size]];
//        
//        [former setPosition:position+2];
//        [former updateWithContentOfSize:[NSValue valueWithCGSize:newFormerFrame.size]];
//		
//		// Perform update
//		[CATransaction begin]; 
//		[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//		[[current layer]setFrame:newCurrentFrame];
//		[[current layer]setHidden:YES];
//		[[next layer]setFrame:newNextFrame];
//		[[next layer]setHidden:YES];
//		[[previous layer]setFrame:newPrevFrame];
//		[[previous layer]setHidden:YES];
//		[[former layer]setFrame:newFormerFrame];
//		[[former layer]setHidden:YES];
//		[CATransaction commit];
		
		// Update the scrollview offset
		[_pagedScrollView setContentOffset:CGPointMake(position * _currentSize.width, 0) animated:NO];
		
		// Save the current position
				
		// Unhide[self.searchManager cancelSearch];
//		[CATransaction begin]; 
//		[[current layer]setHidden:NO];
//		[[next layer]setHidden:NO];
//		[[previous layer]setHidden:NO];
//		[[former layer]setHidden:NO];
//		[CATransaction commit];

		[self showAllLayers];
        
		// Update status
		[self setCurrentPage:page];
        
        // [detailView setHidden:NO];
        
	} else {
        
        // NSLog(@"Already on the same page");
        
    }
	
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:rect],@"rect",
                           [NSNumber numberWithUnsignedInteger:page],@"page",
                           [NSNumber numberWithFloat:zoomLevel],@"zoomLevel",
                           nil];
    
	// Refocus
	[self performSelector:@selector(focusOn:) withObject:info afterDelay:DETAIL_POPIN_DELAY];
}

-(void)goToPage:(NSUInteger)page {
	
	// Noew we can cancel pending rendering ops
    //[self.operationCenter cancelAllOperations];
	
	// Save the position
	NSInteger position = positionForPage(page, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
	_currentPosition = position;
	// ... but since we re not, let's move (without triggering any scroll)!
	_pageControlUsed = YES;
	
    [self hideAllLayers];
    
   
    
//	// Calculate new frames for the layers
//	CGRect newCurrentFrame = [self frameForLayer:position];
//	CGRect newNextFrame = [self frameForLayer:position+1];
//	CGRect newPrevFrame = [self frameForLayer:position-1];
//	CGRect newFormerFrame = [self frameForLayer:position+2];
//	
//	[current setPosition:position];
//	[current updateWithContentOfSize:[NSValue valueWithCGSize:newCurrentFrame.size]];
//	
//	[next setPosition:position+1];
//	[next updateWithContentOfSize:[NSValue valueWithCGSize:newNextFrame.size]];
//	
//	[previous setPosition:position-1];
//	[previous updateWithContentOfSize:[NSValue valueWithCGSize:newPrevFrame.size]];
//	
//	[former setPosition:position+2];
//	[former updateWithContentOfSize:[NSValue valueWithCGSize:newFormerFrame.size]];
//	
//	// Perform update
//	[CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[current layer]setFrame:newCurrentFrame];
//	[[current layer]setHidden:YES];
//	[[next layer]setFrame:newNextFrame];
//	[[next layer]setHidden:YES];
//	[[previous layer]setFrame:newPrevFrame];
//	[[previous layer]setHidden:YES];
//	[[former layer]setFrame:newFormerFrame];
//	[[former layer]setHidden:YES];
//	[CATransaction commit];
	
    [self checkAndUpdateLayers:YES];
    
	// Update the scrollview offset
	[_pagedScrollView setContentOffset:CGPointMake(position * _currentSize.width, 0) animated:NO];
	
	// Save the current position
	
	
	[self showAllLayers];
	//[detailView setHidden:NO];
    
	// Refocus
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];

	// Update status
	[self setCurrentPage:page];
}


- (void)moveToNextPage {
	
	if(_pageButtonUsed) {
		return;
	}
	
	NSInteger newPosition = _currentPosition+1;
	
	if(newPosition < 0 || newPosition >= _currentNumberOfPositions) {
		return;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(focusOn) object:nil];
	
	_pageButtonUsed = YES;
	_pageControlUsed = NO;
	self.savedUserInteractionEnabled = self.view.userInteractionEnabled;
	self.view.userInteractionEnabled = NO;
	
	CGPoint newOffset = CGPointMake(newPosition * _currentSize.width, 0);
	
	[_pagedScrollView setContentOffset:newOffset animated:YES];
	
}

- (void)moveToPreviousPage{
	
	if(_pageButtonUsed) {
		return;
	}
	
	NSInteger newPosition = _currentPosition-1;
	
	if(newPosition < 0 || newPosition >= _currentNumberOfPositions) {
		return;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(focusOn) object:nil];
	
	_pageButtonUsed = YES;
	_pageControlUsed = NO;
	self.savedUserInteractionEnabled = self.view.userInteractionEnabled;
	self.view.userInteractionEnabled = NO;
	
	CGPoint newOffset = CGPointMake(newPosition * _currentSize.width, 0);
	
	[_pagedScrollView setContentOffset:newOffset animated:YES];
}

-(void)focusOn:(NSDictionary *)info {
    if(info) {
        
        NSValue * rectValue = [info valueForKey:@"rect"];
        NSNumber * pageNumber = [info valueForKey:@"page"];
        NSNumber * zoomLevelNumber = [info valueForKey:@"zoomLevel"];
        
        CGRect rect;
        [rectValue getValue:&rect];
        NSUInteger page = [pageNumber unsignedIntValue];
        float zoomLevel = [zoomLevelNumber floatValue];
        
        [self focusOnRect:rect ofPage:page withZoomLevel:zoomLevel];
        
    } else {
        [self focusOn];
    }
}
              
-(void)focusOnRect:(CGRect)rect ofPage:(NSUInteger)page withZoomLevel:(float)level {
	
    //TODO: fix this
    
	//[detailView performZoomOnRect:rect ofPage:page withZoomLevel:level];
}

-(void)focusOn {
	
//	if([target focused]||isRotating)
//		return;
	
	if([_documentDelegate respondsToSelector:@selector(documentViewController:willFocusOnPage:)])
		[_documentDelegate documentViewController:self willFocusOnPage:_currentPage];
    
//	CGRect viewFrame = [[target layer]frame];
//	[target setRect:viewFrame]; // Save layer frame
//	[target setFocused:YES];
//	
//	NSInteger aPosition = [target position];
//	[detailViewController setOverlayEnabled:self.overlayEnabled];
//	[detailViewController setPosition:aPosition];
//	[detailViewController setPageDirection:currentDirection];
//	[detailViewController setPageMode:currentMode];
//	[detailViewController setPageLead:currentLead];
//	
//    viewFrame = [self frameForLayer:currentPosition];
////    NSLog(@"(%.3f x %.3f)[%.3f x %.3f] for position pos %d, [%.3f x %.3f]",viewFrame.origin.x,viewFrame.origin.y,viewFrame.size
////          .width,viewFrame.size.height,currentPosition,currentSize.width,currentSize.height);
//
//	   CGRect detailViewFrame = rectForPosition(target.position, currentSize);
//    [detailView setFrame:detailViewFrame];
//    [detailViewController resetContents];
//	//[detailViewController prepareContents];
//	[detailView setHidden:NO];
//	
//	CGRect layerRect = viewFrame;
//    layerRect.origin = CGPointZero;
//    
//	[CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[target layer] removeFromSuperlayer];
//	[[target layer] setFrame:layerRect]; // Splat the layer under the catiled layer
//	[[target layer] setZPosition:0.0];
//	[[[detailViewController previewView]layer] addSublayer:[target layer]];
//	[CATransaction commit];
//	
	if(_autoZoom) {
		// [detailView performSelector:@selector(performZoom) withObject:nil afterDelay:.2];
	}
	
	if([_documentDelegate respondsToSelector:@selector(documentViewController:didFocusOnPage:)])
		[_documentDelegate documentViewController:self didFocusOnPage:_currentPage];
}


//-(void)renderPreviewLayer:(MFDetailViewController *)target {
//    
//    CGRect layerRect = [self frameForLayer:currentDetailPosition];
//    
//    [CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[target layer]removeFromSuperlayer];
//	[[pagedScrollView layer]insertSublayer:[target layer] atIndex:0];
//	[[target layer]setFrame:layerRect];
//	[CATransaction commit];
//}


//-(void)releaseLayer:(MFDeferredContentLayerWrapper *)wrapper {
//    
//    [wrapper setFocused:NO];
//	
//	[CATransaction begin]; 
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[target layer]removeFromSuperlayer];
//	[[pagedScrollView layer]insertSublayer:[target layer] atIndex:0];
//	[[target layer]setFrame:[target rect]];
//	[CATransaction commit];
//}


-(void)loadConfigurationFromDictionary:(NSDictionary *)dictionary
{
    NSArray * configurations = dictionary[FPKConfigurationDictionaryConfigKey];
    
    for(NSDictionary * configuration in configurations)
    {
        NSArray * pages = configuration[FPKConfigurationDictionaryPageKey];
        if(pages)
        {
            for(NSNumber * page in pages)
            {
                if(page.integerValue == 0)
                {
                    /* Mode */
                    NSNumber * mode = configuration[FPKConfigurationDictionaryModeKey];
                    if(mode)
                    {
                        switch(mode.integerValue)
                        {
                            case 0:
                                self.mode = MFDocumentModeSingle;
                                break;
                            case 1:
                                self.mode = MFDocumentModeDouble;
                                break;
                            case 3:
                                self.mode = MFDocumentModeOverflow;
                                break;
                            default:
                                self.mode = MFDocumentModeSingle;
                            break;
                        }
                    }
                    
                    /* Padding */
                    NSNumber * padValue = configuration[FPKConfigurationDictionaryPaddingKey];
                    if(padValue)
                    {
                        self.padding = padValue.unsignedIntegerValue;
                    }
                    
                    /* Edge flip */
                    NSNumber * edges = configuration[FPKConfigurationDictionaryEdgeFlipKey];
                    if(!edges)
                    {
                        edges = configuration[FPKConfigurationDictionaryAlternateEdgeFlipKey];
                    }
                    if(edges)
                    {
                        self.edgeFlipWidth = edges.unsignedIntegerValue; // Rounded positive float
                    }
                    
                    
                    NSArray * orientations = configuration[FPKConfigurationDictionaryOrientationKey];
                    if(orientations)
                    {
                        FPKSupportedOrientation orientation = FPKSupportedOrientationNone;
                        for(NSNumber * o in orientations)
                        {
                            switch(o.integerValue) {
                        case 1:
                            orientation|=FPKSupportedOrientationPortaitBoth;
                            break;
                        case 2:
                            orientation|=FPKSupportedOrientationLandscape;
                        break;
                            }
                        }
                        self.supportedOrientation = orientation;
                    }
                    
                    break;
                }
            }
        }
    }
}

-(id)initWithDocumentManager:(MFDocumentManager *)aDocumentManager {
    
#if FPK_DEALLOC
    NSLog(@"%@ - initWithDocumentManager",NSStringFromClass([self class]));
#endif
    
    if((self = [super init]))
    {
    
#ifdef __IPHONE_7_0
        if([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
        {
                    self.automaticallyAdjustsScrollViewInsets = NO;
        }
#endif
        
        // Sync
        pthread_mutexattr_t attributes;
        pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_optionsMutex, &attributes);
        pthread_mutexattr_destroy(&attributes);
        
        self.operationCenter = [FPKOperationCenter new];
        
        self.supportedEmbeddedAnnotations = FPKEmbeddedAnnotationsAll;
        
        self.supportedOrientations = UIInterfaceOrientationMaskAll;
        
        checkSignature();
        
        self.overlayDataSources = [NSMutableSet new];
        self.overlayViewDataSources = [NSMutableDictionary new];
        
        _fpkAnnotationsEnabled = YES;

        self.delegates = [NSPointerArray weakObjectsPointerArray];
        
//        CFArrayCallBacks callbacks;
//        
//        callbacks.equal = NULL;
//        callbacks.release = NULL;
//        callbacks.copyDescription = NULL;
//        callbacks.retain = NULL;
//        
//        documentDelegates = CFArrayCreateMutable(NULL, 0, &callbacks);
        
        _document = aDocumentManager;
        _maxNumberOfPages = [_document numberOfPages];
		
        _thumbnailHeight = FPK_DEF_THUMB_HEIGHT;
        _thumbnailBarHeight = -1.0;
        
        _edgeFlipWidth = 0.1;
        
		_startingPage = 1;                                   // Def start page
		_currentPage = 0; // Pages start with 1. Will be initialized o startingPage later on, but better safe than sorry.
		_previewsCount = 4;
        
		_currentDirection = MFDocumentDirectionL2R;
		_currentLead = MFDocumentLeadRight;
		_currentMode = MFDocumentModeSingle;
        _currentAutoMode = MFDocumentAutoModeDouble;
        
        self.settings = [FPKSharedSettings loadSettings];
        
        self.pageFlipOnEdgeTouchEnabled = YES;              // Def YES
		self.zoomInOnDoubleTapEnabled = YES;                // Def YES
		self.documentInteractionEnabled = YES;              // Def NO
        self.defaultMaxZoomScale = 8.0;                     // Def 8.0
        
        _encryptionAlgorithm = FPKEncryptionAlgorithmAES;    // Def AES128
        
		_autoZoom = NO;                                      // Def NO
		_autoMode = NO;                                      // Def NO
        
        [self setPadding:5.0];                              // Def 5.0
        [self setShowShadow:YES];                           // Def YES
        
        _useTiledOverlayView = NO;                           // Def NO
		
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _pageSliderEnabled = NO;
            _thumbnailSliderEnabled = YES;
        }
        else
        {
            _pageSliderEnabled = YES;
            _thumbnailSliderEnabled = NO;
        }
        
        _backgroundThumbnailRenderingEnabled = YES;
        
        cb_init(&_visitedPages, 10);
		}
	
	return self;
}

-(void)setDefaultEdgeFlipWidth:(CGFloat)defaultEdgeFlipWidth {
    _edgeFlipWidth = defaultEdgeFlipWidth;
}

-(CGFloat)defaultEdgeFlipWidth {
    return _edgeFlipWidth;
}

-(void)setConfigurationDictionary:(NSDictionary *)configurationDictionary
{
    if(_configurationDictionary.hash != configurationDictionary.hash)
    {
        _configurationDictionary = configurationDictionary;
        [self loadConfigurationFromDictionary:_configurationDictionary];
    }
}

-(void)setShowShadow:(BOOL)newShowShadow {
    self.settings.showShadow = newShowShadow;
}

-(BOOL)showShadow {
    return self.settings.showShadow;
}

-(void)dealloc {
    
    [self.operationCenter cancelAllOperations];
    
	self.documentDelegate = nil;
    
    pthread_mutex_destroy(&_optionsMutex);
    cb_destroy(&_visitedPages);
}

#pragma mark - User entry points


-(void)setPage:(NSUInteger)page withZoomOfLevel:(float)level onRect:(CGRect)rect {
	
	if(page < 1 || page > _maxNumberOfPages) {
		return;
	}
	
	[self goToPage:page withZoomOfLevel:level onRect:rect];
}

-(void)setPage:(NSUInteger)page {
	
	if(page < 1 || page > _maxNumberOfPages) {
		return;
	}
	
	[self goToPage:page];
}

-(NSUInteger)page {
	return _currentPage;
}

-(void) setAutozoomOnPageChange:(BOOL)autozoom {
	
	if(_autoZoom != autozoom) {
		_autoZoom = autozoom;
	}
}

-(BOOL)autozoomOnPageChange {
	return _autoZoom;
}

-(MFDocumentDirection) direction {
	return _currentDirection;
}

-(void)setDirection:(MFDocumentDirection)newDirection {
	
	if(_currentDirection != newDirection) {
        
        // Change internal status.
        [self setCurrentDirection:newDirection];
        
        // Perform internal changes.
        [self changePageDirection];
        
        if(newDirection == MFDocumentDirectionL2R)
        {
            self.thumbnailScrollView.direction = TVThumbnailScrollViewDirectionForward;
        }
        else if(newDirection == MFDocumentDirectionR2L)
        {
            self.thumbnailScrollView.direction = TVThumbnailScrollViewDirectionBacward;
        }
	}
}


-(void)setLead:(MFDocumentLead)newLead {
    
    //	// Only works in double mode
    //	if(currentMode == MFDocumentModeSingle)
    //		return;
	
	// No need to change
	if(_currentLead != newLead) {
        
        // Change status & callback
        [self setCurrentLead:newLead];
        
        // Refresh view
        [self changePageLead];
    }
}

-(MFDocumentLead) lead {
	return _currentLead;
}

-(BOOL)automodeOnRotation {
	return _autoMode;
}

-(void)setAutomodeOnRotation:(BOOL)automatic {
	
	// No need to change, already in the right mode
	if(_autoMode == automatic)
		return;
	
	if(automatic) {
		
		// Enable automatic mode and set new mode depending on current orientation
		if(_currentOrientation == ORIENTATION_PORTRAIT) {
			
			if(_currentMode != MFDocumentModeSingle) {
				_currentMode = MFDocumentModeSingle;
                
				[self changePageMode];
				
			} else {
				// Current mode is fine, no need to redraw
			}
			
		} else if (_currentOrientation == ORIENTATION_LANDSCAPE) {
            
            if(_currentAutoMode == MFDocumentAutoModeDouble) {
                
                if(_currentMode != MFDocumentModeDouble) {
                    _currentMode = MFDocumentModeDouble;
                    [self changePageMode];
                }
                
            } else if(_currentAutoMode == MFDocumentAutoModeSingle) {
                
                if(_currentMode != MFDocumentModeSingle) {
                    _currentMode = MFDocumentModeSingle;
                    [self changePageMode];
                }
                
            } else if (_currentAutoMode == MFDocumentAutoModeOverflow) {
                
                if(_currentMode != MFDocumentModeOverflow) {
                    _currentMode = MFDocumentModeOverflow;
                    [self changePageMode];
                }
            }
        }
		
		
	} else {
		
		// Nothing to do, keep the current orientation
		
	}
	
	
	// Change state & callback
	_autoMode = automatic;
	
	if([_documentDelegate respondsToSelector:@selector(documentViewController:didChangeModeTo:automatic:)]) {
		[_documentDelegate documentViewController:self didChangeModeTo:_currentMode automatic:automatic];
	}
}

-(MFDocumentMode)mode {
	return _currentMode;
}

-(void)setMode:(MFDocumentMode)newMode  {
	
	// Disable auto mode
	_autoMode = NO;
    
	// Reposition the view & callback only if we actually changed mode
	if(_currentMode != newMode) {
		
		[self setCurrentMode:newMode];		
		[self changePageMode];
	}
}


-(MFDocumentAutoMode)autoMode {
    return _currentAutoMode;
}

-(void)setAutoMode:(MFDocumentAutoMode)newAutoMode {
    
    if(_currentAutoMode!=newAutoMode) {
        [self setCurrentAutoMode:newAutoMode];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
	
	if(_pageControlUsed) {
		return;
	}
	
	NSInteger position = floor((scrollView.contentOffset.x - _currentSize.width / 2) / _currentSize.width) + 1;
	
	if(position!=_currentPosition) {
		
        _currentPosition = position;
        
        NSUInteger newPage = pageForPosition(position, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
		[self setCurrentPage:newPage];
        
        [self updatePosition:position];
	}	
}

-(void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	
	_pageButtonUsed = NO;
	self.view.userInteractionEnabled = self.savedUserInteractionEnabled;
	
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
	
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	
	_pageControlUsed = NO;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(focusOn) object:nil];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
}


#pragma mark - 
#pragma mark Device rotation management

/*
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {	
	
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
#if FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -willRotateToInterfaceOrientation:duration:",NSStringFromClass([self class]));
#endif
    
	pageControlUsed = YES;
    isRotating = YES;
	
	[operationQueue cancelAllOperations]; // Cancel all pending operation
	
		if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
			
			currentOrientation = ORIENTATION_PORTRAIT;
			
			if(autoMode) {
				[self setCurrentMode:MFDocumentModeSingle];
			}
			
		} else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
			
			currentOrientation = ORIENTATION_LANDSCAPE;
			
			if(autoMode) {
                
                // NSLog(@"auto mode is set to %d",currentAutoMode);
                
                if(currentAutoMode == MFDocumentAutoModeDouble) {
                    
                    if(currentMode != MFDocumentModeDouble) {
                        [self setCurrentMode:MFDocumentModeDouble];
                    }
                    
                } else if(currentAutoMode == MFDocumentAutoModeSingle) {
                    
                    if(currentMode != MFDocumentModeSingle) {
                        [self setCurrentMode:MFDocumentModeSingle];
                    }
                    
                } else if (currentAutoMode == MFDocumentAutoModeOverflow) {
                    
                    if(currentMode != MFDocumentModeOverflow) {
                        [self setCurrentMode:MFDocumentModeOverflow];
                    }
                }
			}
		}	
	
	// Unfocus
//	if([current focused]){
//		[self unfocusFrom:current];
//	}
	
	// Hide the layers.
	[self hideAllLayers];
	[detailView setHidden:YES];
    [detailView isOutOfSight:NO];
}
*/

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self preLayout];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self postLayout];
}

/*
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
#if FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -didRotateFromInterfaceOrientation:",NSStringFromClass([self class]));
#endif
    
	pageControlUsed = YES;
	currentSize = self.view.bounds.size;
    
//	NSLog(@"currentSize is now [%.3f x %.3f]",currentSize.width,currentSize.height);
    
//	[detailView setZoomLevel];
//	[[detailView scrollDetailView]setContentSize:currentSize];
	
	// Recalculate position while keeping page number.
	
    currentNumberOfPositions = [self numberOfPositions];
	currentPosition = positionForPage(currentPage, currentMode, currentLead, currentDirection, maxNumberOfPages);
    
    // Update the page scroll view.
    
	[pagedScrollView setContentSize:sizeForContent(currentNumberOfPositions, currentSize)];
	[pagedScrollView setContentOffset:CGPointMake(currentPosition * currentSize.width,0) animated:NO];

	[self checkAndUpdateLayers:YES];
    [self showAllLayers];
    [detailView invalidateRenderInfo];
    //[detailView isOnSight];
    
//	// Redeploy the calayers
//	CGRect newCurrentFrame = [self frameForLayer:currentPosition];
//	CGRect newNextFrame = [self frameForLayer:currentPosition+1];
//	CGRect newPrevFrame = [self frameForLayer:currentPosition-1];
//	CGRect newFormerFrame = [self frameForLayer:currentPosition+2];
//	
//	[current setPosition:currentPosition];
//	[current updateWithContentOfSize:[NSValue valueWithCGSize:newCurrentFrame.size]];
//	
//	[next setPosition:currentPosition+1];
//	[next updateWithContentOfSize:[NSValue valueWithCGSize:newNextFrame.size]];
//	
//	[previous setPosition:currentPosition-1];
//	[previous updateWithContentOfSize:[NSValue valueWithCGSize:newPrevFrame.size]];
//	
//	[former setPosition:currentPosition+2];
//	[former updateWithContentOfSize:[NSValue valueWithCGSize:newFormerFrame.size]];
//	
//	// Default 0.25, unhide and reposition the layers that have been hidden in willRotate.
//	// Set the frame without animation while hidden to prevent a not so nice.
//	[CATransaction begin];
//	[CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//	[[former layer]setFrame:newFormerFrame];
//	[[next layer]setFrame:newNextFrame];
//	[[current layer]setFrame:newCurrentFrame];
//	[[previous layer]setFrame:newPrevFrame];
//	[CATransaction commit];
//	
//	// Default 0.25, unhide the layers that have been hidden in willRotate.
//	[CATransaction begin]; 
//	[[former layer] setHidden:NO];
//	[[next layer] setHidden:NO];
//	[[current layer]setHidden:NO];
// 	[[previous layer]setHidden:NO];
//	[CATransaction commit];
//	
	// Focus on the current layer
     isRotating = NO;
	[self performSelector:@selector(focusOn) withObject:nil afterDelay:DETAIL_POPIN_DELAY];
    //[detailView setHidden:NO];
}
 */

+(NSUInteger)supportedOrientations:(NSArray *)orientations {
    
    NSUInteger v = 0;
    
    for(NSNumber * number in orientations) {
        v|=[number intValue];
    }
    
    return v;
}

-(BOOL)shouldAutorotate {
    
    return YES;
}

-(void)setSupportedOrientation:(FPKSupportedOrientation)supportedOrientation {
    
    _supportedOrientation = supportedOrientation;
    
    UIInterfaceOrientationMask orientations = 0;
    
    if((supportedOrientation & FPKSupportedOrientationLandscapeLeft) == FPKSupportedOrientationLandscapeLeft) {
        orientations|=UIInterfaceOrientationMaskLandscapeLeft;
    }
    if((supportedOrientation & FPKSupportedOrientationLandscapeRight) == FPKSupportedOrientationLandscapeRight) {
        orientations|=UIInterfaceOrientationMaskLandscapeRight;
    }
    if((supportedOrientation & FPKSupportedOrientationPortrait) == FPKSupportedOrientationPortrait) {
        orientations|=UIInterfaceOrientationMaskPortrait;
    }
    if((supportedOrientation & FPKSupportedOrientationPortraitUpsideDown) == FPKSupportedOrientationPortraitUpsideDown) {
        orientations|=UIInterfaceOrientationMaskPortraitUpsideDown;
    }

    self.supportedOrientations = orientations;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return self.supportedOrientations;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    UIInterfaceOrientationMask requiredMask = UIInterfaceOrientationMaskAll;
    
    switch(interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            requiredMask = UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            requiredMask = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            requiredMask = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            requiredMask = UIInterfaceOrientationMaskLandscapeRight;
            break;
        default:
            requiredMask = UIInterfaceOrientationMaskAll;
    }
    
    return ((self.supportedOrientations & UIInterfaceOrientationMaskPortrait) == UIInterfaceOrientationMaskPortrait);
}

#pragma mark -
#pragma mark Lifecycle

-(void)postprepareSubviews {
	
	// Empty
}

-(void)hideAllLayers:(BOOL)animated
{
//    if(animated)
//    {
//        for(MFDeferredContentLayerWrapper * wrapper in wrappers)
//        {
//            [[wrapper layer]setHidden:YES];
//        }
//    }
//    else
//    {
//        for(MFDeferredContentLayerWrapper * wrapper in wrappers)
//        {
//            [CATransaction begin];
//            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//            [[wrapper layer]setHidden:YES];
//            [CATransaction commit];
//        }
//    }
}

-(void)showAllLayers:(BOOL)animated
{
//    if(animated)
//    {
//        for(MFDeferredContentLayerWrapper * wrapper in wrappers)
//        {
//            [[wrapper layer]setHidden:NO];
//        }
//        
//    }
//    else
//    {
//        for(MFDeferredContentLayerWrapper * wrapper in wrappers)
//        {
//            [CATransaction begin];
//            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
//            [[wrapper layer]setHidden:NO];
//            [CATransaction commit];
//        }
//    }
}

-(void)hideAllLayers {

    [self hideAllLayers:YES];
}

-(void)showAllLayers {
    
    [self showAllLayers:YES];
}


-(void)prepareSubviews {
	

}

-(void)removeSplashScreen {
    
    alreadyShown = YES;
    
	[self.splashImageView setHidden:YES];
    [self.splashImageView setImage:nil];
	//[self.splashImageView removeFromSuperview];
	//self.splashImageView = nil;
	//[self postprepareSubviews];
    self.view.userInteractionEnabled = self.savedUserInteractionEnabled;
}

-(void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
    
#ifdef FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -viewWillDisappear:",NSStringFromClass([self class]));
#endif
    
    //[self.operationCenter cancelAllOperations];
    
    //[detailView isOutOfSight:YES];
    
    [_thumbnailScrollView stop];
}

-(void)viewDidAppear:(BOOL)animated
{
	
    [super viewDidAppear:animated];
    
    isAppearing = NO;
    
#ifdef FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -viewDidAppear:",NSStringFromClass([self class]));
#endif
    
	if(fpk_view_version && (!alreadyShown)) 
    {
		
		//fpk_view_version = 0;
        
		[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(removeSplashScreen) userInfo:nil repeats:NO];
	}
    
    if(self.settings.useNewEngine) 
    {
        [_thumbnailScrollView start];
    }
}

-(void)viewDidUnload {
    
    /** DEPRECATED since iOS 6.0. */
    
    [super viewDidUnload];
    
    self.splashImageView = nil;
    self.pagedScrollView = nil;
    self.pageSlider = nil;
    self.wrappers = nil;
}

-(void)preLayout
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    //[self.operationCenter cancelAllOperations];
    
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        
        _currentOrientation = ORIENTATION_PORTRAIT;
        
        if(_autoMode) {
            [self setCurrentMode:MFDocumentModeSingle];
        }
        
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        
        _currentOrientation = ORIENTATION_LANDSCAPE;
        
        if(_autoMode) {
            
            // NSLog(@"auto mode is set to %d",currentAutoMode);
            
            if(_currentAutoMode == MFDocumentAutoModeDouble) {
                
                if(_currentMode != MFDocumentModeDouble) {
                    [self setCurrentMode:MFDocumentModeDouble];
                }
                
            } else if(_currentAutoMode == MFDocumentAutoModeSingle) {
                
                if(_currentMode != MFDocumentModeSingle) {
                    [self setCurrentMode:MFDocumentModeSingle];
                }
                
            } else if (_currentAutoMode == MFDocumentAutoModeOverflow) {
                
                if(_currentMode != MFDocumentModeOverflow) {
                    [self setCurrentMode:MFDocumentModeOverflow];
                }
            }
        }
    }
    
    // Hide the layers.
    // [self hideAllLayers:NO];
    //[detailView setHidden:YES];
    //[detailView isOutOfSight:NO];
}

-(void)postLayout
{
    _pageControlUsed = YES;
    
    CGSize size = self.view.bounds.size;
    
    if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        _currentSize = self.view.bounds.size;
        
        _currentNumberOfPositions = [self numberOfPositions];
        _currentPosition = positionForPage(_currentPage, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
        
        // Update the page scroll view.
        
        CGSize size = sizeForContent(_currentNumberOfPositions, _currentSize);
        [_pagedScrollView setContentSize:size];
        [_pagedScrollView setContentOffset:CGPointMake(_currentPosition * _currentSize.width,0) animated:NO];
        
        [self checkAndUpdateLayers:YES];
        
    } else {
        
        if(!CGSizeEqualToSize(size, _currentSize)) {
            
            _currentSize = self.view.bounds.size;
            
            _currentNumberOfPositions = [self numberOfPositions];
            _currentPosition = positionForPage(_currentPage, _currentMode, _currentLead, _currentDirection, _maxNumberOfPages);
            
            // Update the page scroll view.
            
            CGSize size = sizeForContent(_currentNumberOfPositions, _currentSize);
            [_pagedScrollView setContentSize:size];
            [_pagedScrollView setContentOffset:CGPointMake(_currentPosition * _currentSize.width,0) animated:NO];
            
            [self checkAndUpdateLayers:YES];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
#ifdef FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -viewWillAppear:",NSStringFromClass([self class]));
#endif
    
//    isAppearing = YES;
//    
//    UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
//    
//    if(UIInterfaceOrientationIsPortrait(interfaceOrientation))
//    {
//            currentOrientation = ORIENTATION_PORTRAIT;
//    }
//    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
//    {
//            currentOrientation = ORIENTATION_LANDSCAPE;
//    }
//    else
//    {
//        interfaceOrientation = [[UIApplication sharedApplication]statusBarOrientation];
//        
//        if(UIInterfaceOrientationIsPortrait(interfaceOrientation))
//        {
//            currentOrientation = ORIENTATION_PORTRAIT;
//        }
//        else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
//        {
//            currentOrientation = ORIENTATION_LANDSCAPE;
//        }
//        else
//        {
//            // Default to portrait.
//            currentOrientation = ORIENTATION_PORTRAIT;
//        }
//    }
//    
//    if(autoMode)
//    {
//        if(currentOrientation == ORIENTATION_PORTRAIT) {
//            
//            [self setCurrentMode:MFDocumentModeSingle];
//        }
//        else if (currentOrientation == ORIENTATION_LANDSCAPE) {
//            
//            if(currentAutoMode == MFDocumentAutoModeDouble) {
//                
//                [self setCurrentMode:MFDocumentModeDouble];
//            }
//            else if (currentAutoMode == MFDocumentAutoModeSingle) {
//                
//                [self setCurrentMode:MFDocumentModeSingle];
//            }
//            else if (currentAutoMode == MFDocumentAutoModeOverflow) {
//                
//                [self setCurrentMode:MFDocumentModeOverflow];
//            }
//        }
//    }
//
//    self.savedUserInteractionEnabled = self.view.userInteractionEnabled;
//    self.view.userInteractionEnabled = NO;
//    
//	currentSize = [[self view]bounds].size;
//	
//    currentNumberOfPositions = [self numberOfPositions];
//	[detailView setFrame:CGRectMake(0, 0, currentSize.width, currentSize.height)];
//	[pagedScrollView setContentSize:sizeForContent(currentNumberOfPositions, currentSize)];
//	
//    
//    if(currentPage == 0) { // First time only.
//        
//        if(startingPage != 0) {
//        
//            [self setCurrentPage:startingPage];
//        
//        } else {
//            
//            [self setCurrentPage:1];
//        }
//        
//    } else {
//
//        // Everything should be already up to date, since is not the first time
//        // viewWillAppear is called.
//        // [self setCurrentPage:currentPage];
//    }
//    
//	NSInteger position = positionForPage(currentPage, currentMode, currentLead, currentDirection, maxNumberOfPages);
//	
//	pageControlUsed = YES;
//	[pagedScrollView setContentOffset:CGPointMake(position * currentSize.width, 0)];
//	
//    currentPosition = position;
//    
//    [self checkAndUpdateLayers:YES];

    self.savedUserInteractionEnabled = self.view.userInteractionEnabled;
    self.view.userInteractionEnabled = NO;
    
    if(fpk_view_version && (!alreadyShown))
    {
        
		CGSize screenSize = self.view.bounds.size;
		
		const void * logo = NULL;
		int logo_len = 0;
	
		float logo_width = 256.0;
		float logo_height = 256.0;
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			logo = fpdfk_splash_512;
			logo_len = fpdfk_splash_512_len;
			logo_width = 512.0;
			logo_height = 512.0;
		} else {
			float scale = 1.0;
			if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
				scale = [[UIScreen mainScreen]scale];
			}
			
			if(scale>1.5) {
			
				logo = fpdfk_splash_512;
				logo_len = fpdfk_splash_512_len;
				logo_width = 256.0;
				logo_height = 256.0;
				
			} else if (scale < 1.5) {
				
				logo = fpdfk_splash_256;
				logo_len = fpdfk_splash_256_len;
				logo_width = 256.0;
				logo_height = 256.0;
			}
		}
		
		UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake((screenSize.width-logo_width)*0.5, (screenSize.height-logo_height)*0.5, logo_width, logo_height)];
		[imageView setContentMode:UIViewContentModeScaleAspectFit];
        [imageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
        
		NSData *data = [[NSData alloc]initWithBytesNoCopy:(void *)logo
                                                   length:logo_len
                                             freeWhenDone:NO];
		UIImage *img = [[UIImage alloc ]initWithData:data];
		[imageView setImage:img];
		self.splashImageView = imageView;
		[self.view addSubview:imageView];
		
		// Cleanup.
		
	}
    else
    {
        self.view.userInteractionEnabled = self.savedUserInteractionEnabled;
    }
	
    /*
    [self performSelector:@selector(focusOn)
               withObject:nil
               afterDelay:DETAIL_POPIN_DELAY];
    */
    [self updateStatusViews];
}

-(NSUInteger)pageAtLocation:(CGPoint)location {
    return [self.current pageAtLocation:location];
}

- (void)viewDidLoad
{
    /* 
     OK, qui crea lo stack di view/layer. Tutto deve essere già stato aggiunto
     alla fine di viewDidLoad. Gli altri metodi spostano/ridimensionano solo
     quello che già c'è 
     */
	
#ifdef FPK_DEBUG_MSG_UIVIEWCONTROLLER
    NSLog(@"%@ -viewDidLoad",NSStringFromClass([self class]));
#endif
    
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
	
    _loads = 0;
	_firstLoad = YES;
	_currentNumberOfPositions = [self numberOfPositions];
	_currentDetailPosition = -1; // Nowhere
    
    // Paged scroll view
	UIScrollView * aScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height)];
    aScrollView.autoresizingMask = UIViewAutoresizingNone|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    aScrollView.translatesAutoresizingMaskIntoConstraints = YES;
    
	[aScrollView setPagingEnabled:YES];
	[aScrollView setContentSize:sizeForContent(_currentNumberOfPositions, _currentSize)];
	[aScrollView setDelegate:self];
	[aScrollView setAlwaysBounceHorizontal:NO];
    
	self.pagedScrollView = aScrollView;
    
    if(self.cacheEncryptionKey && (!_operationsSharedData)) {
        
        FPKOperationsSharedData * data = [[FPKOperationsSharedData alloc]init];
        data.password = self.cacheEncryptionKey;
        data.algorithm = self.encryptionAlgorithm;
        self.operationsSharedData = data;
    }
    
    if(_maxNumberOfPages > 0)
    {
        int pCount = (int)MIN(MAX(1, _previewsCount), _maxNumberOfPages);
        int index;
        
        _fpk_preview_count = pCount; // Number of preview layers
        _fpk_preview_next_bias = _fpk_preview_count/2;
        _fpk_preview_prev_bias = -((_fpk_preview_count-1)/2);
        
        NSMutableArray * array = [NSMutableArray new];
        
        FPKThumbnailCache * thumbnailCache = [FPKThumbnailCache new];
        self.thumbnailCache = thumbnailCache;
        
        FPKPageMetricsCache * cache = [FPKPageMetricsCache new];
        
        for(index = 0; index < pCount; index++) {
            
            FPKPageView * pageView = [[FPKPageView alloc]initWithFrame:bounds];
            pageView.autoresizingMask = UIViewAutoresizingNone|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
            pageView.translatesAutoresizingMaskIntoConstraints = YES;
            
            pageView.position = index;
            pageView.offset = index;
            pageView.metricsCache = cache;
            pageView.thumbnailCache = self.thumbnailCache;
            pageView.document = self.document;
            pageView.delegate = self;
            pageView.overlayViewHelper = self.overlayViewHelper;
            pageView.privateOverlayViewHelper = self.privateOverlayViewHelper;
            pageView.operationCenter = self.operationCenter;
            pageView.drawablesHelper = self.drawablesHelper;
            pageView.thumbnailDataStore = self.thumbnailDataStore;
            pageView.childViewControllersHelper = self.childViewControllersHelper;
            pageView.pageZoomCache = self.pageZoomCache;
            pageView.settings = self.settings;
            
            [aScrollView addSubview:pageView];
            
            [array addObject:pageView];
        }
        
        self.wrappers = array;
    }
    
	[self.view addSubview:aScrollView];
    
    [self prepareToolbarItems];
    [self prepareThumbSlider];
    
    if(_currentPage == 0)
    { // First time only.
        if(_startingPage != 0)
        {
            [self setCurrentPage:_startingPage];
        }
        else
        {
            [self setCurrentPage:1];
        }
    }
}

-(void)thumbnailScrollView:(TVThumbnailScrollView *)scrollView didSelectPage:(NSUInteger)page {
    [self setPage:page];
}

-(void)showThumbnails
{
    if(_toolbar) {
        
    }
    if (_toolbar.frame.origin.y >= self.view.bounds.size.height)
    {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             [_toolbar setFrame:CGRectMake(0, _toolbar.frame.origin.y - _toolbar.frame.size.height, _toolbar.frame.size.width, _toolbar.frame.size.height)];
                         }completion:^(BOOL finished) {
                             
                             if(finished) {
                                 _thumbsViewVisible = YES;
                                 
                                 // If new engine is being used speedup, then start anyway (won't do any
                                 // arm).
                                 
                                 if(self.settings.useNewEngine) {
                                     [_thumbnailScrollView speedup];
                                 }
                                 
                                 [_thumbnailScrollView start];
                             }
                         }];
    }
}

-(void)hideThumbnails {
        
    [UIView animateWithDuration:0.25f animations:^{
        [_toolbar setFrame:CGRectMake(0, _toolbar.frame.origin.y+ _toolbar.frame.size.height, _toolbar.frame.size.width, _toolbar.frame.size.height)];
    }completion:^(BOOL finished) {
        
        if(finished)
        {
            _thumbsViewVisible = NO;
        
            // If new engine is used and background rendering is enabled, just slowdown
            // else stop altogether.
            
            if((self.settings.useNewEngine) && self.backgroundThumbnailRenderingEnabled)
            {
                [_thumbnailScrollView slowdown];
            }
            else
            {
                [_thumbnailScrollView stop];
            }
        }
    }];
}

/* Lazily initiazlie this page slider */
-(UISlider *)pageSlider
{
    if(!_pageSlider)
    {
        UISlider * slider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 33)];
        slider.continuous = YES;
        slider.minimumValue = 1.0;
        slider.maximumValue = [self.document numberOfPages];
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [slider addTarget:self action:@selector(pageSliderCancel:) forControlEvents:UIControlEventTouchUpOutside];
        [slider addTarget:self action:@selector(pageSliderSlided:) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(pageSliderStopped:) forControlEvents:UIControlEventTouchUpInside];
        self.pageSlider = slider;
    }
    return _pageSlider;
}

-(id<FPKThumbnailDataStore>)thumbnailDataStore {
    if(!_thumbnailDataStore) {
        FPKThumbnailFileStore * defaultStore = [FPKThumbnailFileStore new];
        defaultStore.directory = [self thumbsCacheDirectory];
        _thumbnailDataStore = defaultStore;
    }
    return _thumbnailDataStore;
}

-(TVThumbnailScrollView *)thumbnailScrollView
{
    if(!_thumbnailScrollView)
    {
        
        CGRect thumbnailViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.thumbnailHeight);
        
        TVThumbnailScrollView * thumbsScrollView = [[TVThumbnailScrollView alloc]initWithFrame:thumbnailViewFrame];
        thumbsScrollView.sharedData = self.operationsSharedData;
        thumbsScrollView.cache = self.thumbnailCache;
        
        CGFloat thumbHeight = self.thumbnailHeight;
        CGSize thumbnailSize = CGSizeMake((thumbHeight/4)*3, thumbHeight);
        thumbsScrollView.thumbnailSize = thumbnailSize;
        
        [thumbsScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        
        // Setting stuff.
        thumbsScrollView.thumbnailDataStore = [self thumbnailDataStore];
        [thumbsScrollView setDocument:[self document]];
        [thumbsScrollView setPagesCount:[self.document numberOfPages]];
        [thumbsScrollView setDelegate:self];
        
        if(self.currentDirection == MFDocumentDirectionR2L)
        {
            thumbsScrollView.direction = TVThumbnailScrollViewDirectionBacward;
        }
        else if (self.currentDirection == MFDocumentDirectionL2R)
        {
            thumbsScrollView.direction = TVThumbnailScrollViewDirectionForward;
        }
        
        self.thumbnailScrollView = thumbsScrollView;
    }
    
    return _thumbnailScrollView;
}

/**
 * Lazily instantiate a toolbar. You are responsible to add it to the view.
 */
-(UIToolbar *)toolbar {
    
    if(self.useNavigationControllerToolbar)
        return nil;
    
    if(!_toolbar && (_thumbnailSliderEnabled||_pageSliderEnabled)) {
        
        CGFloat preferredHeight = self.toolbarBarButtonItemCustomView.frame.size.height;
        
        UIToolbar * toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, preferredHeight)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        toolbar.autoresizesSubviews = YES;
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        self.toolbar = toolbar;
    }
    return _toolbar;
}

/**
 * Instantiate the items to be returned from UIViewController's toolbarItems.
 */
-(void)prepareToolbarItems
{
    static CGFloat sliderHeight = 33;    // UISlider default height.
 
    CGFloat toolbarPadding = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 20 : 16; // Also used to left- and right-pad the slider.
    
    if(_thumbnailSliderEnabled && _pageSliderEnabled) {
    
        UIView * customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, sliderHeight + self.thumbnailHeight)];
        customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.toolbarBarButtonItemCustomView = customView;
        
        [customView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [customView setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        
        TVThumbnailScrollView * thumbScrollView = self.thumbnailScrollView;
        _thumbnailScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UISlider * slider = self.pageSlider;
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary * metrics = @{@"thumbsHeight":@(self.thumbnailHeight),
                                   @"sliderPadding":@(toolbarPadding)};
        NSDictionary * names = @{@"thumbs":_thumbnailScrollView,@"slider":slider};
        [customView addSubview:thumbScrollView];
        [customView addSubview:slider];
        
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[thumbs]|" options:0 metrics:metrics views:names]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(sliderPadding)-[slider]-(sliderPadding)-|" options:0 metrics:metrics views:names]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[thumbs(thumbsHeight)][slider]|" options:0 metrics:metrics views:names]];
        
        UIBarButtonItem * sliderItem = [[UIBarButtonItem alloc]initWithCustomView:customView];
        
        UIBarButtonItem * leftPaddingItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                         target:nil
                                                                                         action:nil];
        leftPaddingItem.width = -toolbarPadding;
        
        
        UIBarButtonItem * rightPaddingItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                         target:nil
                                                                                         action:nil];
        rightPaddingItem.width = -toolbarPadding;
        
        [self setToolbarItems:@[leftPaddingItem, sliderItem, rightPaddingItem]];
        
        
    } else if (self.isThumbnailSliderEnabled)
    {
        UIView * customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.thumbnailHeight)];
                customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.toolbarBarButtonItemCustomView = customView;
        
        TVThumbnailScrollView * thumbScrollView = self.thumbnailScrollView;
        thumbScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary * views = @{@"thumbs": _thumbnailScrollView};
        NSDictionary * metrics = @{@"height":@(self.thumbnailHeight)};
        [customView addSubview:thumbScrollView];
        
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[thumbs]|" options:0 metrics:metrics views:views]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[thumbs(height)]|" options:0 metrics:metrics views:views]];
        
        UIBarButtonItem * leftFlexItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        leftFlexItem.width = -toolbarPadding;
        UIBarButtonItem * sliderItem = [[UIBarButtonItem alloc]initWithCustomView:customView];
        UIBarButtonItem * rightFlexItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                       target:nil
                                                                                       action:nil];
                rightFlexItem.width = -toolbarPadding;
        
        [self setToolbarItems:@[leftFlexItem, sliderItem, rightFlexItem]];
        
    }
    else if(self.isPageSliderEnabled)
    {
        // Slider
        UISlider * slider = self.pageSlider;
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Label
        UILabel * label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.pageSliderLabel = label;
        
        // Wrapper
        UIView * customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, sliderHeight)];
        customView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [customView addSubview:slider];
        [customView addSubview:label];
        
        self.toolbarBarButtonItemCustomView = customView;
        
        NSDictionary * views = @{@"slider":slider,@"label":label};
        NSDictionary * metrics = @{@"height":@(33),
                                   @"labelWidth":@(60),
                                   @"sliderPadding":@(toolbarPadding),
                                   @"separator":@(8)};
        
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(sliderPadding)-[slider]-(separator)-[label(labelWidth)]-(sliderPadding)-|" options:0 metrics:metrics views:views]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[slider]|" options:0 metrics:metrics views:views]];
        [customView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
        
        UIBarButtonItem * leftFlexItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        leftFlexItem.width = -toolbarPadding;
        UIBarButtonItem * sliderItem = [[UIBarButtonItem alloc]initWithCustomView:customView];
        UIBarButtonItem * rightFlexItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        rightFlexItem.width = -toolbarPadding;
        
        [self setToolbarItems:@[leftFlexItem, sliderItem, rightFlexItem]];
    }
}

+(BOOL)isPad
{
    static BOOL isPad = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    });
    return isPad;
}

-(void)prepareThumbSlider
{
    if(_thumbnailSliderEnabled||_pageSliderEnabled)
    {
        UIToolbar * toolbar = self.toolbar;
        toolbar.items = [self toolbarItems];
        [self.view addSubview:toolbar];
    }
}

-(void)cleanUp
{
	NSLog(@"cleanUp does nothing. You can stop using it :)");
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    NSLog(@"didReceiveMemoryWarning");

    if(!self.isViewLoaded)
    {
        //[self.operationCenter cancelAllOperations];
        
        // Detail and its content
        // [[[detailView tiledView]layer]setContents:nil];
        // self.detailView = nil;
        
        // Then the page scroll view.
        self.pagedScrollView = nil;
        self.splashImageView = nil;
        // self.detailView = nil;
    }
	
    // Release any cached data, images, etc that aren't in use.
	[_document emptyCache];
}

#pragma mark - Unused or legacy methods

-(NSArray *)overlayView:(MFOverlayView *)overlayView overlayViewsForPage:(NSUInteger)page {
    return [NSArray new];
}

-(void)setImageCacheOversize:(CGFloat)oversize {
    
}

-(CGFloat)imageCacheOversize {
    return 0;
}

@end
