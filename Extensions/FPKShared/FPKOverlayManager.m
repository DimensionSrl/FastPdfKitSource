//
//  FPKOverlayManager.m
//  FPKShared
//

#import "FPKOverlayManager.h"
#import "FPKURIAnnotation.h"
#import "MFDocumentManager.h"
#import "FPKView.h"
#import "Stuff.h"

@implementation FPKOverlayManager

- (FPKOverlayManager *)initWithExtensions:(NSArray *)ext
{
	self = [super init];
	if (self != nil)
    {
        [self setExtensions:ext];
	}
    
	return self;
}

- (void)setExtensions:(NSArray *)ext{
    
    // Set the supported extension list. If the list is different than the
    // previous one clean up the overlays'array and prepare a fresh one.
    
    if(_extensions!=ext)
    {
        _extensions = ext;
        if(!_overlays)
        {
            _overlays = [[NSMutableArray alloc] init];
        }
        else
        {
            [_overlays removeAllObjects];
        }
    }
}

- (void)setScrollLock:(BOOL)lock
{
    [_documentViewController setScrollEnabled:!lock];
    [_documentViewController setGesturesDisabled:lock];
}

-(void)documentViewController:(MFDocumentViewController *)dvc willRemoveOverlayView:(UIView *)view
{
    for(UIView <FPKView> *view in _overlays)
    {
        if([view respondsToSelector:@selector(willRemoveOverlayView:)])
        {
            [view willRemoveOverlayView:self];
        }
    }
}

- (void)documentViewController:(MFDocumentViewController *)dvc didReceiveTapOnAnnotationRect:(CGRect)rect withUri:(NSString *)uri onPage:(NSUInteger)page
{
    /** We are registered as delegate for the documentViewController, so we can 
     receive tap on annotations */
    [self showAnnotationForOverlay:NO withRect:rect andUri:uri onPage:page];
}

-(UIView *)overlayViewWithTag:(NSInteger)tag
{
    return [_documentViewController.view viewWithTag:tag];
}

+(NSDictionary *)paramsForAltURI:(NSString *)uri
{
    NSMutableDictionary * parameters = [NSMutableDictionary new];
    
    NSScanner * scanner = [NSScanner scannerWithString:uri];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    
    if([uri rangeOfString:@"["].location!=NSNotFound)
    {
        NSString * __autoreleasing params = nil;
        [scanner scanUpToString:@"]" intoString:&params];
        
        NSArray * paramsComponents = [params componentsSeparatedByCharactersInSet:[self alternateParametersSeparatorsCharacterSet]];
        if(paramsComponents.count % 2 == 0)
        {
            for(int i = 0; i < paramsComponents.count; i += 2)
            {
                parameters[paramsComponents[i]] = paramsComponents[i+1];
            }
        }
    }
    
    // Resource
    NSString * __autoreleasing resource = nil;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&resource];
    parameters[@"resource"] = resource;
    
    return parameters;
}

+(NSMutableDictionary *)alternateParamsDictionaryWithURI:(NSString *)uri
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSArray *uriComponents = [uri componentsSeparatedByString:@"://"];
    
	if(uriComponents.count > 0)
    {
        NSString *prefix = [uriComponents objectAtIndex:0];
        
        // 1. Prefix
        dic[@"prefix"] = prefix;
        
        if(uriComponents.count > 1)
        {
            NSString * otherThanPrefixString = uriComponents[1];
            
            parameters[@"load"] = @YES; // By default the annotations are loaded at startup
            
            NSScanner * scanner = [NSScanner scannerWithString:otherThanPrefixString];
            scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
            
            NSString * __autoreleasing paramString = nil;
            [scanner scanUpToString:@"]" intoString:&paramString];
            
            NSCharacterSet * parametersSeparators = [FPKOverlayManager alternateParametersSeparatorsCharacterSet];
            NSArray * paramComponents = [paramString componentsSeparatedByCharactersInSet:parametersSeparators];
            
            if(paramComponents.count % 2 == 0)
            {
                for(int i = 0; i < paramComponents.count; i+=2)
                {
                    NSString * paramName = paramComponents[i];
                    NSString * paramValue = paramComponents[i+1];
                    parameters[paramName] = paramValue;
                }
            }
            
            NSString * __autoreleasing path = nil;
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&path];
            dic[@"path"] = path;
            
            NSArray * pathComponents = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?"]];
            
            if(pathComponents.count > 0)
            {
                NSString * resource = pathComponents[0];
                parameters[@"resource"] = resource;
            }
            
            dic[@"params"] = parameters;
        }
    }
    
    return dic;
}

