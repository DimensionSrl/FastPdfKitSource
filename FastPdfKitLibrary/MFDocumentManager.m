//
//  MFDocumentManager.m
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/20/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFDocumentManager_private.h"
#import "MFPDFOutline.h"
#import "MFOffscreenRenderer.h"
#import "MFURIAnnotation.h"
#import "MFLinkAnnotation.h"
#import <CoreGraphics/CGGeometry.h>
#import "MFPDFUtilities.h"
#import "MFStreamScanner.h"
#import "MFTextItem.h"
#import "MFTextBox.h"
#import "resources_m.h"
#import "MFVideoAnnotation.h"
#import "MFWebAnnotation.h"
#import "MFAudioAnnotation.h"
#import "MFTextStateSmartSearch.h"
#import "MFTextStateSmartExtraction.h"
#import "MFRemoteLinkAnnotation.h"
#import "resources.h"
#import "MFTextStateGlyphData.h"
#import "MFDocumentManager_private.h"
#import "PrivateStuff.h"
#import <pthread.h>
#import "fpktime.h"
#import "FPKBaseEmbeddedAnnotationURIHandler.h"
#import "FPKConfigAnnotation.h"
#import <mach/mach.h>

#define MIN_CONSERVATIVE_MEMORY_USAGE_HINT 104857600
#define DEF_CONSERVATIVE_MEMORY_USAGE 262144000

/*
typedef struct FPKDocumentTicket {

CGPDFDocumentRef * document;
unsigned long int document_lock;

} FPKDocumentTicket;
*/

typedef struct FPKDocumentStruct {
    
    CGPDFDocumentRef document;
    NSUInteger lock;
    NSUInteger clear;
    
} FPKDocumentStruct;

@interface MFDocumentManager() {
 
    pthread_mutex_t _mainLock;      /* Synchronization mutex */
    pthread_cond_t _mainCondition;   /* Waiting queue condition */
    unsigned long int _waitingQueue;    /* Waiting queue size */
    
    FPKDocumentStruct _documents[3];
    
    NSString * password;    /* Document decryption password */
    char * cPassword;
}

+(CGPDFDocumentRef)documentWithProvider:(CGDataProviderRef)prov password:(NSString *)password;
+(CGPDFDocumentRef)documentWithURL:(NSURL *)docUrl password:(NSString *)password;
-(CGPDFDocumentRef)createDocument;

-(CGPDFDocumentRef)lockDocument;
-(void)unlockDocument:(CGPDFDocumentRef)document;
-(NSArray *)ensureAnnotationsLoadedForPageNumber:(NSUInteger)number;

@property (copy, nonatomic) NSString * password;

@property (nonatomic, strong) NSArray * readyPagesMaps;

@end

@implementation MFDocumentManager

@synthesize resourceFolder;
@synthesize fontCacheEnabled;

@synthesize alternateURISchemesEnabled;
@synthesize password;

int fpk_textsearch_version = 1;
int fpk_multimedia_version = 1;
int fpk_bundle_version = 0;
int fpk_registered_version = 0;

#pragma mark - Static

+(CGPDFDocumentRef)newDocumentWithProvider:(CGDataProviderRef)prov pwd:(const char *)password
{
    if(prov) {
        
        CGPDFDocumentRef doc = CGPDFDocumentCreateWithProvider(prov);
        
        if(doc && password && (!CGPDFDocumentIsUnlocked(doc)))
        {
            CGPDFDocumentUnlockWithPassword(doc, password);
        }
        
        return doc;
    }
    
    return NULL;
}

+(CGPDFDocumentRef)documentWithProvider:(CGDataProviderRef)prov password:(NSString *)pass {
    
    const char * pwd = [pass cStringUsingEncoding:NSUTF8StringEncoding];
    
    return [self newDocumentWithProvider:prov pwd:pwd];
}

+(CGPDFDocumentRef)documentWithURL:(NSURL *)docUrl pwd:(const char *)pwd {
    
    if(docUrl) {
        
        CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((CFURLRef)docUrl);
        
        if(doc && pwd && (!CGPDFDocumentIsUnlocked(doc)))
        {
            CGPDFDocumentUnlockWithPassword(doc, pwd);
        }
        
        return doc;
    }
    
    return NULL;
}

+(CGPDFDocumentRef)documentWithURL:(NSURL *)docUrl password:(NSString *)pass {
    
    const char * pwd = [pass cStringUsingEncoding:NSUTF8StringEncoding];
    
    return [self documentWithURL:docUrl pwd:pwd];
}

#pragma mark -

-(NSString *)resourceFolder {
    
    if(!resourceFolder)
    {
        self.resourceFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    }
    
    return resourceFolder;
}

-(CGPDFDocumentRef)createDocument 
{
    if(url)
    {
        return [MFDocumentManager documentWithURL:url
                                              pwd:cPassword];
    }
    else if (provider)
    {
        return [MFDocumentManager newDocumentWithProvider:provider
                                                   pwd:cPassword];
    }
    
    return NULL;
}

-(CGPDFDocumentRef)lockDocument
{
    pthread_mutex_lock(&_mainLock);
    
    while(_documents[0].lock && _documents[1].lock && _documents[2].lock)
    {
        _waitingQueue++;    
        pthread_cond_wait(&_mainCondition, &_mainLock);
        _waitingQueue--;
    }
    
    CGPDFDocumentRef document = NULL;
    
    for(NSUInteger i = 0; i < 3; i++) {
        if(_documents[i].lock)
        {
            continue;
        }
        
            _documents[i].lock++;
            
            if(_documents[i].document==NULL)
            {
                CGPDFDocumentRef doc = [self createDocument];
                _documents[i].document = CGPDFDocumentRetain(doc);
                CGPDFDocumentRelease(doc);
            }
            
            document = _documents[i].document;
            break;
    }
    
    pthread_mutex_unlock(&_mainLock);
    
    return document;
}

vm_size_t guessMemoryUsage() {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        return info.resident_size;
    } else {
        return 0;
    }
}

-(void)setConservativeMemoryUsageHint:(size_t)conservativeMemoryUsageHint {
    if(conservativeMemoryUsageHint!=_conservativeMemoryUsageHint) {
        _conservativeMemoryUsageHint = conservativeMemoryUsageHint >= MIN_CONSERVATIVE_MEMORY_USAGE_HINT ? conservativeMemoryUsageHint : MIN_CONSERVATIVE_MEMORY_USAGE_HINT;
    }
}

-(void)unlockDocument:(CGPDFDocumentRef)document
{
    pthread_mutex_lock(&_mainLock);
    
    vm_size_t memoryUsageLimit = _conservativeMemoryUsageHint;
    
    vm_size_t memoryUsage = 0;
    
    BOOL memoryCheck = self.conservativeMemoryUsage;
    
    if(memoryCheck) {
        memoryUsage = guessMemoryUsage();
    }
    
    for(NSUInteger i = 0; i < 3; i++) {
        
        if(document == _documents[i].document) {
            _documents[i].lock--;
            if(_documents[i].clear || (memoryCheck && memoryUsage > memoryUsageLimit)) {
                _documents[i].clear = 0;
                if(_documents[i].document) {
                    CGPDFDocumentRelease(_documents[i].document), _documents[i].document = NULL;
                }
            }
        }
    }

    if(_waitingQueue > 0) 
        pthread_cond_broadcast(&_mainCondition);
    
    pthread_mutex_unlock(&_mainLock);
}

-(void)clearDocuments {
    
    pthread_mutex_lock(&_mainLock);
    
    for(NSUInteger i = 0; i < 3; i++) {
        if(_documents[i].lock) {
            _documents[i].clear = 1;
        } else {
            if(_documents[i].document) {
            CGPDFDocumentRelease(_documents[i].document), _documents[i].document = NULL;
            }
        }
    }
   
    pthread_mutex_unlock(&_mainLock);
}

+(NSString *)version {
    
    return [NSString stringWithCString:fpk_version encoding:NSUTF8StringEncoding];
}

static inline int checkSignature() {
    return 3;
}

#pragma mark Rendering

-(CGImageRef)createImageWithPage:(NSUInteger)page 
                      pixelScale:(float)scale 
                      imageScale:(NSUInteger)scaling 
                 screenDimension:(CGFloat)dimension 
{    
    return [self.renderer createImageWithPage:page
                              pixelScale:scale 
                              imageScale:scaling 
                         screenDimension:dimension];
}

-(CGImageRef)createImageWithImage:(CGImageRef)imageToBeDrawn  
{
    return [self.renderer createImageWithImage:imageToBeDrawn];
}

-(CGImageRef)createImageFromPDFPage:(NSInteger)page 
                               size:(CGSize)size 
                           andScale:(CGFloat)scale 
                          useLegacy:(BOOL)legacy 
{    
    // Backward compatibility assured.
    return [self.renderer createImageFromPDFPage:page
                                       size:size 
                                   andScale:scale 
                                  useLegacy:legacy 
                                 showShadow:YES 
                                 andPadding:5.0];
}

-(CGImageRef)createImageFromPDFPagesLeft:(NSInteger)leftPage 
                                andRight:(NSInteger)rightPage 
                                    size:(CGSize)size 
                                andScale:(CGFloat)scale 
                               useLegacy:(BOOL)legacy 
{    
    // Backward compatibily.
    return [self.renderer createImageFromPDFPagesLeft:leftPage
                                        andRight:rightPage 
                                            size:size andScale:scale 
                                       useLegacy:legacy showShadow:YES 
                                      andPadding:5.0];
}

