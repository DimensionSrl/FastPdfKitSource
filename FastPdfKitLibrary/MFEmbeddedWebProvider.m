//
//  MFEmbeddedWebProvider.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/10/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFEmbeddedWebProvider.h"
#import "MFWebAnnotation.h"

@implementation MFEmbeddedWebProvider

-(CGRect)webFrame {
    return self.rect;
}

-(void)setWebFrame:(CGRect)webFrame {
    self.rect = webFrame;
}

+(MFEmbeddedWebProvider *)providerForAnnotation:(MFWebAnnotation *)annotation {
    
    MFEmbeddedWebProvider * provider = [[MFEmbeddedWebProvider alloc]init];
    provider.pageURL = annotation.url;
    provider.webFrame = annotation.rect;
    
    return provider;
}

-(UIView *)view {
    return self.webView;
}

-(UIWebView *)webView {
    
    if(!_webView) {
        

        UIWebView * aWebView = [[UIWebView alloc]initWithFrame:self.webFrame];
        

        aWebView.scalesPageToFit = YES;
        aWebView.opaque = NO;
        aWebView.backgroundColor = [UIColor clearColor];
        
        for (id subview in aWebView.subviews){
            
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
                ((UIScrollView *)subview).bouncesZoom = NO;
                for(id subsubview in [subview subviews]) {
                    if([[subsubview class] isSubclassOfClass:[UIImageView class]]) {
                        [subsubview setHidden:YES];
                    }
                }
            }
        }
        
        self.initialized = NO;
        
        self.webView = aWebView;
    }
    
    return _webView;
}

-(void)didAddOverlayView:(UIView *)ov pageView:(FPKPageView *)pageView  {
    
    if(ov == _webView) {
    
        NSURLRequest * request = nil;
        
        if(!self.initialized) {
            
            self.initialized = YES;
            
            request = [[NSURLRequest alloc]initWithURL:self.pageURL];
            
            [_webView loadRequest:request];
            
        } else {
            
            [_webView reload];
        }
    }
}

-(void)willRemoveOverlayView:(UIView *)ov  pageView:(FPKPageView *)pageView {
    
    if(ov == _webView) {
        [_webView stopLoading];
    }
}

-(void)dealloc {
    
#if FPK_DEALLOC
    NSLog(@"%@ - dealloc", NSStringFromClass([self class]));
#endif
}


@end
