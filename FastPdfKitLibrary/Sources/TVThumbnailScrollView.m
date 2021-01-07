//
//  TVThumbnailView.m
//  ThumbnailView
//
//  Created by Nicolò Tosi on 10/14/11.
//  Copyright (c) 2011 MobFarm S.a.s.. All rights reserved.
//

#import "TVThumbnailScrollView.h"

@interface FPKThumbnailViewHelper : NSObject
@property (nonatomic, readwrite) NSInteger position;
@property (nonatomic, weak) TVThumbnailView * thumbnailView;
@end

@implementation FPKThumbnailViewHelper

-(void)setPosition:(NSInteger)position {
    if(position!=_position) {
        
    }
}

@end

@interface TVThumbnailScrollView()

@property (nonatomic,strong) NSDictionary * pendingRequests;
@property (nonatomic,strong) UIScrollView * scrollView;
@property (nonatomic,strong) NSArray * thumbnailViews;
@property (nonatomic,strong) UIView * scrollContainerView;

@property (readwrite) NSInteger startingPosition;
@property (nonatomic, readwrite) NSInteger offset;
@property (readwrite) NSInteger currentPosition;

-(NSUInteger)pageForPosition:(NSInteger)position;
-(NSInteger)positionForPage:(NSUInteger)page;

-(void)checkForThumbnail;
-(NSString *)thumbnailTextForPosition:(NSUInteger)position;

@end

@implementation TVThumbnailScrollView

@synthesize thumbnailViews;
@synthesize thumbnailSize, padding;
@synthesize pagesCount;
@synthesize pendingRequests;
@synthesize startingPosition, offset, currentPosition;
@synthesize scrollContainerView;
@synthesize delegate;
@synthesize document;
@synthesize sharedData;
@synthesize orientation, direction;

NSString * kTVThumbnailName = @"key_tv_thumbnail_name";
NSString * kTVThumbnailReadyNotification = @"tv_thumbnail_ready_notification";

-(NSUInteger)pageForPosition:(NSInteger)position {
    
    if(self.direction == TVThumbnailScrollViewDirectionBacward)
    {
        return (pagesCount - position);
    }
    
    return (position + 1);
}

-(NSInteger)positionForPage:(NSUInteger)pageNr {
    
    if(self.direction == TVThumbnailScrollViewDirectionBacward)
    {
        return (pagesCount - pageNr);
    }
    
    return (pageNr - 1);
}

-(void)setDirection:(TVThumbnailScrollViewDirection)newDirection {
    
    if(newDirection!=direction) {
        
        NSUInteger pageForPosition = [self pageForPosition:currentThumbnailPosition];
        direction = newDirection;
        int newPosition = (int)[self positionForPage:pageForPosition];
        currentThumbnailPosition = newPosition;
        [self setNeedsLayout];
    }
}

-(void)setOrientation:(TVThumbnailScrollViewOrientation)newOrientation {
    if(orientation!=newOrientation) {
        orientation = newOrientation;
        [self setNeedsLayout];
    }
}

int nextOffset(int offset) {
    
    if(offset > 0) {
        return offset * (-1);
    } else if (offset < 0) {
        return (offset * (-1))+1;
    } else {
        return 1;
    }
}

-(void)generateThumbnailOrSkip:(id)something {
    
    @autoreleasepool
    {
        
        NSUInteger pageNr = [self pageForPosition:currentPosition];
        
        /* If the file already exist, skip to the next thumbnail. Otherwise, generate
         the thumbnail image, save it to disk at load it into a thumbnail. */
        
        if([self.thumbnailDataStore dataAvailableForPage:pageNr])
        {
            
            TVThumbnailScrollView * __weak this = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [this checkForThumbnail];
            });
        }
        else
        {
            // Thumbnail rendering here.
            
            CGFloat scale = [[UIScreen mainScreen]scale];
            CGImageRef image = [document createImageForThumbnailOfPageNumber:pageNr ofSize:thumbnailSize andScale:scale];
            UIImage * img = [[UIImage alloc]initWithCGImage:image];
            NSData * data = UIImageJPEGRepresentation(img, 0.75);
            CGImageRelease(image);
            
            if(self.sharedData.password)
            {
                NSData * encryptedData = nil;
                
                if(self.sharedData.algorithm == FPKEncryptionAlgorithmAES) {
                    encryptedData = [NSData encryptedDataForData:data
                                                        password:self.sharedData.key
                                                              iv:nil
                                                           error:NULL];
                }
                else if (self.sharedData.algorithm == FPKEncryptionAlgorithmRC4) {
                    encryptedData = [NSData RC4DataForData:data
                                                  password:self.sharedData.key
                                                     error:NULL];
                }
                
                [self.thumbnailDataStore saveData:encryptedData page:pageNr];
                
            }
            else
            {
                
                [self.thumbnailDataStore saveData:data page:pageNr];
            }
            
            TVThumbnailScrollView * __weak this = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [this handleThumbDone:img];
            });
            // [self performSelectorOnMainThread:@selector(handleThumbDone:) withObject:img waitUntilDone:NO];
        }
    }
}