-(CGImageRef)createImageFromPDFPagesLeft:(NSInteger)leftPage 
                                andRight:(NSInteger)rightPage 
                                    size:(CGSize)size 
                                andScale:(CGFloat)scale 
                               useLegacy:(BOOL)legacy 
                              showShadow:(BOOL)shadow 
                              andPadding:(CGFloat)padding 
{
	return [self.renderer createImageFromPDFPagesLeft:leftPage
                                        andRight:rightPage 
                                            size:size 
                                        andScale:scale 
                                       useLegacy:legacy 
                                      showShadow:shadow 
                                      andPadding:padding];
}

-(CGImageRef)createImageFromPDFPage:(NSInteger)page 
                               size:(CGSize)size  
                           andScale:(CGFloat)scale 
                          useLegacy:(BOOL)legacy 
                         showShadow:(BOOL)shadow 
                         andPadding:(CGFloat)padding 
{
	return [self.renderer createImageFromPDFPage:page
                                       size:size 
                                   andScale:scale 
                                  useLegacy:legacy 
                                 showShadow:shadow 
                                 andPadding:padding];
}

-(CGImageRef)createImageForThumbnailOfPageNumber:(NSUInteger)pageNr 
                                          ofSize:(CGSize)size 
                                        andScale:(CGFloat)scale 
{
	return [self.renderer createImageForThumbnailOfPageNumber:pageNr
                                                  ofSize:size 
                                                andScale:scale];
}


#pragma mark -
#pragma mark Encryption

// Check if the MFDocumentManager wraps an encrypted document
-(BOOL)isLocked 
{    
    CGPDFDocumentRef doc = [self lockDocument];
    
    BOOL encrypted = CGPDFDocumentIsEncrypted(doc);
    
    [self unlockDocument:doc];
    
    return encrypted;
}

// Try to unlock the CGPDFDocument wrapped by the MFDocumentManager
-(BOOL)tryUnlockWithPassword:(NSString *)aPassword
{
    /* Check if the document is encrypted. If it is not, do nothing and return
     NO. If it is encrypted, check if it is unlocked. If it is, just return YES.
     Otherwise attemp to unlock it with the provided password. If successful,
     save the password and return YES, otherwise return NO.
     */
    
    aPassword = aPassword ? : @""; // Default to empty string if nil.
    
    CGPDFDocumentRef doc = [self lockDocument];
    BOOL result = NO;
    
	if(CGPDFDocumentIsEncrypted(doc))
    {
        
		// If it's unlocked, it's already been opened, just return but do not set the password...
		if(CGPDFDocumentIsUnlocked(doc))
        {
			result = YES;
		} 
		else if(aPassword && (CGPDFDocumentUnlockWithPassword(doc, [aPassword cStringUsingEncoding:NSUTF8StringEncoding]))) {
			
			// Set the attributes that were not accessible prior unlocking.
            
			numberOfPages = CGPDFDocumentGetNumberOfPages(doc);
            
			// Set the password
			if([aPassword compare:self.password] != NSOrderedSame)
            {
                self.password = aPassword;
                if(cPassword)
                    free(cPassword);
                const char * pwd = [aPassword cStringUsingEncoding:NSUTF8StringEncoding];
                cPassword = malloc(strlen(pwd) + 1);
                cPassword = strcpy(cPassword, pwd);
			}
			
			result = YES;
			
		} else {
            
			result = NO;
		}
		
	} else {
		
		result = YES;
	}
    
    [self unlockDocument:doc];
    
    return result;
}


#pragma mark -
#pragma mark Document resources

-(NSMutableArray *)outline {

	NSMutableArray *outline = nil;
	
    CGPDFDocumentRef doc = [self lockDocument];
    
	outline = [MFPDFOutline outlineForDocument:doc];
	
	[self unlockDocument:doc];
	
	return outline;
}

-(NSUInteger)numberOfPages 
{
	return numberOfPages; // It is not going to change, no need to look in the document
}

-(void)drawPageNumber:(NSInteger)pageNumber onContext:(CGContextRef)ctx {
	
    CGPDFDocumentRef doc = [self lockDocument];
    
	CGPDFPageRef page = CGPDFDocumentGetPage(doc, pageNumber);
    if(page) {
        CGContextDrawPDFPage(ctx, page);
    }
    
	[self unlockDocument:doc];
}

-(void)getCropbox:(CGRect *)cropbox
      andRotation:(int *)rotation
    forPageNumber:(NSInteger)pageNumber
       withBuffer:(BOOL)bufferOrNot
{
    FPKPageMetrics * metrics = [self pageMetricsForPage:pageNumber];
    *cropbox = metrics.cropbox;
    *rotation = metrics.angle;
}

-(FPKPageMetrics *)pageMetricsForPage:(NSUInteger)pageNr {
    
    pthread_rwlock_rdlock(&_pageDataLock);
    
    FPKPageMetrics * metrics = _metricsCache[@(pageNr)];
    if(metrics) {
        pthread_rwlock_unlock(&_pageDataLock);
        return metrics;
    }
    
    pthread_rwlock_unlock(&_pageDataLock);
    
    CGPDFDocumentRef doc = [self lockDocument];
    CGPDFPageRef page = CGPDFDocumentGetPage(doc, pageNr);
    CGRect box = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    int angle = CGPDFPageGetRotationAngle(page);
    [self unlockDocument:doc];
    
    pthread_rwlock_wrlock(&_pageDataLock);
    
    metrics = [_metricsFactory metricsWithCropbox:box angle:angle];
    _metricsCache[@(pageNr)] = metrics;
    
    pthread_rwlock_unlock(&_pageDataLock);
    
    return metrics;
}

-(void)getCropbox:(CGRect *)cropbox
      andRotation:(int *)rotation
    forPageNumber:(NSInteger)pageNumber
{
    FPKPageMetrics * metrics = [self pageMetricsForPage:pageNumber];
    *cropbox = metrics.cropbox;
    *rotation = metrics.angle;
}

#pragma mark Video annotation

-(FPKAnnotationBuilder *)annotationBuilder {
    if(!_annotationBuilder) {
        FPKAnnotationBuilder * builder = [FPKAnnotationBuilder new];
        builder.document = self;
        self.annotationBuilder = builder;
    }
    return _annotationBuilder;
}

-(id<FPKEmbeddedAnnotationURIHandler>)embeddedAnnotationURIHandler {
    if(!_embeddedAnnotationURIHandler) {
        FPKBaseEmbeddedAnnotationURIHandler * handler = [FPKBaseEmbeddedAnnotationURIHandler new];
        self.embeddedAnnotationURIHandler = handler;
    }
    return _embeddedAnnotationURIHandler;
}

//+(NSURL *)urlForAltRemoteURI:(NSString *)uri schemeLength:(NSUInteger)length {
//    
//    // Substring from htmlremote:// (13)
//    
//    NSURL * remoteUrl = nil;
//    NSString * remoteUri = nil;
//    
//    remoteUri = [[NSString alloc]initWithFormat:@"http://%@",[uri substringFromIndex:length]];
//    remoteUrl =  [NSURL URLWithString:remoteUri];
//    [remoteUri release];
//    
//    return remoteUrl;
//}

//-(NSURL *)urlForAltLocalURI:(NSString *)uri schemeMaxLength:(NSUInteger)length {
//    
//    // Get the uri by:
//    // - trunkate after the scheme
//    // - trunakte before the first parameter
//    
//    NSURL * localUrl = nil;         // Return value
//    NSString * uriResource = nil;    // Actual local resource path component
//    
//    NSRange schemeOccurrence;
//    
//    if(length > 0) {
//        schemeOccurrence = [uri rangeOfString:@"://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, length)];
//    } else {
//        schemeOccurrence = [uri rangeOfString:@"://" options:NSCaseInsensitiveSearch];
//    }
//    
//    // Remove the prefix
//    
//    if(schemeOccurrence.location != NSNotFound) {
//        
//        uriResource = [uri substringFromIndex:schemeOccurrence.location + schemeOccurrence.length];
//        
//
//        // Remove the paramters, if any
//        
//        NSRange paramOccurrence = [uriResource rangeOfString:@"?"];
//        
//        if(paramOccurrence.location != NSNotFound) {
//            
//            uriResource = [uriResource substringToIndex:paramOccurrence.location];
//        }
//        
//        // Compose the absolute path
//        
//        NSString * localUri = [resourceFolder stringByAppendingPathComponent:uriResource];
//        
//        localUrl = [NSURL fileURLWithPath:localUri];
//    }
//    
//    return localUrl;
//
//}

-(NSURL *)URLForLocalResource:(NSString *)resource
{
    NSString * urlString = [self.resourceFolder stringByAppendingPathComponent:resource];
    return [NSURL fileURLWithPath:urlString];
}

+(NSURL *)URLForRemoteResource:(NSString *)resource
{
    NSString * urlString = [@"http://" stringByAppendingPathComponent:resource];
    return [NSURL URLWithString:urlString];
}