+(NSMutableDictionary *)paramsDictionaryWithURI:(NSString *)uri
{
    /*
     Let's take the following annotation URI
    map://maps.google.com/maps?ll=41.889811,12.492088&spn=0.009073,0.01031&padding=2.0
    as example. */
    if([uri rangeOfString:@"://[" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        return [self alternateParamsDictionaryWithURI:uri];
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    /*
     1. We split the uri in prefix and path. Prefix is going to be 'map' while
     'maps.google.com/maps...' is the path.
     */
    NSArray *uriComponents = [uri componentsSeparatedByString:@"://"];
	if(uriComponents.count > 0)
    {
        /*
         2. Store the 'map' prefix.
        */
        NSString *uriType = uriComponents[0];
        dic[@"prefix"] = uriType;
        if(uriComponents.count > 1)
        {
            
            /* 
             3. Store the whole path, including the parameters. The path might
             include parameter required by the remote service to work. It will
             ignore our custom params.
            */
            
            NSString *path = uriComponents[1];
            dic[@"path"] = path;
            parameters[@"load"] = @YES; // By default the annotations are loaded at startup
            
            /*
             4. Separate the parameters from the resource ('map.google.com/maps').
             Store the resource and then process the parameters.
            */
            
            NSArray * pathComponents = [path componentsSeparatedByString:@"?"];
            if(pathComponents.count > 0)
            {
                parameters[@"resource"] = pathComponents[0];
            }
            
            if(pathComponents.count == 2)
            {
                /*
                 5. Parameters are <name>=<value> pairs separated by commas, so 
                 split the params using '=' and ',' as separators.
                 */
                NSCharacterSet * parametersSeparators = [FPKOverlayManager defaultParametersSeparatorsCharacterSet];
                NSArray * paramComponents = [pathComponents[1] componentsSeparatedByCharactersInSet:parametersSeparators];
                if(paramComponents.count % 2 == 0) // We should get an even number of components.
                {
                    for(int i = 0; i < paramComponents.count; i+=2)
                    {
                        NSString * paramName = paramComponents[i];
                        NSString * paramValue = paramComponents[i+1];
                        parameters[paramName] = paramValue;
                    }
                }
            }
            
            dic[@"params"] = parameters;
        }
    }
    
    return dic;
}

+(NSCharacterSet *)defaultParametersSeparatorsCharacterSet
{
    static NSCharacterSet * set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@"=&"];
    });
    return set;
}

+(NSCharacterSet *)alternateParametersSeparatorsCharacterSet
{
    static NSCharacterSet * set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@":,;"];
    });
    return set;
}

- (UIView *)showAnnotationForOverlay:(BOOL)load
                            withRect:(CGRect)rect
                              andUri:(NSString *)uri
                              onPage:(NSUInteger)page
{
    NSMutableDictionary * dic = [FPKOverlayManager paramsDictionaryWithURI:uri];
    
    dic[@"load"] = @(load);
    
    /**
     Set the supported extensions array when you instantiate your FPKOverlayManager subclass
     [self setExtensions:[[NSArray alloc] initWithObjects:@"FPKYouTube", nil]];
     */
    if(!_extensions)
    {
        [self setExtensions:[NSArray new]];
    }
    
    NSString * uriType = dic[@"prefix"];
    
    NSString *class = nil;
    
    if(_extensions && [_extensions count] > 0)
    {
        for(NSString *extension in _extensions)
        {
            Class classType = NSClassFromString(extension);
            
            if ([classType respondsToPrefix:uriType])
            {
                class = extension;
            }
        }
    }
    
    NSDictionary * parameters = dic[@"params"];
    
    BOOL loadByParam = [parameters[@"load"] boolValue];
    
    CGRect adjustedRect = rect;
    if (parameters[@"padding"])
    {
        CGFloat padding = [parameters[@"padding"] floatValue];
        
        adjustedRect = CGRectIntegral(CGRectInset(rect, padding, padding));
    }
    
    UIView<FPKView> * retVal = nil;
    
    if (class && ((load && loadByParam) || !load))
    {
        UIView<FPKView> *aView = (UIView <FPKView> *)[[NSClassFromString(class) alloc] initWithParams:dic andFrame:adjustedRect from:self];
        retVal = aView;
    }
    else
    {
        NSLog(@"FPKOverlayManager - No Extension found that supports %@", uriType);
    }
    
    return retVal;
}