-(void)speedup {
    fast = YES;
}

-(void)slowdown {
    fast = NO;
}
    
-(void)handleThumbDone:(UIImage *)image {
    
    int count = 0;
    TVThumbnailView * view = nil;
    
    if((count = (int)[thumbnailViews count]) != 0) {
    
        view = [thumbnailViews objectAtIndex:currentPosition%count];
        
        if(view.position==currentPosition) {
            view.thumbnailImage = image;
        }
    }
    
    if(fast) {
        TVThumbnailScrollView * __weak this = self;
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            [this checkForThumbnail];
        });
        
    } else {
        TVThumbnailScrollView * __weak this = self;
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            [this checkForThumbnail];
        });
    }
}

-(void)checkForThumbnail {
    
    if(!shouldContinueBackgrounWork) {
        backgroundWorkStillGoingOn = NO;
        return;
    } else {
        backgroundWorkStillGoingOn = YES;
    }
    
    if(startingPosition!=currentThumbnailPosition) {
        
        startingPosition = currentThumbnailPosition;
        offset = 0;
    }
    
    int position = (int)(startingPosition+offset);
    offset = (int)(nextOffset((int)offset));
    int retry = 2;
    while((position < 0 || position >= pagesCount) && retry > 0) {
        position = (int)(startingPosition+offset);
        offset = nextOffset((int)offset);
        retry--;
    }
    
    if(retry > 0) {
        
        self.currentPosition = position;
        
        TVThumbnailScrollView * __weak this = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [this generateThumbnailOrSkip:nil];
        });
        // [self performSelectorInBackground:@selector(generateThumbnailOrSkip:) withObject:nil];
        
    } else {
        
        backgroundWorkStillGoingOn = NO;
    }
}

+(NSNotification *)thumbnailReadyNotification:(NSString *)thumbnail {
    
    NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:thumbnail,kTVThumbnailName, nil];
    
    return [NSNotification notificationWithName:kTVThumbnailReadyNotification object:nil userInfo:info];
}

CGFloat thumbnailOffset(int position, CGFloat thumbWidth, CGFloat padding, CGFloat viewportWidth) {
    
    return ((viewportWidth - thumbWidth) * 0.5) + position * thumbWidth;
}

CGFloat contentWidth (CGFloat thumbWidth, CGFloat padding, int count, CGFloat viewportWidth) {
    
    return  viewportWidth + (count - 1) * thumbWidth;
}

CGFloat contentOffset(int position, CGFloat thumbWidth, CGFloat padding, CGFloat viewportWidth) {
    
    
    return thumbWidth * position;
}

NSUInteger thumbnailPositionForOffset(CGFloat offset, CGFloat thumbWidth, CGFloat padding, CGFloat viewportWidth) {
    
    
    return (offset + (thumbWidth * 0.5)) / thumbWidth;
}