//+(NSURL *)urlForRemoteFpkURI:(NSString *)uri {
//    
//    NSURL * remoteUrl = nil;
//    NSString * remoteUri = nil;
//    
//    remoteUri = [[NSString alloc]initWithFormat:@"http://%@",[uri substringFromIndex:7]];
//    remoteUrl =  [NSURL URLWithString:remoteUri];
//    [remoteUri release];
//    
//    return remoteUrl;
//}

+(BOOL)matchFPKAnnotationString:(NSString *)baseString withMatchString:(NSString *) matchString {
    
    NSUInteger bsLen = [baseString length];
    NSUInteger msLen = [matchString length];
    NSString * substring = nil;
    
    if(bsLen < msLen)
        return NO;
    
    substring = [baseString substringToIndex:msLen];
    
    if([substring isEqualToString:matchString])
        return YES;
    
    return NO;
}

//-(NSURL *)urlForLocalFpkURI:(NSString *)uri {
//    
//    NSFileManager * fileManager = nil;
//    NSURL * localUrl = nil;
//    
//    NSString *uriResource = nil;
//    NSArray *arrayParameter = nil;
//    NSArray *arrayAfterResource = nil;
//    
//    arrayParameter = [uri componentsSeparatedByString:@"://"];
//    
//	if([arrayParameter count] > 0){
//        if([arrayParameter count] > 1){
//            uriResource = [NSString stringWithFormat:@"%@", [arrayParameter objectAtIndex:1]];
//            arrayAfterResource = [uriResource componentsSeparatedByString:@"?"];
//            if([arrayAfterResource count] > 0)
//                uriResource = [NSString stringWithFormat:@"%@", [arrayAfterResource objectAtIndex:0]];
//        }
//    }
//    
//    // NSLog(@"uri resource: %@", uriResource);
//    
//    NSString * localUri = [resourceFolder stringByAppendingPathComponent:uriResource];
//    
//    fileManager = [[NSFileManager alloc]init];
//    
//    if([fileManager fileExistsAtPath:localUri]) {
//
//        localUrl = [NSURL fileURLWithPath:localUri];
//    }
//    
//    [fileManager release];
//    
//    return localUrl;
//}

+(NSCharacterSet *)parametersSeparatorsCharacterSet
{
    static NSCharacterSet * set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [[NSCharacterSet characterSetWithCharactersInString:@"&="]retain];
    });
    return set;
}

+(NSCharacterSet *)altParametersSeparatorsCharacterSet
{
    static NSCharacterSet * set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [[NSCharacterSet characterSetWithCharactersInString:@",:;"]retain];
    });
    return set;
}