#pragma -
#pragma FPKOverlayViewDataSource


- (NSArray *)documentViewController:(MFDocumentViewController *)dvc overlayViewsForPage:(NSUInteger)page{
    // NSLog(@"overlayViewsForPage: Method Framework %i", page);
    
    [_overlays removeAllObjects];
    NSArray *annotations = [[_documentViewController document] uriAnnotationsForPageNumber:page];
    
    for (FPKURIAnnotation *ann in annotations) {
        
        UIView *view = [self showAnnotationForOverlay:YES withRect:[ann rect] andUri:[ann uri] onPage:page];
        
        if(view != nil){
            [_overlays addObject:view];
        }
    }
    
    return [NSArray arrayWithArray:_overlays];
}

- (CGRect)documentViewController:(MFDocumentViewController *)dvc rectForOverlayView:(UIView *)view onPage:(NSUInteger)page {
    if([_overlays containsObject:view]) {
        return [(UIView <FPKView> *)view rect];
    }
    return CGRectNull;
}

-(void)setDocumentViewController:(MFDocumentViewController<FPKOverlayManagerDelegate> *)documentViewController {
    if(_documentViewController!=documentViewController) {
        _documentViewController = documentViewController;
        [self setGlobalParametersFromAnnotation];
    }
}

-(void)parseAndApplyModeString:(NSString *)modeParam {
    if([modeParam caseInsensitiveCompare:@"Single"] == NSOrderedSame)
    {
        [_documentViewController setMode:MFDocumentModeSingle];
    }
    else  if([modeParam caseInsensitiveCompare:@"Double"] == NSOrderedSame)
    {
        [_documentViewController setMode:MFDocumentModeDouble];
    }
    else if([modeParam caseInsensitiveCompare:@"Overflow"] == NSOrderedSame)
    {
        [_documentViewController setMode:MFDocumentModeOverflow];
    }
}

/**
 * Global parameters
 * Place it on the first pdf page
 * global://?mode=3&automode=3&zoom=1.0&padding=0&shadow=YES&sides=0.1&status=NO
 */