CGFloat rightOffsetForThumbnailPosition(int position, CGFloat thumbWidth, CGFloat padding, CGFloat viewportWidth) {
    
    return thumbWidth * position;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        [self setAutoresizesSubviews:YES];
        
        UIView * aScrollContainerView = [[UIView alloc]initWithCoder:aDecoder];
        [aScrollContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollContainerView setAutoresizesSubviews:YES];
        
        CGRect frame = self.frame;
        
        UIScrollView * aScrollView = [[UIScrollView alloc]initWithFrame:frame];
        [aScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollView setDelegate:self];
        [aScrollView setShowsVerticalScrollIndicator:NO];
        [aScrollView setShowsHorizontalScrollIndicator:NO];
        
        self.scrollView = aScrollView;
        
        currentThumbnailPosition = 0;
        thumbnailSize = CGSizeMake(60, 80);
        padding = 0.0;

        [aScrollContainerView addSubview:aScrollView];
        [self addSubview:aScrollContainerView];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
    
        [self setAutoresizesSubviews:YES];
        
        UIView * aScrollContainerView = [[UIView alloc]initWithFrame:frame];
        [aScrollContainerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollContainerView setAutoresizesSubviews:YES];
        
        UIScrollView * aScrollView = [[UIScrollView alloc]initWithFrame:frame];
        [aScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [aScrollView setDelegate:self];
        [aScrollView setShowsVerticalScrollIndicator:NO];
        [aScrollView setShowsHorizontalScrollIndicator:NO];
        
        self.scrollView = aScrollView;
    
        currentThumbnailPosition = 0;
        thumbnailSize = CGSizeMake(60, 80);
        padding = 0.0;
        
        [aScrollContainerView addSubview:aScrollView];
        [self addSubview:aScrollContainerView];
    }
    
    return self;
}

-(void)setPage:(NSUInteger)pageNr animated:(BOOL)animated {
    
    NSInteger position = [self positionForPage:pageNr];
    CGFloat contentOffset = rightOffsetForThumbnailPosition((int)position, thumbnailSize.width, padding, self.bounds.size.width);
    
    [_scrollView setContentOffset:CGPointMake(contentOffset, 0) animated:animated];
}

-(NSUInteger)page {
    
    return [self pageForPosition:currentThumbnailPosition];
}

-(void)alignToThumbnail {
    
    NSInteger position = thumbnailPositionForOffset(_scrollView.contentOffset.x, thumbnailSize.width, padding, self.bounds.size.width);
    
    CGFloat contentOffset = rightOffsetForThumbnailPosition((int)position, thumbnailSize.width, padding, self.bounds.size.width);
    
    [_scrollView setContentOffset:CGPointMake(contentOffset, 0) animated:YES];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self alignToThumbnail];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if(!decelerate) {
        [self alignToThumbnail];
    }
}


BOOL isViewOutsideRange(int viewPosition, int currentPosition, int count) {
    
    return (abs(viewPosition-currentPosition) > (count/2));
}

-(NSData *)thumbnailView:(TVThumbnailView *)view dataForPage:(NSUInteger)pageNr {
    
    return [self.thumbnailDataStore loadDataForPage:pageNr];
}

-(void)thumbnailViewTapped:(TVThumbnailView *)view position:(NSInteger)position {
    [delegate thumbnailScrollView:self didSelectPage:[self pageForPosition:position]];
}

-(void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    
    int thumbPosition = (int)thumbnailPositionForOffset(_scrollView.contentOffset.x, thumbnailSize.width, padding, self.bounds.size.width);
    
    if(currentThumbnailPosition != thumbPosition) {
     
        currentThumbnailPosition = thumbPosition;
        
        int position;
        int count = (int)[thumbnailViews count];
        int pageNr;
        
        for(TVThumbnailView * view in thumbnailViews) {
            
            position = (int)view.position;
            BOOL done = NO;
            
            while (isViewOutsideRange(position, thumbPosition, count) && (!done)) {
                
                if(position < thumbPosition) {
                    
                    position += count; 
                    
                    if(position >= pagesCount) {
                        position-=count;
                        done = YES;
                    }
                    
                } else if (position > thumbPosition) {
                    
                    position -= count;
                    
                    if(position < 0) {
                        position+=count;
                        done = YES;
                    }
                }
            }
            
            if(view.position!=position) {
             
                view.position = position;

                CGRect frame = view.frame;
                frame.origin.x = thumbnailOffset(position, thumbnailSize.width, padding, self.bounds.size.width);
                view.frame = frame;
                pageNr = (int)[self pageForPosition:position];
                
                view.title = [self thumbnailTextForPosition:position];
                
                [view asynchronouslyLoadImageForPage:pageNr];
            }
        }
    }
}

-(void)setPagesCount:(NSUInteger)newPagesCount {
    
    if(newPagesCount!=pagesCount) {
        pagesCount = newPagesCount;
        [self setNeedsLayout];
    }
}