+(NSDictionary *)paramsForAltURI:(NSString *)uri
{
    NSMutableDictionary * parameters = [NSMutableDictionary new];
    
    NSScanner * scanner = [NSScanner scannerWithString:uri];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"/[]"];
    [scanner scanUpToString:@"/" intoString:nil];
    
    if([uri rangeOfString:@"["].location!=NSNotFound)
    {
        NSString * __autoreleasing params = nil;
        [scanner scanUpToString:@"]" intoString:&params];
        
        NSArray * paramsComponents = [params componentsSeparatedByCharactersInSet:[self altParametersSeparatorsCharacterSet]];
        if(paramsComponents.count % 2 == 0)
        {
            for(int i = 0; i < paramsComponents.count; i+=2)
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

+(NSDictionary *)paramsFromURI:(NSString *)uri {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSURL * url = [NSURL URLWithString:uri];
    
    
    if([uri rangeOfString:@"://["].location!=NSNotFound)
    {
        return [self paramsForAltURI:uri];
    }
    
    NSString * host = url.host.length > 0 ? url.host : @"";
    NSString * path = url.path.length > 0 ? url.path : @"";
    
    NSString * resource = [host stringByAppendingPathComponent:path];
    parameters[@"resource"] = resource;
    
    NSString * query = url.query;
    
    NSArray * paramsComponents = [query componentsSeparatedByCharactersInSet:[self parametersSeparatorsCharacterSet]];
    if(paramsComponents.count % 2 == 0)
    {
        for(int i = 0; i < paramsComponents.count; i+=2)
        {
            parameters[paramsComponents[i]] = paramsComponents[i+1];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:parameters];
}

-(NSArray *)remoteAudioAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    // Skip remote audio annotation.
    
    return [NSArray new];
}

-(NSArray *)audioAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    NSArray * annotations = [self ensureAnnotationsLoadedForPageNumber:pageNr];
    
    NSMutableArray * tmp = [NSMutableArray array];
    
    for(id annotation in annotations) {
        if([annotation isKindOfClass:[MFAudioAnnotation class]])
            [tmp addObject:annotation];
    }
    
    return [NSArray arrayWithArray:tmp];
    
}

+(MFWebAnnotation *)altRemoteWebAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {

    MFWebAnnotation * annotation = [[MFWebAnnotation alloc]init];
    annotation.rect = rect;
    
    NSDictionary * params = [self paramsFromURI:uri];

    annotation.url = [self URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    return [annotation autorelease];
}

-(MFWebAnnotation *)altWebAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {
    
    MFWebAnnotation * annotation = [[MFWebAnnotation alloc]init];
    annotation.rect = rect;
    
    NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
    
    annotation.url = [self URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    return [annotation autorelease];
}

-(MFVideoAnnotation *)altVideoAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {
    
    MFVideoAnnotation * annotation = [[MFVideoAnnotation alloc]init];
    annotation.rect = rect;
    
    NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
    
    annotation.url = [self URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    CGRect paddedRect;
    
    if([params objectForKey:@"padding"]){
        int padding = [[params objectForKey:@"padding"] intValue];
        paddedRect = CGRectInset(annotation.rect, padding, padding);
        annotation.rect = paddedRect;
    }
    
    annotation.autoplay = params[@"autoplay"];
    annotation.loop = params[@"loop"];
    annotation.controls = params[@"controls"];
    
    return [annotation autorelease];
}

+(MFVideoAnnotation *)altRemoteVideoAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {
    
    MFVideoAnnotation * annotation = [[MFVideoAnnotation alloc]init];

    NSDictionary *params = [MFDocumentManager paramsFromURI:(NSString *)uri];
   
    annotation.rect = rect;
    annotation.url = [self URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;                            
    
    NSNumber * paddingValue;
    if((paddingValue = [params objectForKey:@"padding"])) {
        
        int padding = [paddingValue intValue];
        
        annotation.rect = CGRectInset(rect, padding, padding);
    }
    
    annotation.autoplay = params[@"autoplay"];
    annotation.loop = params[@"loop"];
    annotation.controls = params[@"controls"];
    
    return [annotation autorelease];
}

+(MFAudioAnnotation *)altRemoteAudioAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {
    
    MFAudioAnnotation * annotation = [[MFAudioAnnotation alloc]init];
    annotation.rect = rect;
    
    NSDictionary *params = [MFDocumentManager paramsFromURI:(NSString *)uri];
    
    annotation.url = [self URLForRemoteResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    annotation.showView = params[@"view"];
    
    return [annotation autorelease];
}

-(MFAudioAnnotation *)altAudioAnnotationWithURI:(NSString *)uri rect:(CGRect)rect context:(id)ctx {
    
    MFAudioAnnotation * annotation = [[MFAudioAnnotation alloc]init];
    annotation.rect = rect;
    
    NSDictionary * params = [MFDocumentManager paramsFromURI:uri];
    
    annotation.url = [self URLForLocalResource:params[@"resource"]];
    annotation.originalUri = (NSString *)uri;
    
    annotation.showView = params[@"view"];

    return [annotation autorelease];
}

-(NSDictionary *)cocoaAnnotationsForPage:(NSUInteger)pageNr {
    
    CGPDFDictionaryRef pageDictionary = NULL;
    CGPDFDocumentRef doc = NULL;
    CGPDFPageRef page = NULL;
    CGPDFObjectRef annotsObject = NULL;
    NSDictionary *annotations = nil;
    
    doc = [self lockDocument];
    
	page = CGPDFDocumentGetPage(doc, pageNr);
	pageDictionary = CGPDFPageGetDictionary(page);
    
    if(CGPDFDictionaryGetObject(pageDictionary, "Annots", &annotsObject)) {
        
        MFPDFObjectParser * parser = [[MFPDFObjectParser parser]retain];
    
        annotations = [parser parse:annotsObject];
        
        [parser release];
    }
    
    [self unlockDocument:doc];

    return annotations;
}

+(CGRect)rectFromCGPDFArray:(CGPDFArrayRef)array {
    
    CGPDFReal llx, lly, urx, ury;
    llx = lly = urx = ury = 0.0f;
    
    CGRect rect = CGRectNull;
    
	CGPDFArrayGetNumber(array, 0, &llx);
	CGPDFArrayGetNumber(array, 1, &lly);
	CGPDFArrayGetNumber(array, 2, &urx);
	CGPDFArrayGetNumber(array, 3, &ury);
    
    rect = CGRectStandardize(CGRectMake(llx, lly, (urx-llx), (ury-lly)));
    
    return rect;
}

-(NSArray *)allSupportedAnnotationsForPageNumber:(NSUInteger)pageNr {
    
#if DEBUG
	NSLog(@"%@ -linkAnnotationsForPageNumber: %lu",NSStringFromClass([self class]), (unsigned long) pageNr);
#endif
    
    NSInteger annotationsCount = [self.annotationsCache annotationsCountForPage:pageNr];
    
    if((annotationsCount != NSNotFound) && (annotationsCount == 0)) {
    
        return [FPKAnnotationsCache emptyAnnotations];
    }
    
    NSMutableArray *annotations = [[NSMutableArray alloc]init];

	CGPDFArrayRef annots = NULL;
	CGPDFDictionaryRef annotationDictionary = NULL;
	size_t count,i;                             // Number of annotation and loop index.
    
    CGPDFObjectRef annotsObject = NULL;
    
    CGPDFDocumentRef doc = [self lockDocument];
    
#if DEBUG
    NSLog(@"allSupportedAnnotationsForPageNumber:");
#endif
    
	CGPDFPageRef page = CGPDFDocumentGetPage(doc, pageNr);
	CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
    
    CGRect box = CGPDFPageGetBoxRect(page, kCGPDFCropBox); // Used to reverse the rect
    CGFloat pageHeight = box.size.height;
    
    if(CGPDFDictionaryGetObject(pageDictionary, "Annots", &annotsObject)) {
        
        if((CGPDFObjectGetType(annotsObject) == kCGPDFObjectTypeArray) && CGPDFObjectGetValue(annotsObject, kCGPDFObjectTypeArray, &annots)) {
            
                count = CGPDFArrayGetCount(annots);
                
                for(i = 0; i < count; i++) {
                    
                    const char *subtype = NULL;         // Required.
                    NSUInteger pageNumber = 0;
                    CGPDFArrayRef rectangle = NULL;     // Required.
                    CGRect rect = CGRectZero;
                    CGRect frame = CGRectZero;
                    CGPDFObjectRef destination = NULL;  // Mutal exclusive with the following action;
                    CGPDFDictionaryRef action = NULL;
                    
                    if(CGPDFArrayGetDictionary(annots, i, &annotationDictionary)) { // It could also be Null!
                        
                        CGPDFDictionaryGetName(annotationDictionary, "Subtype", &subtype);
                        
                        if((strcmp(subtype, "Link") == 0)||(strcmp(subtype, "Widget"))==0) { // Widget check here.
                            
                            // Rectangle, always present
                            if(CGPDFDictionaryGetArray(annotationDictionary, "Rect", &rectangle)) {
                                CGRect annotationRect = [MFDocumentManager rectFromCGPDFArray:rectangle];
                                frame = FPKReversedAnnotationRect(annotationRect, pageHeight);
                                rect = annotationRect;
                            }
                            
                            // The destination is either an action, as A, or a destinations as Dest
                            
                            if (CGPDFDictionaryGetDictionary(annotationDictionary, "A", &action)) {
                                
                                const char * actionName = NULL; // Must be "GoTo" for internal destination.
                                CGPDFDictionaryGetName(action, "S", &actionName);
                                
                                if(actionName==NULL) {
                                    
                                    continue;
                                    
                                } else if (strcmp(actionName, "GoTo")==0) {
                                    
                                    if(CGPDFDictionaryGetObject(action, "D", &destination)) {
                                        pageNumber = pageNumberForDestination(doc, destination);
                                    }
                                    
                                    // Something has gone wrong, lets skip it.
                                    if(pageNumber==0)
                                        continue;
                                    
                                    MFLinkAnnotation *annotation = [[MFLinkAnnotation alloc]init];
                                    annotation.destinationPage = pageNumber;
                                    annotation.rect = rect;
                                    annotation.frame = frame;
                                    [annotations addObject:annotation];
                                    [annotation release],annotation = nil;
                                    
                                }
                                else if (strcmp(actionName, "URI") == 0)
                                {
                                    
                                    CGPDFStringRef uriString = NULL;
                                    CFStringRef escapedURI = NULL;
                                    CGPDFBoolean mapBoolean;
                                    BOOL isMap = NO;
                                    // NSString * prefix = nil;
                                    
                                    // Map boolean.
                                    if(CGPDFDictionaryGetBoolean(action, "IsMap", &mapBoolean)) {
                                        isMap = mapBoolean;
                                    }
                                    
                                    // Uri.
                                    if(CGPDFDictionaryGetString(action, "URI", &uriString)) {
                                        escapedURI = CGPDFStringCopyTextString(uriString);
                                    }
                                    
                                    NSString * uri = [(NSString *)escapedURI stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                    if(escapedURI)
                                        CFRelease(escapedURI);
                                    
                                    // Attempt to parse a multimedia annotation.
                                    MFFPKAnnotation * multimediaAnnotation = [self.annotationBuilder annotationFromURI:uri rect:rect frame:frame];
                                    if(multimediaAnnotation != nil) {
                                        [annotations addObject:multimediaAnnotation];
                                    }
                                    
                                        // Add an uri annotation no matter what, so user will be notified even when
                                        // they click on an fpk annotation...
                                        
                                        MFURIAnnotation * annotation = [[MFURIAnnotation alloc]init];
                                        annotation.rect = rect;
                                        annotation.frame = frame;
                                        annotation.uri = (NSString *)uri;
                                        annotation.map = isMap;
                                        
                                        [annotations addObject:annotation];
                                        [annotation release],annotation = nil;
                                }
                                else if (strcmp(actionName, "GoToR") == 0)
                                {
                                    
                                    CGPDFDictionaryRef fileSpecification = NULL;
                                    CFStringRef destinationName = NULL;
                                    CFStringRef fileName = NULL;
                                    NSUInteger pageNumber = 0;
                                    
                                    if(CGPDFDictionaryGetDictionary(action, "F", &fileSpecification)) {
                                        
                                        // parseDictionary(fileSpecification);
                                        CGPDFStringRef f = NULL;
                                        
                                        if(CGPDFDictionaryGetString(fileSpecification, "F", &f)) {
                                            fileName = CGPDFStringCopyTextString(f);
                                        }
                                    }
                                    
                                    if(CGPDFDictionaryGetObject(action, "D", &destination)) {
                                        
                                        destinationName = createDestinationNameForDestination(doc, destination, &pageNumber);
                                    }
                                    
                                    MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                    annotation.rect = rect;
                                    annotation.frame = frame;
                                    if(destinationName) {
                                        annotation.destination = (NSString *)destinationName;
                                    } else {
                                        annotation.page = pageNumber;
                                    }
                                    annotation.document = (NSString *) fileName;
                                    
                                    [annotations addObject:annotation];
                                    [annotation release],annotation = nil;
                                    
                                    // Cleanup.
                                    
                                    if(fileName)
                                        CFRelease(fileName);
                                    if(destinationName)
                                        CFRelease(destinationName);
                                    
                                }
                                else if (strcmp(actionName, "Launch") == 0)
                                {
                                    
                                    CGPDFObjectRef fileSpecificationObj = NULL;
                                    CGPDFDictionaryRef fileSpecDictionary = NULL;
                                    CGPDFObjectRef fileNameObj = NULL;
                                    BOOL application = NO;
                                    BOOL print = NO;
                                    CGPDFObjectRef optionObj = NULL;
                                    
                                    if(CGPDFDictionaryGetObject(action, "Win", &fileSpecificationObj))
                                    {
                                        
                                        if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                                            
                                            /*
                                             Check if there are application parameter. If yes
                                             it is an application launch request and will be
                                             ignored.
                                             */
                                            if(CGPDFDictionaryGetObject(fileSpecDictionary, "P", NULL)) {
                                                application = YES;
                                            }
                                            
                                            /*
                                             Check if there is an option parameter. If yes, ensure
                                             that's the value is 'open'.
                                             */
                                            if(CGPDFDictionaryGetObject(fileSpecDictionary, "O", &optionObj)) {
                                                
                                                if (CGPDFObjectGetType(optionObj) == kCGPDFObjectTypeString) {
                                                    
                                                    CGPDFStringRef optionString = NULL;
                                                    CFStringRef option = NULL;
                                                    
                                                    if(CGPDFObjectGetValue(optionObj, kCGPDFObjectTypeString, &optionString)) {
                                                        
                                                        option = CGPDFStringCopyTextString(optionString);
                                                        
                                                        if(![((NSString *)option) compare:@"open" options:NSCaseInsensitiveSearch]) {
                                                            print = YES;
                                                        }
                                                        
                                                        if(option)
                                                            CFRelease(option);
                                                    }
                                                }
                                            }
                                            
                                            /*
                                             If it's not an application launch and it is not
                                             a print action, try to parse the filename
                                             */
                                            if((!application) && (!print) && CGPDFDictionaryGetObject(fileSpecDictionary, "F", &fileNameObj)) {
                                                
                                                if(CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeName) {
                                                    
                                                    const char * fileName;
                                                    if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeName, &fileName)) {
                                                        
                                                        MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                                        annotation.rect = rect;
                                                        
                                                        NSString * fileNameString = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
                                                        
                                                        annotation.page = 1;
                                                        
                                                        annotation.document = (NSString *) fileNameString;
                                                        
                                                        [annotations addObject:annotation];
                                                        [annotation release],annotation = nil;
                                                    }
                                                    
                                                    
                                                }
                                                else if (CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeString) {
                                                    
                                                    CGPDFStringRef fileNameString = NULL;
                                                    CFStringRef fileName = NULL;
                                                    
                                                    if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeString, &fileNameString)) {
                                                        
                                                        fileName = CGPDFStringCopyTextString(fileNameString);
                                                        
                                                        MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                                        annotation.rect = rect;
                                                        
                                                        annotation.page = 1;
                                                        
                                                        annotation.document = (NSString *) fileName;
                                                        
                                                        [annotations addObject:annotation];
                                                        [annotation release],annotation = nil;
                                                        
                                                        if(fileName)
                                                            CFRelease(fileName);
                                                    }
                                                }
                                            }
                                        }
                                        
                                    }
                                    else if (CGPDFDictionaryGetObject(action, "Unix", &fileSpecificationObj))
                                    {
                                        
                                        // Not yet defined as of PDF Referece 1.7.
                                        
                                    }
                                    else if (CGPDFDictionaryGetObject(action, "Mac", &fileSpecificationObj)) {
                                        // Not yet defined as of PDF Referece 1.7.
                                    }
                                    else if (CGPDFDictionaryGetObject(action, "F", &fileSpecificationObj)) {
                                        
                                        // Required as fallback, likely to be the default.
                                        
                                        if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                                            
                                            
                                            CGPDFStringRef fileNameString = NULL;
                                            CFStringRef fileName = NULL;
                                            
                                            /*
                                             Precedence to the UF entry, then F, and then Mac,
                                             Unix and lastly DOS.
                                             */
                                            if(CGPDFDictionaryGetString(fileSpecDictionary, "UF", &fileNameString)) {
                                                
                                            }
                                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "F", &fileNameString)) {
                                                
                                            }
                                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "Mac", &fileNameString)) {
                                                
                                            }
                                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "Unix", &fileNameString)) {
                                                
                                            }
                                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "DOS", &fileNameString)) {
                                                
                                            }
                                            
                                            /*
                                             If we have a valid file name string, we can create
                                             the outline entry.
                                             */
                                            if(fileNameString) {
                                                
                                                fileName = CGPDFStringCopyTextString(fileNameString);
                                                
                                                MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                                annotation.rect = rect;
                                                annotation.frame = frame;
                                                annotation.page = 1;
                                                
                                                annotation.document = (NSString *) fileName;
                                                
                                                [annotations addObject:annotation];
                                                [annotation release],annotation = nil;
                                                
                                                if(fileName ) {
                                                    CFRelease(fileName);
                                                }
                                            }
                                        }
                                    } // End of if 'F'
                                }
                                else
                                {
                                    NSLog(@"Unsupported action %s\n",actionName);
                                }
                                
                            }
                            else if(CGPDFDictionaryGetObject(annotationDictionary, "Dest", &destination))
                            {
                                
                                pageNumber = pageNumberForDestination(doc, destination);
                                
                                // Something has gone wrong, lets skip it.
                                if(pageNumber==0)
                                    continue;
                                
                                MFLinkAnnotation *annotation = [[MFLinkAnnotation alloc]init];
                                annotation.destinationPage = pageNumber;
                                annotation.rect = rect;
                                annotation.frame = frame;
                                [annotations addObject:annotation];
                                [annotation release],annotation = nil;
                            }
                            
                        }
                        
                        else if (strcmp(subtype, "Launch") == 0)
                        {
                                CGPDFObjectRef fileSpecificationObj = NULL;
                                CGPDFDictionaryRef fileSpecDictionary = NULL;
                                CGPDFObjectRef fileNameObj = NULL;
                                BOOL application = NO;
                                BOOL print = NO;
                                CGPDFObjectRef optionObj = NULL;
                                
                                if(CGPDFDictionaryGetObject(annotationDictionary, "Win", &fileSpecificationObj))
                                {
                                    
                                    if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                                        
                                        /*
                                         Check if there are application parameter. If yes
                                         it is an application launch request and will be
                                         ignored.
                                         */
                                        if(CGPDFDictionaryGetObject(fileSpecDictionary, "P", NULL)) {
                                            application = YES;
                                        }
                                        
                                        /*
                                         Check if there is an option parameter. If yes, ensure
                                         that's the value is 'open'.
                                         */
                                        if(CGPDFDictionaryGetObject(fileSpecDictionary, "O", &optionObj)) {
                                            
                                            if (CGPDFObjectGetType(optionObj) == kCGPDFObjectTypeString) {
                                                
                                                CGPDFStringRef optionString = NULL;
                                                CFStringRef option = NULL;
                                                
                                                if(CGPDFObjectGetValue(optionObj, kCGPDFObjectTypeString, &optionString)) {
                                                    
                                                    option = CGPDFStringCopyTextString(optionString);
                                                    
                                                    if(![((NSString *)option) compare:@"open" options:NSCaseInsensitiveSearch]) {
                                                        print = YES;
                                                    }
                                                    
                                                    if(option)
                                                        CFRelease(option);
                                                }
                                            }
                                        }
                                        
                                        /*
                                         If it's not an application launch and it is not
                                         a print action, try to parse the filename
                                         */
                                        if((!application) && (!print) && CGPDFDictionaryGetObject(fileSpecDictionary, "F", &fileNameObj)) {
                                            
                                            if(CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeName) {
                                                
                                                const char * fileName;
                                                if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeName, &fileName)) {
                                                    
                                                    MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                                    annotation.rect = rect;
                                                    annotation.frame = frame;
                                                    NSString * fileNameString = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
                                                    annotation.page = 1;
                                                    annotation.document = (NSString *) fileNameString;
                                                    [annotations addObject:annotation];
                                                    [annotation release],annotation = nil;
                                                }
                                            }
                                            else if (CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeString) {
                                                
                                                CGPDFStringRef fileNameString = NULL;
                                                CFStringRef fileName = NULL;
                                                
                                                if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeString, &fileNameString)) {
                                                    
                                                    fileName = CGPDFStringCopyTextString(fileNameString);
                                                    
                                                    MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                                    annotation.rect = rect;
                                                    annotation.frame = frame;
                                                    annotation.page = 1;
                                                    
                                                    annotation.document = (NSString *) fileName;
                                                    
                                                    [annotations addObject:annotation];
                                                    [annotation release],annotation = nil;
                                                    
                                                    if(fileName)
                                                        CFRelease(fileName);
                                                }
                                            }
                                        }
                                    }
                                }
                                else if (CGPDFDictionaryGetObject(annotationDictionary, "Unix", &fileSpecificationObj))
                                {
                                    
                                    // Not yet defined as of PDF Referece 1.7.
                                    
                                }
                                else if (CGPDFDictionaryGetObject(annotationDictionary, "Mac", &fileSpecificationObj)) {
                                    // Not yet defined as of PDF Referece 1.7.
                                }
                                else if (CGPDFDictionaryGetObject(action, "F", &fileSpecificationObj)) {
                                    
                                    // Required as fallback, likely to be the default.
                                    
                                    if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                                        
                                        
                                        CGPDFStringRef fileNameString = NULL;
                                        CFStringRef fileName = NULL;
                                        
                                        /*
                                         Precedence to the UF entry, then F, and then Mac,
                                         Unix and lastly DOS.
                                         */
                                        if(CGPDFDictionaryGetString(fileSpecDictionary, "UF", &fileNameString)) {
                                            
                                        }
                                        else if (CGPDFDictionaryGetString(fileSpecDictionary, "F", &fileNameString)) {
                                            
                                        }
                                        else if (CGPDFDictionaryGetString(fileSpecDictionary, "Mac", &fileNameString)) {
                                            
                                        }
                                        else if (CGPDFDictionaryGetString(fileSpecDictionary, "Unix", &fileNameString)) {
                                            
                                        }
                                        else if (CGPDFDictionaryGetString(fileSpecDictionary, "DOS", &fileNameString)) {
                                            
                                        }
                                        
                                        /*
                                         If we have a valid file name string, we can create
                                         the outline entry.
                                         */
                                        if(fileNameString) {
                                            
                                            fileName = CGPDFStringCopyTextString(fileNameString);
                                            
                                            MFRemoteLinkAnnotation * annotation = [[MFRemoteLinkAnnotation alloc]init];
                                            annotation.rect = rect;
                                            annotation.frame = frame;
                                            annotation.page = 1;
                                            
                                            annotation.document = (NSString *) fileName;
                                            
                                            [annotations addObject:annotation];
                                            [annotation release],annotation = nil;
                                            
                                            if(fileName ) {
                                                CFRelease(fileName);
                                            }
                                        }
                                    }
                                } // End of if 'F'                            
                        } // Action
                        
                        else if(strcmp(subtype, "Text") == 0) {
                            
                            continue;
                            
#if DEBUG
                            NSLog(@"Text annotation found");
#endif
                            CGPDFStringRef contentsString = NULL;
                            
                            if(CGPDFDictionaryGetString(annotationDictionary, "Contents", &contentsString)) {
      
#if DEBUG
                                NSLog(@"Contents found");
                                CFStringRef contents = CGPDFStringCopyTextString(contentsString);
                                NSLog(@"Contents: %@", (NSString *) contents);
                                if(contents) {
                                    CFRelease(contents);
                                }
#endif
                                
                            }
                            
                            CGPDFDictionaryRef apDictionary = NULL;
                            if(CGPDFDictionaryGetDictionary(annotationDictionary, "AP", &apDictionary)) {
                                
                                CGPDFObjectRef nObject = NULL;
                                if(CGPDFDictionaryGetObject(apDictionary, "N", &nObject)) {
                                    
                                    CGPDFStreamRef stream = NULL;
                                    CGPDFDictionaryRef dictionary = NULL;
                                    
                                    if(CGPDFObjectGetValue(nObject, kCGPDFObjectTypeStream, &stream)) {
                                        
                                        
                                        
                                        CGPDFDataFormat format;
                                        
                                        CFDataRef data = CGPDFStreamCopyData(stream, &format);
                                        
                                        switch (format) {
                                            case CGPDFDataFormatRaw:
                                                
                                                [self drawObject:(NSData *)data 
                                                       onContext:nil 
                                                      dictionary:nil];
                                                
                                                break;
                                            case CGPDFDataFormatJPEG2000:
                                                NSLog(@"JPEG2000");
                                                break;
                                            case CGPDFDataFormatJPEGEncoded:
                                                NSLog(@"JPEGEncoded");
                                            default:
                                                NSLog(@"Unknow format");
                                                break;
                                        }
                                        
                                        if(data)
                                            CFRelease(data);
                                    }
                                    
                                    if(CGPDFObjectGetValue(nObject, kCGPDFObjectTypeDictionary, &dictionary)) {
                                        NSLog(@"Dictionary found too");
                                    }
                                    
                                }
                            }
                            
                            CGPDFObjectRef popup = NULL;
                            if(CGPDFDictionaryGetObject(annotationDictionary, "Popup", &popup)) {
                                NSLog(@"Has popup");
                            } else {
                                NSLog(@"No popup");
                            }
                        } // Text
                        
                        else if(strcmp(subtype, "Popup") == 0) {
                            
                            continue;
                            
                            CGPDFStringRef contentsString = NULL;
                            if(CGPDFDictionaryGetString(annotationDictionary, "Contents", &contentsString)) {
                                NSLog(@"Contents found");
                                CFStringRef contents = CGPDFStringCopyTextString(contentsString);
                                NSLog(@"Contents: %@", (NSString *) contents);
                                if(contents)
                                    CFRelease(contents);
                            }
                            
                        } // Popup
                        else if (strcmp(subtype, "FreeText")==0) {
                            
                            continue;
                            
                            NSLog(@"FreeText annotation found");
                            
                            CGPDFStringRef contentsString = NULL;
                            
                            if(CGPDFDictionaryGetString(annotationDictionary, "Contents", &contentsString)) {
                                
                                NSLog(@"Contents found");
                                CFStringRef contents = CGPDFStringCopyTextString(contentsString);
                                NSLog(@"Contents: %@", (NSString *) contents);
                                if(contents)
                                    CFRelease(contents);
                                
                            }
                            
                            CGPDFDictionaryRef apDictionary = NULL;
                            if(CGPDFDictionaryGetDictionary(annotationDictionary, "AP", &apDictionary)) {
                                
                                CGPDFObjectRef nObject = NULL;
                                if(CGPDFDictionaryGetObject(apDictionary, "N", &nObject)) {
                                    
                                    CGPDFStreamRef stream = NULL;
                                    CGPDFDictionaryRef dictionary = NULL;
                                    
                                    if(CGPDFObjectGetValue(nObject, kCGPDFObjectTypeStream, &stream)) {
                                        NSLog(@"Stream found");
                                        CGPDFDataFormat format;
                                        
                                        CFDataRef data = CGPDFStreamCopyData(stream, &format);
                                        
                                        switch (format) {
                                            case CGPDFDataFormatRaw:
                                                NSLog(@"Raw");
                                                
                                                [self drawObject:(NSData *)data onContext:nil dictionary:nil];
                                                
                                                break;
                                            case CGPDFDataFormatJPEG2000:
                                                NSLog(@"JPEG2000");
                                                break;
                                            case CGPDFDataFormatJPEGEncoded:
                                                NSLog(@"JPEGEncoded");
                                            default:
                                                NSLog(@"Unknow format");
                                                break;
                                        }
                                        
                                        if(data)
                                            CFRelease(data);
                                    }
                                    
                                    if(CGPDFObjectGetValue(nObject, kCGPDFObjectTypeDictionary, &dictionary)) {
                                        NSLog(@"Dictionary found too");
                                    }
                                    
                                }
                            }
                            
                            CGPDFObjectRef popup = NULL;
                            if(CGPDFDictionaryGetObject(annotationDictionary, "Popup", &popup)) {
                                NSLog(@"Has popup");
                            } else {
                                NSLog(@"No popup");
                            }
                        }
                    }
                } // for annots
        }
    }
	
	[self unlockDocument:doc];
        
    [self.annotationsCache addAnnotationsCount:annotations.count page:pageNr];
	
	return [annotations autorelease];
}

