//
//  FastPdfKit Extension
//

#import "FPKGalleryTap.h"
#import "TransitionImageView.h"
#import "BorderImageView.h"
#import "MFDocumentManager.h"

@interface FPKGalleryTap()

@property (nonatomic, strong) UIGestureRecognizer * gestureRecognizer;
@property (nonatomic,copy) NSDictionary * parameters;
@property (nonatomic,weak) FPKOverlayManager * overlayManager;

-(TransitionImageView *)mainImageWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager;
-(void)changeImageWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager;
@end

@implementation FPKGalleryTap

#pragma mark -
#pragma mark Initialization

// NSLog(@"FPKGalleryTap - ");


static NSString * const kTime = @"time";
static NSString * const kParams = @"params";
static NSString * const kAnimate = @"animate";
static NSString * const kTag = @"id";
static NSString * const kTargetTag = @"target_id";
static NSString * const kColor = @"color";
static NSString * const kColorRed = @"r";
static NSString * const kColorGreen = @"g";
static NSString * const kColorBlue = @"b";
static NSString * const kTargetImage = @"src";
static NSString * const kSelfImage = @"self";
static NSString * const kResource = @"resource";
static NSString * const kAction = @"action";
static NSString * const kPrefix = @"prefix";
static NSString * const kButton = @"button";
static NSString * const kLoad = @"load";

-(UIView *)initWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager
{
    if (self = [super initWithFrame:frame]) {
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        _rect = frame;
        
        // Add Here your Extension code.
        
        CGRect origin = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
        
        NSDictionary * parameters = params[kParams];
        
        // Keep the parameters for later
        self.parameters = params;
        self.overlayManager = manager;
        
        
        NSString * resource = parameters[kResource];
        NSString * prefix = params[kPrefix];
        
        // If resource equals 'button' or the prefix is 'action', we have a button view
        if ([resource caseInsensitiveCompare:kButton] == 0||[prefix caseInsensitiveCompare:kAction]==0)
        {
            if ([params[kLoad] boolValue])
            {
                // Whe should return the image to be rendered
                UIView * subview = [FPKGalleryTap buttonImageWithParams:params
                                                               andFrame:origin
                                                                   from:manager];
                [self addGestureRecognizer:self.gestureRecognizer];

                [self addSubview:subview];
            }
            else
            {
                // Need to check for the main image and change it's content
                [self changeImageWithParams:params andFrame:frame from:manager];
            }
            
        } else {
            // This should be the annotation for the big image
            if ([params[kLoad] boolValue]){
                
                UIView * image = [self mainImageWithParams:params
                                                       andFrame:origin
                                                           from:manager];
                if(image) {
                    [self addSubview:image];
                }
            }
        }
    }
    return self;
}

-(UIGestureRecognizer *)gestureRecognizer {
    if(!_gestureRecognizer) {
        UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeImage:)];
        self.gestureRecognizer = recognizer;
    }
    return _gestureRecognizer;
}

-(void)changeImage:(UIGestureRecognizer *)gr {
    
    [self changeImageWithParams:self.parameters andFrame:CGRectZero from:self.overlayManager];
}

-(TransitionImageView *)mainImageWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager
{
    NSString * resourcePath = nil;
    
    if([manager respondsToSelector:@selector(documentViewController)]){
        resourcePath = [[[manager documentViewController] document] resourceFolder];
    } else {
        resourcePath = [manager performSelector:@selector(resourcePath)];
    }
    
    NSDictionary * parameters = params[kParams];
    
    NSString * resource = parameters[kSelfImage]; // gallerytap://<something>?self=resource.png
    if(!resource) {
        resource = parameters[kResource]; // gallerytap://resource.png
    }
    
    NSString * file = [NSString stringWithFormat:@"%@/%@",
                       resourcePath, 
                       resource];
                       
    UIImage *image = [UIImage imageWithContentsOfFile:file];
    
    if (image) {
        
        TransitionImageView *transitionImageView = [[TransitionImageView alloc] initWithImage:image];
        transitionImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        transitionImageView.contentMode = UIViewContentModeScaleAspectFit;
        transitionImageView.multipleTouchEnabled = YES;
        transitionImageView.userInteractionEnabled = YES;
        transitionImageView.autoresizesSubviews = YES;
        transitionImageView.clipsToBounds = YES;
        
        if(parameters[kTag])
        {
            NSUInteger tag = [parameters[kTag] integerValue];
            transitionImageView.tag = tag;
        }
        
        transitionImageView.frame = frame;
        transitionImageView.backgroundColor = [UIColor clearColor];
        
        return transitionImageView;
    }

    return nil;
}


