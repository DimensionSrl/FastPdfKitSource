//
//  FastPdfKit Extension
//

#import "FPKConfig.h"

@implementation FPKConfig

#pragma mark -
#pragma mark Initialization

static NSString * const kParams = @"params";
static NSString * const kZoom = @"zoom";
static NSString * const kSides = @"sides";

-(UIView *)initWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager{
    if (self = [super initWithFrame:CGRectZero])
    {        
        _rect = frame;
        
        if([[params objectForKey:kParams] objectForKey:kZoom]){
            NSNumber *pZoom = [NSNumber numberWithFloat:[[[params objectForKey:kParams] objectForKey:kZoom] floatValue]];
            if([manager respondsToSelector:@selector(documentViewController)]){
                [[manager documentViewController] setMaximumZoomScale:pZoom];
            }
        }    
        if([[params objectForKey:kParams] objectForKey:kSides]){
            float pSides = [[[params objectForKey:kParams] objectForKey:kSides] floatValue];
            if([manager respondsToSelector:@selector(documentViewController)]){
                [[manager documentViewController] setEdgeFlipWidth:pSides];
            }
        }
    }
    return self;  
}

+ (NSArray *)acceptedPrefixes
{
    return [NSArray arrayWithObjects:@"config", nil];
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

#pragma mark -
#pragma mark Cleanup

@end