-(NSArray *)ensureAnnotationsLoadedForPageNumber:(NSUInteger)number {
    
    NSArray * annotations = [self.annotationsHelper annotationsForPage:number];
    
    if(!annotations) {
        
        annotations = [self allSupportedAnnotationsForPageNumber:number];
        
        [self.annotationsHelper addAnnotations:annotations page:number];
    }
    
    return annotations;
}

-(NSArray *)webAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    NSArray * annotations = [self ensureAnnotationsLoadedForPageNumber:pageNr];
    
    NSMutableArray * tmp = [NSMutableArray array];
    
    for(id annotation in annotations) {
        if([annotation isKindOfClass:[MFWebAnnotation class]])
            [tmp addObject:annotation];
    }
    
    return [NSArray arrayWithArray:tmp];
}

-(NSArray *)configAnnotationsForPageNumber:(NSUInteger)pageNr {
    NSArray * annotations = [self ensureAnnotationsLoadedForPageNumber:pageNr];
    
    NSMutableArray * tmp = [NSMutableArray array];
    
    for(id annotation in annotations) {
        if([annotation isKindOfClass:[FPKConfigAnnotation class]])
            [tmp addObject:annotation];
    }
    
    return [NSArray arrayWithArray:tmp];
}

-(NSArray *)videoAnnotationsForPageNumber:(NSUInteger)pageNr {
	
    NSArray * annotations = [self ensureAnnotationsLoadedForPageNumber:pageNr];
    
    NSMutableArray * tmp = [NSMutableArray array];
    
    for(id annotation in annotations) {
        if([annotation isKindOfClass:[MFVideoAnnotation class]])
            [tmp addObject:annotation];
    }
    
    return [NSArray arrayWithArray:tmp];
   }