-(void)changeImageWithParams:(NSDictionary *)params andFrame:(CGRect)frame from:(FPKOverlayManager *)manager{
    
    NSDictionary * parameters = params[kParams];
    if(!parameters) {
        return;
    }
    
    NSString * resource = nil;
    
    if([manager respondsToSelector:@selector(documentViewController)]){
        resource = [[[manager documentViewController] document] resourceFolder];
    } else {
        resource = [manager performSelector:@selector(resourcePath)];
    }
    
    id targetTagValue = parameters[kTargetTag];
    NSInteger targetTag = [targetTagValue integerValue];
    
    // Get the target view
    TransitionImageView *targetView = (TransitionImageView *)[manager overlayViewWithTag:targetTag];
    
    BOOL animating = YES;
    if(parameters[kAnimate])
    {
        animating = [parameters[kAnimate] boolValue];
    }
    
    float time = 1.0;
    if(parameters[kTime])
    {
        time = [parameters[kTime] floatValue];
    }
    
    [targetView setImage:[UIImage imageWithContentsOfFile:
                          [NSString stringWithFormat:@"%@/%@",
                           resource,
                           [parameters objectForKey:kTargetImage]
                           ]
                          ]
 withTransitionAnimation:animating
            withDuration:time];
    
    NSString * colorString = nil;
    
    NSInteger tag = [parameters[@"id"] integerValue];
    BorderImageView * target = (BorderImageView *)[manager overlayViewWithTag:tag];
    
    if(target)
    {
        if((colorString = parameters[kColor])) {
            
            NSArray * arrayColor = [colorString componentsSeparatedByString:@"-"];
            if ([arrayColor count] == 4) {
                UIColor * color = [UIColor colorWithRed:[[arrayColor objectAtIndex:0] floatValue] green:[[arrayColor objectAtIndex:1] floatValue] blue:[[arrayColor objectAtIndex:2] floatValue] alpha:[[arrayColor objectAtIndex:3] floatValue]];
                [target setSelected:YES withColor:color];
            }
            else
            {
                [target setSelected:YES withColor:[UIColor whiteColor]];
            }
            
            
        } else
        {
            id red = parameters[kColorRed];
            id green = parameters[kColorGreen];
            id blue = parameters[kColorBlue];
            
            if(red && green && blue){
                
                UIColor * color = [UIColor colorWithRed:[red floatValue]/255.0
                                                  green:[green floatValue]/255.0
                                                   blue:[blue floatValue]/255.0
                                                  alpha:1.0
                                   ];
                [target setSelected:YES withColor:color];
            } else{
                
                [target setSelected:YES withColor:[UIColor redColor]];
            }
        }
        
        // Removing the border from the other buttons
        
        NSString * othersString = nil;
        if((othersString  = parameters[@"others"]))
        {
            NSArray *tags = [othersString componentsSeparatedByString:@","];;
            if([tags count] > 0){
                for (NSString * tagString in tags) {
                    NSInteger tag = [tagString integerValue];
                    BorderImageView * target = (BorderImageView *)[manager overlayViewWithTag:tag];
                    [target setSelected:NO withColor:[UIColor clearColor]];
                }
            }
        }
    }
}

+(UIView *)buttonImageWithParams:(NSDictionary *)params
                        andFrame:(CGRect)frame
                            from:(FPKOverlayManager *)manager
{
    
    NSString * resourcePath = nil;
    
    if([manager respondsToSelector:@selector(documentViewController)]){
        resourcePath = [[[manager documentViewController] document] resourceFolder];
    } else {
        resourcePath = [manager performSelector:@selector(resourcePath)];
    }
    
    UIView* view = [[UIView alloc] initWithFrame:frame];
    
    [view setBackgroundColor:[UIColor clearColor]];
    
    NSDictionary * parameters = params[@"params"];
    
    NSString * filename = parameters[@"self"];
    
    if(filename)
    {
        
        BorderImageView *inner = [[BorderImageView alloc] initWithFrame:frame];
        
        NSString * file = [NSString stringWithFormat:@"%@/%@",
                           resourcePath,
                           filename];
        
        inner.image = [UIImage imageWithContentsOfFile:file];
        inner.contentMode = UIViewContentModeScaleAspectFill;
        inner.autoresizesSubviews = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        inner.clipsToBounds = YES;
        
        id tagValue = parameters[@"id"];
        if(tagValue)
        {
            NSUInteger tag = [tagValue integerValue];
            inner.tag = tag;
        }
        
        NSString * colorString = parameters[@"color"];
        if(colorString.length > 0)
        {
            NSArray * colorComponents = [colorString componentsSeparatedByString:@"-"];
            if (colorComponents.count == 4)
            {
                float red = [colorComponents[0] floatValue];
                float green = [colorComponents[1] floatValue];
                float blue = [colorComponents[2] floatValue];
                float alpha = [colorComponents[3] floatValue];
                
                UIColor * color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
                [inner setSelected:NO withColor:color];
            }
            else
            {
                [inner setSelected:NO withColor:[UIColor whiteColor]];
            }
        }
        else {
            
            id red = parameters[@"r"];
            id green = parameters[@"g"];
            id blue = parameters[@"b"];
            
            if(red && green && blue)
            {
                UIColor * color = [UIColor colorWithRed:([red floatValue]/255.0)
                                                  green:([green floatValue]/255.0)
                                                   blue:([blue floatValue]/255.0)
                                                  alpha:1.0];
                [inner setSelected:YES withColor:color];
            }
            else
            {
                [inner setSelected:NO withColor:[UIColor whiteColor]];
            }
        }
        
        view.clipsToBounds = YES;
        view.autoresizesSubviews = YES;
        [view addSubview:inner];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    
    return view;
}

+ (NSArray *)acceptedPrefixes
{
    return [NSArray arrayWithObjects:@"gallerytap",@"action",@"image",nil];
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