- (void)setGlobalParametersFromAnnotation
{
    NSString *globalURI = nil;
    NSArray *ann = [[_documentViewController document] uriAnnotationsForPageNumber:1];
    if(ann.count > 0){
        for (FPKURIAnnotation * annotation in ann) {
            if ([annotation.uri hasPrefix:@"settings"]||[annotation.uri hasPrefix:@"global"]){
                globalURI = annotation.uri;
#if DEBUG
                NSLog(@"Global found URI: %@", globalURI);
#endif
                break;
            }
        }    
    }
    
    if(globalURI)
    {
        NSArray * arrayParameter = [globalURI componentsSeparatedByString:@"://"];
        if(arrayParameter.count > 0){

            NSMutableDictionary *parameters = [NSMutableDictionary new];
            
            if(arrayParameter.count > 1){
                
                NSString * uriResource = [NSString stringWithFormat:@"%@", arrayParameter[1]];
                
                NSArray * arrayAfterResource = [uriResource componentsSeparatedByString:@"?"];
                if(arrayAfterResource.count > 0) {
                    parameters[@"resource"] = arrayAfterResource[0];
                }
                if(arrayAfterResource.count == 2) {
                    NSArray * arrayArguments = [arrayAfterResource[1] componentsSeparatedByString:@"&"];
                    for (NSString *param in arrayArguments) {
                        NSArray *keyAndObject = [param componentsSeparatedByString:@"="];
                        if (keyAndObject.count == 2) {
                            id key = keyAndObject[0];
                            parameters[key] = [keyAndObject[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        }
                    }    
                }
            }
            
            // Mode
            NSString * modeParam = parameters[@"mode"];
            if(modeParam)
            {
                int mode = modeParam.integerValue;
                switch(mode) {
                    case 1:
                           [_documentViewController setMode:MFDocumentModeSingle];
                        break;
                    case 2:
                           [_documentViewController setMode:MFDocumentModeDouble];
                        break;
                    case 3:
                        [_documentViewController setMode:MFDocumentModeOverflow];
                        break;
                    default:
                    [self parseAndApplyModeString:modeParam]; // Attemp to use a non int string
                }
            }
            
            // Automode
            NSString * automodeParam = parameters[@"automode"];
            if(automodeParam)
            {
                int mode = 1;
                if([automodeParam isEqualToString:@"None"])
                {
                    mode = 1;
                }
                else if([automodeParam isEqualToString:@"Single"])
                {
                    mode = 2;
                }
                else  if([automodeParam isEqualToString:@"Double"])
                {
                    mode = 3;
                }
                else if([automodeParam isEqualToString:@"Overflow"])
                {
                    mode = 4;
                }
                
                [_documentViewController setAutoMode:mode];
            }
            
            // Zoom
            NSString * zoomParam = parameters[@"zoom"];
            if(zoomParam)
            {
                [_documentViewController setDefaultMaxZoomScale:[zoomParam floatValue]];
            }
            
            // Padding
            if(parameters[@"padding"]) {
                [_documentViewController setPadding:[parameters[@"padding"] intValue]];
            }
          
            // Shadow
            if(parameters[@"shadow"]) {
                [_documentViewController setShowShadow:[parameters[@"padding"] boolValue]];
            }
            
            // Sides
            if(parameters[@"sides"]) {
                [_documentViewController setEdgeFlipWidth:[parameters[@"sides"] floatValue]];
            }
            
            // Status
            if(parameters[@"status"]) {
                [[UIApplication sharedApplication] setStatusBarHidden:![parameters[@"status"] boolValue] withAnimation:UIStatusBarAnimationSlide];
            }
            
            
            if([_documentViewController respondsToSelector:@selector(setSupportedOrientation:)]){
                
                NSMutableArray *orientations = [[NSMutableArray alloc] init];
                
                if(parameters[@"orientation"]) {
                    
                    NSString * valuesSeparatedByCommas = parameters[@"orientation"]; // @"2,3"
                    
                    NSArray * separatedValues = [valuesSeparatedByCommas componentsSeparatedByString:@","];
                    for(NSString * value in separatedValues) {
                        if([value isEqualToString:@"0"]) {
                            [orientations addObject:@(FPKSupportedOrientationPortrait)];
                        } else if ([value isEqualToString:@"1"]) {
                            [orientations addObject:@(FPKSupportedOrientationPortraitUpsideDown)];
                        } else if ([value isEqualToString:@"2"]) {
                            [orientations addObject:@(FPKSupportedOrientationLandscapeRight)];
                        } else if ([value isEqualToString:@"3"]) {
                            [orientations addObject:@(FPKSupportedOrientationLandscapeLeft)];
                        }
                    }
                    
                } else {
                    if(parameters[@"portrait"] && [parameters[@"portrait"] boolValue]) {
                        [orientations addObject:@(FPKSupportedOrientationPortrait)];
                    }
                    
                    if(parameters[@"portraitupsidedown"] && [parameters [@"portraitupsidedown"] boolValue]) {
                        [orientations addObject:@(FPKSupportedOrientationPortraitUpsideDown)];
                    }
                    if(parameters[@"landscaperight"] && [parameters[@"landscaperight"] boolValue]) {
                        [orientations addObject:@(FPKSupportedOrientationLandscapeRight)];
                    }
                    if(parameters[@"landscapeleft"] && [parameters[@"landscapeleft"] boolValue]) {
                        [orientations addObject:@(FPKSupportedOrientationLandscapeLeft)];
                    }
                }
                
                if(orientations.count > 0) {
                    [_documentViewController setSupportedOrientation:[self supportedOrientations:orientations]];
                }
            }
        }
    }
}


-(NSUInteger)supportedOrientations:(NSArray *)orientations
{
    NSUInteger v = 0;
    for(NSNumber * number in orientations) {
        v|=[number intValue];
    }
    return v;
}

@end