#pragma mark - 
#pragma mark Tagged PDF

// Word spacing.
static void op_MP(CGPDFScannerRef s, void *info) {
    fprintf(stdout, "MP\n");
}

static void op_DP(CGPDFScannerRef s, void * info) {
    fprintf(stdout, "DP\n");    
}
static void op_BMC(CGPDFScannerRef s, void * info) {
        fprintf(stdout, "BMC\n");
}
static void op_BDC(CGPDFScannerRef s, void * info) {
        fprintf(stdout, "BDC\n");
}
static void op_EMC(CGPDFScannerRef s, void * info) {
        fprintf(stdout, "EMC\n");
}
static void op_Tj(CGPDFScannerRef s, void * info) {
        fprintf(stdout, "Tj\n");
}

-(void)taggedInformation:(NSUInteger)pageNumber {
    
    CGPDFDocumentRef doc = [self lockDocument];
    
    CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();
    
    float x;
    
    CGPDFOperatorTableSetCallback(operatorTable, "MP", &op_MP);
    CGPDFOperatorTableSetCallback(operatorTable, "DP", &op_DP);    
    CGPDFOperatorTableSetCallback(operatorTable, "BMC", &op_BMC);   
    CGPDFOperatorTableSetCallback(operatorTable, "BDC", &op_BDC);
    CGPDFOperatorTableSetCallback(operatorTable, "EMC", &op_EMC);
    CGPDFOperatorTableSetCallback(operatorTable, "TJ", &op_Tj);
    
	CGPDFPageRef page = CGPDFDocumentGetPage(doc, pageNumber);
	// CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
    
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, &x);
	
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	
    CGPDFContentStreamRelease(contentStream);
    CGPDFOperatorTableRelease(operatorTable);
    
    [self unlockDocument:doc];
    
    CGPDFDictionaryRef catalog = NULL;
    //CGPDFPageRef page = NULL;
    CGPDFDictionaryRef markInfo = NULL;
    CGPDFDictionaryRef structTreeRoot = NULL;
    CGPDFBoolean marked, userProperties, suspects;
    
    doc = [self lockDocument];
    
    
    page = CGPDFDocumentGetPage(doc, pageNumber);
    catalog = CGPDFDocumentGetCatalog(doc);
    size_t catalog_count = CGPDFDictionaryGetCount(catalog);
    
    NSLog(@"Catalog entry count %lu",catalog_count);
      parseDictionary(catalog);
    if(CGPDFDictionaryGetDictionary(catalog, "MarkInfo", &markInfo)) {
    
      
        
        CGPDFDictionaryGetBoolean(markInfo, "Marked", &marked);
        CGPDFDictionaryGetBoolean(markInfo, "UserProperties", &userProperties);
        CGPDFDictionaryGetBoolean(markInfo, "Suspects", &suspects);
    
        NSLog(@"Marked: %d UserProperties: %d Suspects: %d",marked,userProperties,suspects);
    
    } else {
        
        NSLog(@"MarkInfo not found in the catalog");
    }
    
    if(CGPDFDictionaryGetDictionary(catalog, "StructTreeRoot", &structTreeRoot)) {
        NSLog(@"StructTreeRoot found");
    } else {
        NSLog(@"StructTreeRoot not found");
    }
    
    [self unlockDocument:doc];
}

