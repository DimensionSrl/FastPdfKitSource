//
//  FPKAnnotationBuilder.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/15.
//
//

#import "FPKAnnotationBuilder.h"
#import "MFDocumentManager_private.h"
#import "MFWebAnnotation.h"
#import "MFVideoAnnotation.h"
#import "MFAudioAnnotation.h"
#import "FPKConfigAnnotation.h"
#import "MFFPKAnnotation.h"

@implementation FPKAnnotationBuilder

+(BOOL)occurrencesOfDotInPath:(NSString *)path {
    NSUInteger count = 0;
    NSUInteger length = path.length;
    for(NSUInteger index = 0; index < length; index++) {
        if ([path characterAtIndex:index] == '.') {
            count++;
        }
    }
    return count;
}

-(MFWebAnnotation *)remoteWebAnnotationFromURI:(NSString *)uri
                                        params:(NSDictionary *)params
                                          rect:(CGRect)rect
                                         frame:(CGRect)frame
{
    MFWebAnnotation * annotation = [[MFWebAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [MFDocumentManager URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2 * padding, rect.size.height - 2 * padding);
        annotation.rect = paddedRect;
    }
    
    return annotation;
}

-(MFWebAnnotation *)webAnnotationFromURI:(NSString *)uri
                                  params:(NSDictionary *)params
                                    rect:(CGRect)rect
                                   frame:(CGRect)frame
{
    MFWebAnnotation * annotation = [[MFWebAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [self.document URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2 * padding, rect.size.height - 2 * padding);
        annotation.rect = paddedRect;
    }
    
    return annotation;
}

-(MFVideoAnnotation *)videoAnnotationFromURI:(NSString *)uri
                                      params:(NSDictionary *)params
                                        rect:(CGRect)rect
                                       frame:(CGRect)frame
{
    MFVideoAnnotation * annotation = [[MFVideoAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [self.document URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    // Setting inset padding
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2 * padding, rect.size.height - 2 * padding);
        annotation.rect = paddedRect;
    }
    
    annotation.autoplay = params[@"autoplay"];
    annotation.loop = params[@"loop"];
    annotation.controls = params[@"controls"];
    
    return annotation;
}

-(MFVideoAnnotation *)remoteVideoAnnotationFromURI:(NSString *)uri
                                            params:(NSDictionary *)params
                                              rect:(CGRect)rect
                                             frame:(CGRect)frame {
    MFVideoAnnotation * annotation = [[MFVideoAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [MFDocumentManager URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2 * padding, rect.size.height - 2 * padding);
        annotation.rect = paddedRect;
    }
    
    annotation.autoplay = params[@"autoplay"];
    annotation.loop = params[@"loop"];
    annotation.controls = params[@"controls"];
    
    return annotation;
}

-(MFAudioAnnotation*)remoteAudioAnnotationFromURI:(NSString *)uri
                                            params:(NSDictionary *)params
                                              rect:(CGRect)rect
                                             frame:(CGRect)frame {
    
    MFAudioAnnotation * annotation = [[MFAudioAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [MFDocumentManager URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    annotation.showView = [params objectForKey:@"view"];
    annotation.loop = [params objectForKey:@"loop"];
    annotation.autoplay = [params objectForKey:@"autoplay"];
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2*padding, rect.size.height - 2*padding);
        annotation.rect = paddedRect;
    }
    
    return annotation;
}


-(MFAudioAnnotation *)audioAnnotationFromURI:(NSString *)uri
                                            params:(NSDictionary *)params
                                              rect:(CGRect)rect
                                             frame:(CGRect)frame {
    
    MFAudioAnnotation * annotation = [[MFAudioAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [self.document URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    annotation.showView = [params objectForKey:@"view"];
    annotation.loop = [params objectForKey:@"loop"];
    annotation.autoplay = [params objectForKey:@"autoplay"];
    
    if(params[@"padding"]){
        int padding = [params[@"padding"] intValue];
        CGRect paddedRect = CGRectMake(rect.origin.x + padding, rect.origin.y + padding, rect.size.width - 2*padding, rect.size.height - 2*padding);
        annotation.rect = paddedRect;
    }
    
    return annotation;
}

-(FPKConfigAnnotation *)configAnnotationFromURI:(NSString *)uri
                                         params:(NSDictionary *)params
                                           rect:(CGRect)rect
                                          frame:(CGRect)frame {
    
    FPKConfigAnnotation * annotation = [[FPKConfigAnnotation alloc]init];
    annotation.rect = rect;
    annotation.frame = frame;
    annotation.url = [self.document URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    annotation.maxZoomScale = params[@"zoom"];
    annotation.edgeFlipMargin = params[@"sides"];
    return annotation;
}

-(MFFPKAnnotation *)multimediaAnnotationFromURI:(NSString *)uri
                                         params:(NSDictionary *)params
                                           rect:(CGRect)rect
                                          frame:(CGRect)frame {
    NSString * resource = params[@"resource"];
    
    // Mp4 or mov video files.
    if([resource.pathExtension isEqualToString:@"mp4"]||[resource.pathExtension isEqualToString:@"mov"]) {
        
        // Brutally, if the resource begin with http or has more than one dots (one being the extension) it is a remote path
        if([resource hasPrefix:@"http://"]||[FPKAnnotationBuilder occurrencesOfDotInPath:resource] > 1) {
            
            // Remote
            return [self remoteVideoAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else {
            
            // Local
            return [self videoAnnotationFromURI:uri params:params rect:rect frame:frame];
        }
        
    } else if ([resource.pathExtension isEqualToString:@"mp3"]||[resource.pathExtension isEqualToString:@"aac"]) { // MP3 and AAC audio
        
        // Remote resource, either because it begins with an http schema or because it has more than 1 dot in the path...
        if([resource hasPrefix:@"http://"]||[FPKAnnotationBuilder occurrencesOfDotInPath:resource] > 1) {
            
            // Remote
            return [self remoteAudioAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else {
            
            // Local
            return [self audioAnnotationFromURI:uri params:params rect:rect frame:frame];
        }
        
    } else if([[resource pathExtension]isEqualToString:@"html"]) {
        
        if([FPKAnnotationBuilder occurrencesOfDotInPath:resource] > 1) {
            
            // Remote web
            
            return [self remoteWebAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else {
            
            // Local web
            
            return [self webAnnotationFromURI:uri params:params rect:rect frame:frame];
        }
    } else {
        // It is not an html files, but it could still be a link to a remote website
        if([FPKAnnotationBuilder occurrencesOfDotInPath:resource] > 1) {
            
            return [self remoteWebAnnotationFromURI:uri params:params rect:rect frame:frame];
        }
    }
    
    return nil;
}

-(MFFPKAnnotation *)annotationFromURI:(NSString *)uri
                                 rect:(CGRect)rect
                                frame:(CGRect)frame
{
    if([(NSString *)uri length] > 5) {
        
        // Handle the uri
        
        if([self.document.embeddedAnnotationURIHandler isRemoteWebURI:uri]) {   // fpkw
            
            NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
            return [self remoteWebAnnotationFromURI:uri
                                             params:params
                                               rect:rect
                                              frame:frame];
            
        } else if([self.document.embeddedAnnotationURIHandler isWebURI:uri]) { // fpkh
            
            NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
            return [self webAnnotationFromURI:uri
                                       params:params
                                         rect:rect
                                        frame:frame];
            
        } else if([self.document.embeddedAnnotationURIHandler isVideoURI:uri]) { // fpkv
            
            NSDictionary *params = [MFDocumentManager paramsFromURI:(NSString *)uri];
            return [self videoAnnotationFromURI:uri
                                         params:params
                                           rect:rect
                                          frame:frame];
            
        } else if ([self.document.embeddedAnnotationURIHandler isRemoteVideoURI:uri]) { // fpky
            
            NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
            return [self remoteVideoAnnotationFromURI:uri
                                               params:params
                                                 rect:rect
                                                frame:frame];
            
        } else if([self.document.embeddedAnnotationURIHandler isRemoteAudioURI:uri]) {   // fpkb
            
            NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
            return [self remoteAudioAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else if([self.document.embeddedAnnotationURIHandler isAudioURI:uri]) { // fpka, local
            
            NSDictionary *params = [MFDocumentManager paramsFromURI:(NSString *)uri];
            return [self audioAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else if([self.document.embeddedAnnotationURIHandler isConfigURI:uri]) {
            
            NSDictionary *params = [MFDocumentManager paramsFromURI:(NSString *)uri];
            return [self configAnnotationFromURI:uri params:params rect:rect frame:frame];
            
        } else if(_multimediaAnnotationEnabled && [self.document.embeddedAnnotationURIHandler isMultimediaURI:uri]) {
            
            NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
            return [self multimediaAnnotationFromURI:uri
                                              params:params
                                                rect:rect
                                               frame:frame];
        }
    }
    
    return nil;
}

@end

