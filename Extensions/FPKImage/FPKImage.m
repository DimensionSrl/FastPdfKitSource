//
//  FPKImage.m
//  FastPdfKit Extension
//

#import "FPKImage.h"
#import "FPKTransitionImageView.h"

#import "MFDocumentManager.h"

@implementation FPKImage

#pragma mark -
#pragma mark Initialization

// NSLog(@"FPKImage - ");

static NSString const * kParams = @"params";
static NSString const * kResource = @"resource";
static NSString const * kImage = @"image";

-(UIView *)initWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager{
    if (self = [super initWithFrame:frame])
    {
        _rect = frame;
        
        NSString * resource;
        if([manager respondsToSelector:@selector(documentViewController)]){
            resource = [[[manager documentViewController] document] resourceFolder];
        } else {
            resource = [manager performSelector:@selector(resourcePath)];
        }
        
        FPKTransitionImageView *image = [[FPKTransitionImageView alloc] initWithImage:
                                         [UIImage imageWithContentsOfFile:
                                          [NSString stringWithFormat:@"%@/%@",
                                           resource,
                                           params[kParams][kResource]]
                                          ]
                                         ];
        
        //        UIImageView *image = [[UIImageView alloc] initWithImage:
        //                              [UIImage imageWithContentsOfFile:
        //                               [NSString stringWithFormat:@"%@/%@",
        //                                resource,
        //                                params[kParams][kResource]
        //                                ]
        //                               ]
        //                              ];
        
        image.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        image.contentMode = UIViewContentModeScaleAspectFit;
        image.multipleTouchEnabled = YES;
        image.userInteractionEnabled = YES;
        image.autoresizesSubviews = YES;
        image.clipsToBounds = YES;
        image.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        [self addSubview:image];
    }
    return self;
}

+ (NSArray *)acceptedPrefixes {
    return [NSArray arrayWithObjects:kImage, nil];
}

+(BOOL)matchesURI:(NSString *)uri
{
    NSArray * prefixes = self.acceptedPrefixes;
    for(NSString * prefix in prefixes)
    {
        if([uri hasPrefix:prefix])
            return YES;
    }
    return NO;
}

+ (BOOL)respondsToPrefix:(NSString *)prefix
{
    NSArray * prefixes = self.acceptedPrefixes;
    for(NSString * supportedPrefix in prefixes)
    {
        if([prefix caseInsensitiveCompare:supportedPrefix] == 0)
        {
            return YES;
        }
    }
    return NO;
}

- (void)setRect:(CGRect)aRect{
    [self setFrame:aRect];
    _rect = aRect;
}

@end