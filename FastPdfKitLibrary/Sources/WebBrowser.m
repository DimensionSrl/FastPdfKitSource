//
//  WebBrowser.m
//  FastPdfKit Sample
//
//  Created by Gianluca Orsini on 28/03/11.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "WebBrowser.h"

@implementation WebBrowser

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil link:(NSString *)anUri local:(BOOL)isLocal
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
		self.local = isLocal;
		self.uri = anUri;
    }
    
    return self;
}

- (void)dealloc
{
    self.docViewController = nil;
    
    [_closeButton release];
    [_webView release];
    [_uri release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - UIWebViewDelegate

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView: %p didFailLoadWithError: %@", webView, error.localizedDescription);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad: %p", webView);
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad: %p", webView);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    NSArray * subviews = self.webView.subviews;
    for (id subview in subviews){
        if ([[subview class] isSubclassOfClass: [UIScrollView class]])
            ((UIScrollView *)subview).bounces = NO;
    }
    
	if (_local) {
		
        if([self.uri hasPrefix:@"http"]) {
         
            NSURL * url = [NSURL URLWithString:self.uri];
            [self loadURL:url];
            
        } else {
    
            NSURL * url = [[NSURL alloc] initFileURLWithPath:self.uri];
            [self loadURL:url];
                [url release];
        }
        
	} else {
		
        if([self.uri hasPrefix:@"http"]) {
        
            NSURL * url = [NSURL URLWithString:self.uri];
            [self loadURL:url];
            
        } else {
            
            NSString * fixedString = [@"http://" stringByAppendingString:self.uri];
            NSURL * url = [NSURL URLWithString: fixedString];
            [self loadURL:url];
        }
	}
}

-(void)loadURL:(NSURL *)url {
    
    NSURLRequest * request = [[NSURLRequest alloc ]initWithURL:url];
    if(request) {
        [self.webView loadRequest:request];
    }
    
    [request release];
}

-(IBAction)actionDismiss{
    
	self.docViewController.multimediaVisible = NO;
	[[self parentViewController]dismissViewControllerAnimated:YES completion:nil];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