-(void)setThumbnailSize:(CGSize)newThumbnailSize {
    if(!CGSizeEqualToSize(thumbnailSize, newThumbnailSize)) {
        thumbnailSize = newThumbnailSize;
        [self setNeedsLayout];
    }
}

-(void)setPadding:(CGFloat)newPadding {
    if(padding!=newPadding) {
        padding = newPadding;
        [self setNeedsLayout];
    }
}

int numberOfThumbnails(CGFloat viewportWidth, CGFloat thumbWidth, CGFloat padding) {
    
    int count = ceilf(viewportWidth/(thumbWidth + padding))+1;
    if(count%2 == 0)
        count++;
    return count;
}

-(void)start {
    
    if(backgroundWorkStillGoingOn) {
        return;
    } else {
        shouldContinueBackgrounWork = YES;
        [self checkForThumbnail];
    }
}

-(void)stop {
    
    shouldContinueBackgrounWork = NO;
}

-(NSString *)thumbnailTextForPosition:(NSUInteger)position {
    
    if([delegate respondsToSelector:@selector(thumbnailScrollView:thumbnailTitleForPage:)]) {
        
       return [delegate thumbnailScrollView:self thumbnailTitleForPage:position+1];
       
    } else {
        
        return [NSString stringWithFormat:@"%lu", (unsigned long)[self pageForPosition:position]];
    }
}

-(void)layoutSubviews {
    
    CGRect bounds = self.bounds;
    
    int maxNumberOfThumbnails = numberOfThumbnails(bounds.size.width,thumbnailSize.width,padding);
    
    int newThumbnailCount = maxNumberOfThumbnails < pagesCount ? maxNumberOfThumbnails : (int)pagesCount;
    
    if(newThumbnailCount != thumbnailCount)
    {
        for(UIView * thumbnailView in thumbnailViews)
        {
            [thumbnailView removeFromSuperview];
        }
        
        NSMutableArray * thumbnailArray = [[NSMutableArray alloc]initWithCapacity:newThumbnailCount];
        
        int i;
        for(i = 0; i < newThumbnailCount; i++)
        {
            TVThumbnailView * thumbnailView = [[TVThumbnailView alloc]initWithFrame:CGRectZero]; // Will be layed out later.
            thumbnailView.cache = self.cache;
            thumbnailView.sharedData = self.sharedData;
            thumbnailView.position = i;
            thumbnailView.delegate = self;
            [thumbnailArray addObject:thumbnailView];
            [_scrollView addSubview:thumbnailView];
        }
        
        self.thumbnailViews = thumbnailArray;
    }
    
    thumbnailCount = newThumbnailCount;
    
    for(TVThumbnailView * view in thumbnailViews) {
        
        int position = (int)view.position;
        BOOL done = NO;
        int pageNr;
        while (isViewOutsideRange(position, (int)currentThumbnailPosition, (int)thumbnailCount) && (!done)) {
            
            if(position < currentThumbnailPosition) {
                
                position += thumbnailCount; 
                
                if(position >= pagesCount) {
                    position-=thumbnailCount;
                    done = YES;
                }
                
            } else if (position > currentThumbnailPosition) {
                
                position -= thumbnailCount;
                
                if(position < 0) {
                    position+=thumbnailCount;
                    done = YES;
                }
            }
        }

        CGRect frame = CGRectMake(thumbnailOffset(position, thumbnailSize.width, padding, bounds.size.width), (bounds.size.height - thumbnailSize.height) * 0.5, thumbnailSize.width, thumbnailSize.height);
        view.frame = frame;
        
        pageNr = (int)[self pageForPosition:position];
        view.position = position;
        view.title = [self thumbnailTextForPosition:position];
        [view asynchronouslyLoadImageForPage:pageNr];
    }
    
    _scrollView.contentSize = CGSizeMake(contentWidth(thumbnailSize.width, padding, pagesCount, bounds.size.width), bounds.size.height);
    
    CGFloat contentOffset = rightOffsetForThumbnailPosition((int)currentThumbnailPosition, thumbnailSize.width, padding, bounds.size.width);
    [_scrollView setContentOffset:CGPointMake(contentOffset, 0) animated:NO];
}

-(void)dealloc
{
    shouldContinueBackgrounWork = NO;
    
    _scrollView.delegate = nil;
    
    delegate = nil;

}

@end
