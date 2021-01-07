//
//  MFSliderDetailVIew.m
//  FastPdfKit Sample
//
//  Created by Nicolò Tosi on 7/7/11.
//  Copyright 2011 MobFarm S.a.s.. All rights reserved.
//

#import "TVThumbnailView.h"
#import "FPKImageUtils.h"

@interface TVThumbnailView()
@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic,strong) UIImageView * thumbnailView;
@property (nonatomic,strong) UIActivityIndicatorView * activityIndicator;
@property (nonatomic,strong) UILabel * pageNumberLabel;
@end

@implementation TVThumbnailView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userInteractionEnabled = YES;
        
        UIActivityIndicatorView * anActivityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        anActivityIndicatorView.frame = CGRectMake((frame.size.width - anActivityIndicatorView.frame.size.width) * 0.5, (frame.size.height - anActivityIndicatorView.frame.size.height) * 0.5, anActivityIndicatorView.frame.size.width, anActivityIndicatorView.frame.size.height);
        anActivityIndicatorView.hidesWhenStopped = YES;
        
        [self addSubview:anActivityIndicatorView];
        [anActivityIndicatorView startAnimating];
        
        self.activityIndicator = anActivityIndicatorView;
        
        UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapReceived:)];
        
        [self addGestureRecognizer:recognizer];
    }
    return self;
}

-(void)layoutPageNumberLabel {
    
    // CGRect bounds = self.bounds;
    
    if(self.title) {
        
        if(!self.pageNumberLabel) {
            
            UILabel *aLabel =  [[UILabel alloc ] initWithFrame:CGRectMake(0, self.bounds.size.height - 15, self.bounds.size.width, 15) ];
                aLabel.textAlignment =  NSTextAlignmentCenter;
                aLabel.textColor = [UIColor whiteColor];
                aLabel.backgroundColor = [UIColor clearColor];
                //aLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(20.0)];
            aLabel.font = [UIFont systemFontOfSize:13.0];
            
            self.pageNumberLabel = aLabel;
            [self addSubview:aLabel];
        }
     
        self.pageNumberLabel.text = self.title;
        self.pageNumberLabel.hidden = NO;
        
    } else {
        
        self.pageNumberLabel.hidden = YES;
    }
}

+(CGRect)frameForImageView:(CGSize)size {
    
    return CGRectMake(2, 2, size.width-4, size.height-17);
}

-(void)layoutSubviews {
    
    /*
     If there's an associated image, present it as thumbnail, otherwise show the
     activity indicator. In both case, layout the label since the page number
     is always displayed at the bottom of the view.
     */
    
    CGRect bounds = self.bounds;
    
    if(self.thumbnailImage) {
        
        self.activityIndicator.hidden = YES;
        
        // Calculate the image view frame.
        
        CGRect imageViewFrame = [TVThumbnailView frameForImageView:bounds.size];
        
        if(!self.thumbnailView) { // Prepare the subview if it does not exist yet.
            
            UIImageView * anImageView = [[UIImageView alloc]initWithFrame:imageViewFrame];
            anImageView.backgroundColor = [UIColor clearColor];
            anImageView.userInteractionEnabled = YES;
            [anImageView setContentMode:UIViewContentModeScaleAspectFit];
            
            self.thumbnailView = anImageView;
            
            [self addSubview:anImageView];
            
        }
        
        // Set the image view frame and content, then show it (ignored if already shown).
        
        self.thumbnailView.image = _thumbnailImage;
        self.thumbnailView.frame = imageViewFrame;
        self.thumbnailView.hidden = NO;
        
        [self layoutPageNumberLabel]; // Layout the page number label.
        
    } else {
        
        self.thumbnailView.hidden = YES;
        
        [self layoutPageNumberLabel]; // Layout the page number label.
        
        CGRect spinnerFrame = CGRectMake(bounds.size.width * 0.5 - self.activityIndicator.frame.size.width * 0.5, bounds.size.height * 0.5 - self.activityIndicator.frame.size.height * 0.5, self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
        self.activityIndicator.frame = spinnerFrame;
        [self.activityIndicator startAnimating];
    }
}

-(void)setTitle:(NSString *)newPageNumber {
    
    if(newPageNumber!=_title) {
        
        _title = newPageNumber;
        
        [self setNeedsLayout];
    }
}


-(void)setThumbnailImage:(UIImage *)newThumbnailImage {
    if(_thumbnailImage!=newThumbnailImage) {
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadImage:) object:@(_page)];
        
        _thumbnailImage = newThumbnailImage;
        [self setNeedsLayout];
    }
}

-(void)asynchronouslyLoadImageForPage:(NSUInteger)page {
    if(_page!=page||(_thumbnailImage==nil)) {
        NSNumber * previousPage = @(_page);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadImage:) object:previousPage];
        _page = page;
        self.thumbnailImage = nil;
        NSNumber * newPage = @(_page);
        [self performSelectorInBackground:@selector(loadImage:) withObject:newPage];
    }
}

-(void)loadImage:(NSNumber *)pageNumber {
    
    @autoreleasepool {
        
        NSUInteger page = pageNumber.unsignedIntegerValue;
        
        NSData * data = [self.cache thumbnailDataForPage:page];
        
        if(data) {
            
            /* Cached, uses as is. */
            
            CGImageRef imageRef = [FPKImageUtils newJPEGImageWithData:data];
            
            UIImage * image = [FPKImageUtils newImageWithCGImage2:imageRef];
            
            CGImageRelease(imageRef);
            
            id __weak this = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [this setThumbnailImage: image];
            });
            
        } else {
            
            /* Not cached, attemp to load from the store */
            
            data = [self.delegate thumbnailView:self dataForPage:page];
            
            if(data) {
                
                if(self.sharedData.password) {
                    
                    NSData * decryptedData = nil;
                    
                    if(self.sharedData.algorithm == FPKEncryptionAlgorithmRC4) {
                        decryptedData = [NSData RC4DataForData:data password:self.sharedData.key error:NULL];
                    }
                    else if (self.sharedData.algorithm == FPKEncryptionAlgorithmAES) {
                        decryptedData = [NSData decryptedDataForData:data password:self.sharedData.key iv:nil error:NULL];
                    }
                    
                    CGImageRef imageRef = [FPKImageUtils newJPEGImageWithData:decryptedData];
                    
                    UIImage * image = [FPKImageUtils newImageWithCGImage2:imageRef];
                    CGImageRelease(imageRef);
                    
                    if(image) {
                        
                        [self.cache addThumbnailData:decryptedData page:page];
                        
                        id __weak this = self;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [this setThumbnailImage: image];
                        });
                    } else {
                        /* Handle unavailable image */
                    }
                    
                } else {
                    
                    CGImageRef imageRef = [FPKImageUtils newJPEGImageWithData:data];
                    
                    UIImage * image = [FPKImageUtils newImageWithCGImage2:imageRef];
                    CGImageRelease(imageRef);
                    
                    if(image) {
                        
                        [self.cache addThumbnailData:data page:page];
                        
                        id __weak this = self;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [this setThumbnailImage: image];
                        });
                    }
                }
                
            } else {
                
                /* Unable to load a valid image */
            }
        }
    }
}

-(void)tapReceived:(UITapGestureRecognizer *)gestureRecognizer
{
    [_delegate thumbnailViewTapped:self position:_position];
}

- (void)dealloc
{
    self.delegate = nil;
}

@end