#pragma mark -
#pragma mark Annotations

-(BOOL)isFpkAnnotation:(NSString *)uri {
    
    NSString * partial = nil;
    
    if([[uri substringToIndex:3]isEqualToString:@"fpk"]) {
     
        partial = [uri substringToIndex:4];
        
        if([partial isEqualToString:@"fpkv"]||[partial isEqualToString:@"fpky"]||[partial isEqualToString:@"fpkw"]||[partial isEqualToString:@"fpkh"]
           ||[partial isEqualToString:@"fpka"]||[partial isEqualToString:@"fpkb"]||[partial isEqualToString:@"fpkm"]) {
            return YES;
        }
    }
    
    return NO;
}


-(NSArray *)linkAndURIAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    NSArray * annotations = [self ensureAnnotationsLoadedForPageNumber:pageNr];
    NSMutableArray * tmp = [NSMutableArray array];
    for(id ann in annotations) {
        
        if([ann isKindOfClass:[MFURIAnnotation class]]||[ann isKindOfClass:[MFRemoteLinkAnnotation class]]||[ann isKindOfClass:[MFLinkAnnotation class]]) {
            [tmp addObject:ann];
        }
        
    }
    
    return [NSArray arrayWithArray:tmp];
}

-(NSArray *)textAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    return [self allSupportedAnnotationsForPageNumber:pageNr];
}

-(NSArray *)uriAnnotationsForPageNumber:(NSUInteger)pageNr {
    
    if(!fpk_multimedia_version)
		return nil;
    
    NSArray * internalUriAnnotations = [self linkAndURIAnnotationsForPageNumber:pageNr];
    NSMutableArray * annotations = [NSMutableArray array];
    for(MFAnnotation * note in internalUriAnnotations) {
        if([note isKindOfClass:[MFURIAnnotation class]]) {
            [annotations addObject:[(MFURIAnnotation *)note annotation]];
        }
    }
    return [NSArray arrayWithArray:annotations];
}

#pragma mark - Glyph box extraction

-(NSArray *)glyphBoxesForPage:(NSUInteger)pageNr 
{
    
    CGPDFPageRef page = NULL;
    
	MFStreamScanner *streamScanner = nil;
	MFTextStateGlyphData *state = nil;
	NSArray * boxes;    
	
	if(!(fpk_registered_version && fpk_textsearch_version))
		return nil;
	
	state = [[MFTextStateGlyphData alloc]init];
    
    CGPDFDocumentRef doc = [self lockDocument];
 	
	page = CGPDFDocumentGetPage(doc, pageNr);
	
    if(page) {
        
        streamScanner = [[MFStreamScanner alloc]initWithTextState:state andPage:page];
        if(fontCacheEnabled) {
            [streamScanner setUseCache:YES];
            [streamScanner setFontCache:fontCache];
        }
        
        [streamScanner scan];
	}
    
    [self unlockDocument:doc];
	
	boxes = [[NSArray alloc]initWithArray:[state textLines]];
	
	[streamScanner release];
	[state release];
	
	return [boxes autorelease];
}

#pragma mark -
#pragma mark Text extraction methods

-(NSString *)test_wholeTextForPage:(NSUInteger)pageNr {
    
    return [self wholeTextForPage:pageNr];
}

-(NSString *)wholeTextForPage:(NSUInteger)pageNr {
    
    CGPDFPageRef page = NULL;
    
	MFStreamScanner *streamScanner = nil;
	MFTextStateSmartExtraction *state = nil;
	NSString *text = nil;    
	
	if(!fpk_textsearch_version)
		return nil;
	
	state = [[MFTextStateSmartExtraction alloc]init];
    
	CGPDFDocumentRef doc = [self lockDocument];
 	
	page = CGPDFDocumentGetPage(doc, pageNr);
	
    if(page) {
        
        streamScanner = [[MFStreamScanner alloc]initWithTextState:state andPage:page];
        if(fontCacheEnabled) {
            [streamScanner setUseCache:YES];
            [streamScanner setFontCache:fontCache];
        }
        
        [streamScanner scan];
	}
    
    [self unlockDocument:doc];
	
    NSString * textBuffer = [state textBuffer];
    
    if(textBuffer) {
        text = [[NSString alloc]initWithString:textBuffer];
	}
    
	[streamScanner release];
	[state release];
	
	return [text autorelease];
}

-(NSString *)wholeTextForPage:(NSUInteger)pageNr withProfile:(MFProfile *)p {
		
    return [self wholeTextForPage:pageNr];
}

#pragma mark - Conversion

-(void)convertRectsFromPDFSpaceToViewSpace:(CGRect *)rects length:(NSUInteger)length page:(NSUInteger)page {
    
    CGRect box;
    [self getCropbox:&box andRotation:NULL forPageNumber:page];
    
    for (NSUInteger index = 0; index < length; index++) {
        
        rects[index] = FPKReversedAnnotationRect(rects[index], box.size.height);
    }
}

-(void)convertRectsFromViewSpaceToPDFSpace:(CGRect *)rects length:(NSUInteger)length page:(NSUInteger)page {
    CGRect box;
    [self getCropbox:&box andRotation:NULL forPageNumber:page];
    
    for (NSUInteger index = 0; index < length; index++) {
        
        rects[index] = FPKReversedAnnotationRect(rects[index], box.size.height);
    }
}

-(CGRect)convertRectFromPDFSpaceToViewSpace:(CGRect)rect page:(NSUInteger)page {
    CGRect box;
    [self getCropbox:&box andRotation:NULL forPageNumber:page];
    return FPKReversedAnnotationRect(rect, box.size.height);
}

-(CGRect)convertRectFromViewSpaceToPDFSpace:(CGRect)rect page:(NSUInteger)page {
    CGRect box;
    [self getCropbox:&box andRotation:NULL forPageNumber:page];
    return FPKReversedAnnotationRect(rect, box.size.height);
}

#pragma mark -
#pragma mark Search text methods

-(NSArray *)searchItemsFromTextBoxArray:(NSArray *)textboxes
                                 onPage:(NSUInteger)page
                                cropbox:(CGRect)box
{
    return [self searchItemsFromTextBoxArray:textboxes onPage:page cropbox:box pdfCoordinates:YES];
}

/**
 * Same as searchItemsFromTextBoxArray:onPage:, except that the box paramter is used
 * to calculate the highlight path in reversed pages coordinates (origin on the upper left).
 */
-(NSArray *)searchItemsFromTextBoxArray:(NSArray *)textboxes
                                 onPage:(NSUInteger)page
                                    cropbox:(CGRect)box
                         pdfCoordinates:(BOOL)pdfCoords
{
    
    NSUInteger count = textboxes.count;
    if(count == 0) {
        return nil;
    }
    
    // Cycle over the TextBox putted inside textboxes.
    
    NSMutableArray * searchItems = [[NSMutableArray alloc] initWithCapacity:count];
    
    // Now cycle over the GlyphQuad of the TextBox and create its CGPath.
    
    [textboxes enumerateObjectsUsingBlock:^(MFTextBox *  _Nonnull tb, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGMutablePathRef path = CGPathCreateMutable();
        
        NSArray * quads = [tb quads];
        
        NSUInteger quadCount = [quads count];
        for(int j = 0; j < quadCount; j++) {
            
            MFGlyphQuad *quad = [quads objectAtIndex:j];
            CGAffineTransform transform = [quad transform];
            CGPathAddRect(path, &transform, [quad box]);
        }
        
        CGRect boundingBox = CGPathGetBoundingBox(path);
        
        if(!pdfCoords) {
            boundingBox = FPKReversedAnnotationRect(boundingBox, box.size.height);
        }
        
        CGPathRef enclosingPath = CGPathCreateWithRect(boundingBox, NULL);
        
        NSString *text = [tb text];
        
        MFTextItem * searchItem = [[MFTextItem alloc]initWithText:text
                                                    highlightPath:enclosingPath
                                                          andPage:page];
        searchItem.searchTermRange = tb.searchTermRange;
        [searchItems addObject:searchItem];
        [searchItem release];
        
        CGPathRelease(path);
        CGPathRelease(enclosingPath);
        
    }];
    
    return [searchItems autorelease];
}

-(NSArray *)searchItemsFromTextBoxArray:(NSArray *)textboxes onPage:(NSUInteger)page {
	
	MFTextItem *searchItem = nil;
	NSMutableArray *searchItems = nil;
	
	// Cycle over the TextBox putted inside textboxes.
	
	NSUInteger count;
	if((count = [textboxes count]) > 0) {
		
		searchItems = [[NSMutableArray alloc]initWithCapacity:count];
		
		// Now cycle over the GlyphQuad of the TextBox and create its CGPath.
		
		int i;
		for(i = 0; i < count; i++) {
			
			MFTextBox *tb = [textboxes objectAtIndex:i];
			
			CGMutablePathRef path = CGPathCreateMutable();
			
			NSArray * quads = [tb quads];
			
			NSUInteger quadCount = [quads count];
			int j;
			
			for(j = 0; j < quadCount; j++) {
				
				MFGlyphQuad *quad = [quads objectAtIndex:j];
				CGAffineTransform transform = [quad transform];
				CGPathAddRect(path, &transform, [quad box]);
                
                // NSLog(@"Box %@", NSStringFromCGRect([quad box]));
			}
            
            CGPathRef enclosingPath = CGPathCreateWithRect(CGPathGetBoundingBox(path), NULL);
            
			// NSLog(@"Enclosing %@", NSStringFromCGRect(CGPathGetBoundingBox(path)));
            
			// Create the MFSearchItem with the text context of the TextBox and the CGPath of the search term.
			
			NSString *text = [tb text];
			
			searchItem = [[MFTextItem alloc]initWithText:text highlightPath:path andPage:page];
			searchItem.searchTermRange = tb.searchTermRange;
			[searchItems addObject:searchItem];
			[searchItem release];
            
			CGPathRelease(path);
            CGPathRelease(enclosingPath);
		}
	}
	
	return [searchItems autorelease];
}

