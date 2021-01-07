//
//  MFDeferredRenderOperation.m
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/19/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFDeferredRenderOperation.h"
#import "MFOffscreenRenderer.h"
#import "MFDocumentManager.h"
#import "FPKPageRenderingData.h"

@implementation MFDeferredRenderOperation

@synthesize delegate;
@synthesize size;
@synthesize number;
@synthesize leftNumber, rightNumber;
@synthesize document;
@synthesize mode;
@synthesize legacy;
@synthesize  showShadow, padding;
@synthesize data;

-(NSString *)imageDirectory {
    
    static NSString * dir = nil;
    
    if(!dir) {
        
        MFDocumentManager * doc = [delegate documentForRenderOperation:self];
        
        dir = [[[doc resourceFolder] stringByAppendingPathComponent:@"images"]copy];
        
        NSFileManager * fileManager = [[NSFileManager alloc]init];
        
        if(![fileManager fileExistsAtPath:dir isDirectory:NULL]) {
            [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    
    return dir;
}

+(NSString *)identifierForSize:(CGSize)size left:(NSUInteger)left right:(NSUInteger)right scale:(float)scale {
    
    return [NSString stringWithFormat:@"img_%d_%d_%d_%d_%d.png", (int)size.width, (int)size.height, (int)scale, (int)left, (int)right];

}

-(id)initWithTarget:(id)aTarget leftPage:(NSInteger)leftPageNumber rightPage:(NSInteger)rightPageNumber document:(MFDocumentManager *)aDocument imagSize:(CGSize)aSize operationNumber:(NSNumber *)aName {
		
	if((self = [super init])) {
		
		[self setNumber:aName];
		[self setDelegate:aTarget];
		[self setSize:aSize];
		[self setLeftNumber:leftPageNumber];
		[self setRightNumber:rightPageNumber];
		[self setDocument:aDocument];
		self.mode = MFDeferredRenderModePageSingle;
		self.legacy = NO;
		
	}
	
	return self;
}

-(void)main {
    
    static BOOL checked = NO;
	static CGFloat scale = 1.0;
    
	@autoreleasepool {
    
	if([self isCancelled]||nil == delegate||nil == document) {
#if FPK_DEBUG_OPS
		NSLog(@"Ops cancelled");	
#endif
	
		return;
	}
	
	__unused NSString *returnId = [self.number copy];
		
	CGImageRef img = NULL;
    
    if(!checked) {
    
        __unused BOOL isPad = NO;
        
#ifdef UI_USER_INTERFACE_IDIOM
        isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
        
        if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
            scale = [[UIScreen mainScreen]scale];
            
            // NSLog(@"Scale %.3f", scale);
        }
        
// UNCOMMENT TO HAVE 1.0 preview on iPad retina
//        if(isPad && (fabs(scale - 2.0) < FLT_EPSILON)) {
//            scale = 1.0;
//        }
    }
    
    UIImage * image = nil;
    BOOL save = NO;
    NSFileManager * fileManager = nil;
    
    //fileManager = [[NSFileManager alloc]init];
    
    NSString * path = nil;
    //path = [[self imageDirectory]stringByAppendingPathComponent:[MFDeferredRenderOperation identifierForSize:size left:leftNumber right:rightNumber scale:scale]];
    
    // NSLog(@"Path %@", path);
    
    if([fileManager fileExistsAtPath:path]) {
        
        // NSLog(@"Loading");
        //image = [[UIImage alloc]initWithContentsOfFile:path];
        
        CGDataProviderRef provider = CGDataProviderCreateWithFilename([path cStringUsingEncoding:NSUTF8StringEncoding]);
        img = CGImageCreateWithPNGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
        CGDataProviderRelease(provider);
        
        //image = [[UIImage alloc]initWithCGImage:img];
        
        CGImageRelease(img);
        
    } else {
        
        // Remember that you are responsible for releasing the return CGImage.
        if(self.mode == MFDeferredRenderModePageSingle) {
            img = [document createImageFromPDFPage:self.leftNumber size:self.size andScale:scale useLegacy:self.legacy showShadow:self.showShadow andPadding:padding];
        } else if (self.mode == MFDeferredRenderModePageDouble) {
            img = [document createImageFromPDFPagesLeft:self.leftNumber andRight:self.rightNumber size:self.size andScale:scale useLegacy:self.legacy showShadow:self.showShadow andPadding:self.padding];
        }
        
        //image = [[UIImage alloc]initWithCGImage:img scale:scale orientation:UIImageOrientationUp];
        
        [self.data setImage:img];
        
        CGImageRelease(img);
        
    }
    
    
	if([self isCancelled]) {
#if FPK_DEBUG_OPS
		NSLog(@"Ops cancelled");			
#endif		
		


		return;
	}
	
	//NSDictionary * dataDictionary = [[NSDictionary alloc]initWithObjectsAndKeys:image,@"image",returnId,@"id",nil];

	
	if([self isCancelled]) {
#if FPK_DEBUG_OPS
		NSLog(@"Ops cancelled");	
#endif		

		// [dataDictionary release];

		return;
	}
	
    //[target updateContentWithData:data];
        
        id __weak this = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate renderOperation:this didCompleteWithData:data];
        });
        
    
	// [target performSelectorOnMainThread:@selector(updateContentWithData:) withObject:self.data waitUntilDone:NO];
    
    if(save) {
        
        NSData * imageData = UIImagePNGRepresentation(image);

        if(![imageData writeToFile:path atomically:NO]) {
            NSLog(@"Cannot save %@",path);
        }
    }
	
#if FPK_DEBUG_OPS
	NSLog(@"Ops done");	
#endif
	
	//[dataDictionary release];
    }
}

-(void)dealloc {
	
#if FPK_DEALLOC
		NSLog(@"%@ - dealloc",NSStringFromClass([self class]));
#endif
	
	delegate = nil;
	
}

@end
