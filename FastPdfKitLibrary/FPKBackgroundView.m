//
//  FPKBackgroundView.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 26/11/14.
//
//

#import "FPKBackgroundView.h"
#import "MFDeferredPageOperation.h"
#import "PrivateStuff.h"
#import "FPKSharedSettings_Private.h"

@interface FPKBackgroundView() <MFDeferredPageOperationDelegate>

@property (nonatomic, weak) NSOperation * leftOperation;
@property (nonatomic, weak) NSOperation * rightOperation;

@property (nonatomic, strong) FPKPageRenderingData * leftData;
@property (nonatomic, strong) FPKPageRenderingData * rightData;

@end

@implementation FPKBackgroundView

-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    if(self.mode == MFDocumentModeDouble) {
        
        if(self.leftData) {
            
            CGSize parentLayerFrame = self.layer.frame.size;
            CGRect layerFrame;
            
            transformAndBoxForPagesRendering(NULL, NULL, &layerFrame, NULL, parentLayerFrame, self.leftData.data.metrics.cropbox, CGRectZero, self.leftData.data.metrics.angle, 0, _settings.padding, NO);
            
            CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
            
            self.leftView.frame = layerFrame;
            
            if(self.leftData.ui_image!=nil) {
                self.leftView.layer.contents = (id)[self.leftData ui_image].CGImage;
                self.leftData.ui_image = nil;
            }
            
            if(_settings.showShadow) {
                self.leftView.layer.shadowColor = [UIColor blackColor].CGColor;
                self.leftView.layer.shadowOffset = CGSizeMake(MIN(5, _settings.padding), 5);
                self.leftView.layer.shadowOpacity = 0.25;
                self.leftView.layer.shadowPath = shadowPath;
            }
            
        } else {
            
            self.leftView.layer.contents = (id)nil;
            self.leftView.frame = CGRectZero;
            self.leftView.layer.shadowPath = NULL;
        }
        
        if(self.rightData) {
            
            // FPKSharedSettings * settings = [self.delegate sharedSettingsForBackgroundView:self];
            
            CGSize parentLayerFrame = self.layer.frame.size;
            CGRect layerFrame;
            
            transformAndBoxForPagesRendering(NULL, NULL, NULL, &layerFrame, parentLayerFrame, CGRectZero, self.rightData.data.metrics.cropbox, 0, self.rightData.data.metrics.angle, _settings.padding, NO);
            
            CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
            
            self.rightView.frame = layerFrame;
            
            if(self.rightData.ui_image!=nil) {
                self.rightView.layer.contents = (id)[self.rightData ui_image].CGImage;
                self.rightData.ui_image = nil;
            }
            
            if(_settings.showShadow) {
                
                self.rightView.layer.shadowColor = [UIColor blackColor].CGColor;
                self.rightView.layer.shadowOffset = CGSizeMake(MIN(5, _settings.padding), 5);
                self.rightView.layer.shadowOpacity = 0.25;
                self.rightView.layer.shadowPath = shadowPath;
            }
            
            
            
        } else {
            
            self.rightView.layer.contents = (id)nil;
            self.rightView.frame = CGRectZero;
            self.rightView.layer.shadowPath = NULL;
        }
        
    } else if (self.mode == MFDocumentModeSingle||self.mode == MFDocumentModeOverflow) {
        
        if(self.leftData) {
            
            CGSize parentLayerFrame = self.layer.frame.size;
            CGRect layerFrame;
            
            transformAndBoxForPageRendering(NULL, &layerFrame, parentLayerFrame, self.leftData.data.metrics.cropbox, self.leftData.data.metrics.angle, _settings.padding, NO);
            
            CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, layerFrame.size.width, layerFrame.size.height)]CGPath];
            
            self.leftView.frame = layerFrame;
            if(self.leftData.ui_image!=nil) {
                self.leftView.layer.contents = (id)[self.leftData ui_image].CGImage;
                self.leftData.ui_image = nil;
            }
            
            if(_settings.showShadow) {
                self.leftView.layer.shadowColor = [UIColor blackColor].CGColor;
                self.leftView.layer.shadowOffset = CGSizeMake(MIN(5, _settings.padding), 5);
                self.leftView.layer.shadowOpacity = 0.25;
                self.leftView.layer.shadowPath = shadowPath;
            }
            
        } else {

            self.leftView.layer.contents = (id)nil;
            self.leftView.frame = CGRectZero;
            self.leftView.layer.shadowPath = NULL;
        }
        
        self.rightView.layer.contents = (id)nil;
        self.rightView.frame = CGRectZero;
        self.rightView.layer.shadowPath = NULL;
    }
}

-(void)pageOperation:(MFDeferredPageOperation *)operation didCompleteWithData:(FPKPageRenderingData *)data
{
    if(data.data.page == self.leftPage) {
        
        self.leftData = data;
        [self setNeedsLayout];
        
    } else if (data.data.page == self.rightPage) {
        
        self.rightData = data;
        [self setNeedsLayout];
    }
}

-(void)setMode:(MFDocumentMode)mode {
    if(_mode!=mode) {
        _mode = mode;
        [self setNeedsLayout];
    }
}

-(NSOperation *)enqueueOperationsWithPage:(NSUInteger)page {
    
    MFDeferredPageOperation * pageOperation = [MFDeferredPageOperation operationWithPage:page
                                                                                document:[self.delegate documentForBackgroundView:self] delegate:self];
    
    pageOperation.document = [self.delegate documentForBackgroundView:self];
    pageOperation.sharedData = [self.delegate sharedDataForBackgroundView:self];
    pageOperation.settings = _settings;
    pageOperation.imagesCacheDirectory = [self.delegate imagesDirectoryForBackgroundView:self];
    pageOperation.thumbsCacheDirectory = [self.delegate thumbnailsDirectoryForBackgroundView:self];
    pageOperation.cache = self.cache;
    pageOperation.thumbnailDataStore = self.thumbnailDataStore;
    
    [self.operationCenter.operationQueueA addOperation:pageOperation];

    return pageOperation;
}

-(void)setLeftPage:(NSUInteger)leftPage {
    if(_leftPage != leftPage) {
        _leftPage = leftPage;
        
        [self.leftOperation cancel];

        self.leftData = nil;
        
        [self setNeedsLayout];
        
        if(_leftPage > 0) {
            self.leftOperation = [self enqueueOperationsWithPage:_leftPage];
        }
    }
}

-(void)setRightPage:(NSUInteger)rightPage {
    if(_rightPage != rightPage) {
        _rightPage = rightPage;
        
        [self.rightOperation cancel];
        
        self.rightData = nil;
        
        [self setNeedsLayout];
        
        if(_rightPage > 0) {
            self.rightOperation = [self enqueueOperationsWithPage:_rightPage];
        }
    }
}

#pragma mark - UIView

-(void)dealloc {
    
    [self.leftOperation cancel];
    [self.rightOperation cancel];
}

-(instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if(self) {
        
        // Left view
        UIView * leftView = [[UIView alloc]initWithFrame:CGRectZero];
        self.leftView = leftView;
        [self addSubview:leftView];

        // Right view
        UIView * rightView = [[UIView alloc]initWithFrame:CGRectZero];
        self.rightView = rightView;
        [self addSubview:rightView];
    }
    
    return self;
}

@end