#pragma mark - Search

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                          mode:(FPKSearchMode)mode 
                    ignoreCase:(BOOL)ignoreOrNot 
                    exactMatch:(BOOL)exactMatchOrNot
                pdfCoordinates:(BOOL)pdf;

{
    CGPDFPageRef page = NULL;
	MFStreamScanner *streamScanner = nil;
	NSMutableArray *textboxes = nil;
	MFTextState * textState = nil;
    NSArray * searchItems = nil;
    
    if(pageNr <= 0 || pageNr > numberOfPages)
        return nil;
    
	if(!fpk_textsearch_version)
		return nil;
	
    textboxes = [[NSMutableArray alloc]init];
    
	textState = [[MFTextStateSmartSearch alloc]initWithSearchTerm:searchTerm];
	[textState setTextboxDestination:textboxes];
    
    [(MFTextStateSmartSearch *)textState setIgnoreCase:ignoreOrNot];
    [(MFTextStateSmartSearch *)textState setSearchMode:mode];
    [(MFTextStateSmartSearch *)textState setExactMatch:exactMatchOrNot];
    [(MFTextStateSmartSearch *)textState prepare];
    
    CGPDFDocumentRef doc = [self lockDocument];
 	
	page = CGPDFDocumentGetPage(doc, pageNr);
    
    CGRect box = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
	
	streamScanner = [[MFStreamScanner alloc]initWithTextState:textState andPage:page];
    
    if(fontCacheEnabled)
    {
        [streamScanner setUseCache:YES];
        [streamScanner setFontCache:fontCache];
    }
    
	[textState release];
	
	[streamScanner scan];
	
    [self unlockDocument:doc];
    
    [(MFTextStateSmartSearch *)textState compileTextBoxes];
	
	searchItems = [self searchItemsFromTextBoxArray:textboxes
                                             onPage:pageNr
                                                cropbox:box
                                     pdfCoordinates:pdf];
	[streamScanner release];
	[textboxes release];
	
	return searchItems;
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr
                forSearchTerms:(NSString *)searchTerm
                          mode:(FPKSearchMode)mode
                    ignoreCase:(BOOL)ignoreCaseOrNot
                    exactMatch:(BOOL)exactMatchOrNot
{
    return [self searchResultOnPage:pageNr
                     forSearchTerms:searchTerm
                               mode:mode
                         ignoreCase:ignoreCaseOrNot
                         exactMatch:exactMatchOrNot
                     pdfCoordinates:YES];
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                          mode:(FPKSearchMode)mode 
                    ignoreCase:(BOOL)ignoreOrNot 
{
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:mode 
                         ignoreCase:ignoreOrNot 
                         exactMatch:NO];
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                    ignoreCase:(BOOL)ignoreOrNot 
                    exactMatch:(BOOL)exactMatchorNot
{
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:FPKSearchModeSmart 
                         ignoreCase:ignoreOrNot 
                         exactMatch:exactMatchorNot];
}


-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                          mode:(FPKSearchMode)mode 
                    exactMatch:(BOOL)exactMatchOrNot 
{
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:mode 
                         ignoreCase:YES 
                         exactMatch:exactMatchOrNot];
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                    mode:(FPKSearchMode)mode 
{
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:mode 
                         ignoreCase:YES 
                         exactMatch:NO];
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                    ignoreCase:(BOOL)ignoreOrNot 
{    
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:FPKSearchModeSmart 
                         ignoreCase:ignoreOrNot 
                         exactMatch:NO];
    
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                    exactMatch:(BOOL)exactMatchOrNot 
{
    
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:FPKSearchModeSmart 
                         ignoreCase:YES 
                         exactMatch:exactMatchOrNot];
}


-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
{
    
    return [self searchResultOnPage:pageNr 
                     forSearchTerms:searchTerm 
                               mode:FPKSearchModeSmart 
                         ignoreCase:YES 
                         exactMatch:NO];
}

-(NSArray *)searchResultOnPage:(NSUInteger)pageNr 
                forSearchTerms:(NSString *)searchTerm 
                   withProfile:(MFProfile *)p 
{
    return [self searchResultOnPage:pageNr forSearchTerms:searchTerm];
}

#pragma mark -

-(NSUInteger)pageNumberForDestinationNamed:(NSString *)name {

    CGPDFDocumentRef doc = [self lockDocument];
 	
    NSUInteger pageNumber = pageNumber = pageNumberForDestinationNamed(doc, name);
    
    [self unlockDocument:doc];
    
    return pageNumber;
}


#pragma mark -
#pragma mark Lifecycle

-(MFOffscreenRenderer *)renderer {
    if(!renderer) {
        renderer = [[MFOffscreenRenderer alloc]init];
        renderer.dataSource = self;
    }
    return renderer;
}

-(void)commonInit
{
    checkSignature();;
    
    _conservativeMemoryUsageHint = DEF_CONSERVATIVE_MEMORY_USAGE;
    
    fontCacheEnabled = YES;
    alternateURISchemesEnabled = YES;
    
    pthread_mutex_init(&_mainLock, NULL);
    pthread_cond_init(&_mainCondition, NULL);

    int coreCounts = countCores();
    for(NSUInteger i = 0; i < 3; i++) {
        _documents[i].document = NULL;
        _documents[i].clear = 0;
        _documents[i].lock = i < coreCounts ? 0 : 1;
    }
    
    fontCache = [[NSMutableDictionary alloc]init];
    
    pthread_rwlock_init(&_pageDataLock, NULL);
    
    FPKAnnotationsHelper * annotationsHelper = [[FPKAnnotationsHelper alloc]init];
    self.annotationsHelper = annotationsHelper;
    [annotationsHelper release];

    CGPDFDocumentRef doc = [self lockDocument];
    
    if(CGPDFDocumentIsUnlocked(doc))
        numberOfPages = CGPDFDocumentGetNumberOfPages(doc); // Can be 0 if document is encrypted.
    
    [self unlockDocument:doc];
    
    // Data cache
    _metricsCache = [NSMutableDictionary new];
    _metricsFactory = [FPKPageMetricsFactory new];
    
    // Annotation
    _annotationsCache = [[FPKAnnotationsCache alloc]init];
}

-(id)initWithDataProvider:(CGDataProviderRef)dataProvider {
    
    if((self = [super init])) {
        
        provider = CGDataProviderRetain(dataProvider);
        
        [self commonInit];
        
         // Force single document
        for(NSUInteger i = 0; i < 3; i++) {
            _documents[i].document = NULL;
            _documents[i].clear = 0;
            _documents[i].lock = i < 1;
        }
    }
    
    return self;
}

-(id)initWithFileUrl:(NSURL *)anUrl {
	
	if((self = [super init])) {
        
    	url = [anUrl retain];
        
        [self commonInit];
	}
	
	return self;
}

+(MFDocumentManager *)documentManagerWithFilePath:(NSString *)filePath {
	
	NSURL *anUrl = [NSURL fileURLWithPath:filePath];
	MFDocumentManager *documentManager = [[[MFDocumentManager alloc]initWithFileUrl:anUrl]autorelease];
	return documentManager;
}

-(void)tearDown {
	
    [self clearDocuments];
	
	[renderer tearDown];
}

-(void)emptyCache {
	
#if DEBUG
	NSLog(@"Cleaning up the cache.");
#endif
	
	[self clearDocuments];
    
    // Font cache could also not be cleared on empty cache, since it does not
    // contain reference to the document objects. 
    [fontCache removeAllObjects];
}

-(void)dealloc {
	
#if FPK_DEALLOC
	NSLog(@"%@ -dealloc",NSStringFromClass([self class]));
#endif
	
	[self tearDown];
	
    [resourceFolder release], resourceFolder = nil;
    
    [_annotationsHelper release], _annotationsHelper = nil;
    [_annotationsCache release], _annotationsCache = nil;
    
    [_metricsCache release], _metricsCache = nil;
    [_metricsFactory release], _metricsFactory = nil;
    
    if(provider)
        CGDataProviderRelease(provider),provider = NULL;
    
	[renderer release], renderer = nil;
    
	[url release], url = nil;
	[password release], password = nil;
	
    [fontCache release], fontCache = nil;
    
    pthread_rwlock_destroy(&_pageDataLock);
    
	[super dealloc];
}

#pragma mark - OLD

-(void)drawObject:(NSData *)data
        onContext:(CGContextRef)context
       dictionary:(NSDictionary *)dictionary
{
    NSString * reasons = [NSString stringWithFormat:@"Unimplemented method %@", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reasons userInfo:nil];
}

@end
