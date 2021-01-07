//
//  MenuViewController.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuViewController.h"
#import "MFDocumentManager.h"
#import "ReaderViewController.h"
#import "SSZipArchive.h"
#import <QuartzCore/QuartzCore.h>
#import "TestOverlayViewDataSource.h"
#import "FPKBaseEmbeddedAnnotationURIHandler.h"
#import "TestOverlayDataSource.h"
#import "FPKOverlayManager.h"
#import "OverlayManager.h"
#import "TestOverlayViewDataSource2.h"
#import "FPKAnnotationDrawableDataSource.h"


@implementation Document

-(NSURL *)URL {
    return [[NSBundle mainBundle]URLForResource:_filename withExtension:nil];
}

#pragma mark - Factory methods

+(Document *)documentWithFilename:(NSString *)filename {
    Document * document = [Document new];
    document.filename = filename;
    document.identifier = filename;
    document.name = filename;
    return document;
}

+(NSArray *)documentsWithFilenames:(NSString **)filenames count:(NSUInteger)count {
    NSMutableArray * documents = [NSMutableArray new];
    for(NSUInteger index = 0; index < count; index++) {
        NSString * filename = filenames[index];
        Document *document = [Document documentWithFilename:filename];
        [documents addObject:document];
    }
    return documents;
}
@end


@implementation MultimediaDocument

+(MultimediaDocument *)documentWithFilename:(NSString *)filename {
    MultimediaDocument * doc = [MultimediaDocument new];
    doc.filename = filename;
    doc.identifier = filename;
    doc.name = filename;
    return doc;
}

@end

@implementation MenuViewController

+(MultimediaDocument *)defaultMultimediaDocument {
    static MultimediaDocument * document = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MultimediaDocument * doc = [MultimediaDocument documentWithFilename:@"aaa.zip"];
        doc.document = @"aaa.pdf";
        document = doc;
         
    });
    return document;
}

/**
 * Return a list of documents.
 */
+(NSArray *)documents {
    
    static NSArray * documents = NULL;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSMutableArray * docs = [NSMutableArray new];
        
        //TODO: add your documents here!
        
        [docs addObject:[Document documentWithFilename:@"pdf_reference_1_7.pdf"]];
        
        documents = [NSArray arrayWithArray:docs];
    });
    return documents;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[MenuViewController documents] count];
}

static NSUInteger kTypePlain = 0;
static NSUInteger kTypeMultimedia = 1;

-(NSUInteger)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    id doc = [[MenuViewController documents] objectAtIndex:indexPath.row];
    if([doc isKindOfClass:[MultimediaDocument class]]) {
        return kTypeMultimedia;
    }
    return kTypePlain;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * cellID = @"Document";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if(cell==nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(0, 0, 32, 32)];
        [button addTarget:self action:@selector(thumbnailButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Thumb" forState:UIControlStateNormal];
        cell.accessoryView = button;
    }
    
    Document * document = [MenuViewController documents][indexPath.row];
    cell.textLabel.text = document.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Document *document = [MenuViewController documents][indexPath.row];
    [self openURL:document.URL];
}

#pragma mark - Actions

-(void)thumbnailButtonTapped:(id)sender event:(id)event {
    
    UITouch * anyTouch = [[event allTouches]anyObject];
    CGPoint location = [anyTouch locationInView:self.tableView];
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
    if(indexPath!=nil) {
        Document * document = [[MenuViewController documents]objectAtIndex:indexPath.row];
        [self actionThumbnail:document];
    }
}

/**
 * Return a lazily allocated TestOverlayViewDataSource.
 */
-(TestOverlayViewDataSource *)testOverlayViewDataSource {
    if(!_testOverlayViewDataSource) {
        TestOverlayViewDataSource * dataSource = [[TestOverlayViewDataSource alloc]init];
        self.testOverlayViewDataSource = dataSource;
    }
    return _testOverlayViewDataSource;
}

-(TestOverlayViewDataSource2 *)testOverlayDataSource2 {
    if(!_testOverlayDataSource2) {
        TestOverlayViewDataSource2 * datasource = [TestOverlayViewDataSource2 new];
        self.testOverlayDataSource2 = datasource;
    }
    return _testOverlayDataSource2;
}

-(TestOverlayDataSource *)testOverlayDataSource {
    if(!_testOverlayDataSource) {
        TestOverlayDataSource * dataSource = [TestOverlayDataSource new];
        self.testOverlayDataSource = dataSource;
    }
    return _testOverlayDataSource;
}

-(void)dismissDocumentViewController:(id)controller {
    
    [[self navigationController]popToViewController:self animated:YES];
}

-(IBAction)actionWipeCache:(id)sender
{
    NSString * cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSError * __autoreleasing error = nil;
    NSArray * cacheContent = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:cachePath error:&error];

    NSLog(@"WIPING CACHE AT %@", cachePath);
    
    if(cacheContent)
    {
        for(NSString * subpath in cacheContent)
        {
            NSString * pathToDelete = [cachePath stringByAppendingPathComponent:subpath];
            if([[NSFileManager defaultManager]removeItemAtPath:pathToDelete error:&error])
            {
                NSLog(@"Wiped %@", pathToDelete);
            }
        }
    }
    else
    {
        NSLog(@"Unable to wipe cache directory %@", cachePath);
        NSLog(@"%@", error.localizedDescription);
    }
}

-(void)openURL:(NSURL *)url
{
    if(!url)
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Not Found!"
                                                        message:[NSString stringWithFormat:@"Document %@.pdf not found in the bundle.", url.lastPathComponent]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    else
    {
        
        // NSData * data = [NSData dataWithContentsOfURL:url];
        
        // CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        
        MFDocumentManager *documentManager = [[MFDocumentManager alloc] initWithFileUrl:url];
        documentManager.conservativeMemoryUsage = YES;
        documentManager.fontCacheEnabled = NO;
        documentManager.conservativeMemoryUsageHint = 50 * 1024 * 1024;
        documentManager.conservativeMemoryUsage = true;
        // CGDataProviderRelease(dataProvider);
        
        // MFDocumentManager * documentManager = [[MFDocumentManager alloc]initWithFileUrl:url];
        
        if([documentManager isLocked])
        {
            NSLog(@"Locked");
            
            if([documentManager tryUnlockWithPassword:@"123Ciao"])
            {
                NSLog(@"Unlocked");
            }
        }
        
        ReaderViewController * docViewController = [[ReaderViewController alloc]initWithDocumentManager:documentManager];
        docViewController.overlayEnabled = YES;
        docViewController.documentId = url.lastPathComponent;
        docViewController.pageSliderEnabled = YES;
        docViewController.edgeFlipWidth = 0;
        docViewController.settings.foregroundEnabled = NO;
        docViewController.settings.cacheImageScale = FPKImageCacheScaleTrueToPixels;
        
        TestOverlayDataSource * dataSource = self.testOverlayDataSource;
        [docViewController addOverlayDataSource:dataSource];
        
        FPKOverlayManager * overlayManager = [self overlayManager];
        
        overlayManager.documentViewController = docViewController;
        
        [docViewController addOverlayViewDataSource:overlayManager name:@"overlayManager"];
        
        id<FPKOverlayViewDataSource> dataSource2 = self.testOverlayViewDataSource;
        [docViewController addOverlayViewDataSource:dataSource2 name:@"test2"];
        
        FPKAnnotationDrawableDataSource * annotationDS = [FPKAnnotationDrawableDataSource new];
        annotationDS.documentManager = documentManager;
        [docViewController addOverlayDataSource:annotationDS];
        
        docViewController.thumbnailSliderEnabled = YES;
        docViewController.settings.cacheImageScale = FPKImageCacheScaleTrueToPixels;
        [docViewController setDefaultMaxZoomScale:8.0];
        [docViewController setAutoMode:MFDocumentAutoModeDouble];
        [docViewController setAutomodeOnRotation:YES];
    
        [self.navigationController pushViewController:docViewController animated:YES];
    }
}

-(OverlayManager *)overlayManager {
    if(_overlayManager) {
        _overlayManager = [OverlayManager new];
    }
    return _overlayManager;
}

-(void)openFilename:(NSString *)filename 
{    
    NSURL * url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"pdf"];
    
    [self openURL:url];
}

+(NSString *)multimediaFolder:(MultimediaDocument *)document
{    
    static NSString * multimediaFolder = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!multimediaFolder) {
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString* libraryPath = [paths objectAtIndex:0];
            NSString * multimediaPath = [libraryPath stringByAppendingPathComponent:@"Multimedia"];
            multimediaFolder = [[multimediaPath stringByAppendingPathComponent:document.identifier]copy];
        }
    });
    
    return multimediaFolder;
}

+(NSString *)multimediaDocumentPath:(MultimediaDocument *)document
{    
    return [[MenuViewController multimediaFolder:document] stringByAppendingPathComponent:document.document];
}

-(IBAction)actionUnarchiveDefaultMultimedia:(id)sender {
    [self actionUnarchiveDocument:[MenuViewController defaultMultimediaDocument]];
}

-(IBAction)actionOpenDefaultMultimedia:(id)sender {
    [self actionOpenMultimedia:[MenuViewController defaultMultimediaDocument]];
}

-(void)actionUnarchiveDocument:(MultimediaDocument *)document
{    
    NSString * archivePath = [document.URL path];
    NSString * unarchivePath = [MenuViewController multimediaFolder:document];
    
    if([SSZipArchive unzipFileAtPath:archivePath toDestination:unarchivePath]) 
    {
        UIAlertView * view = [[UIAlertView alloc]initWithTitle:@"WIN!" message:@"Archive successfully deflated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [view show];
    } 
    else 
    {
        UIAlertView * view = [[UIAlertView alloc]initWithTitle:@"FAIL!" message:@"Failed to deflate the archive." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [view show];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if([UIAlertController class]) {
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Image saved" message:@"Thumbnail image saved to photo gallery." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        UIAlertView * view = [[UIAlertView alloc]initWithTitle:@"Image saved" message:@"Thumbnail image saved to photo gallery." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [view show];
    }
}

-(void)actionThumbnail:(Document *)document {
    
    MFDocumentManager * documentManager = [[MFDocumentManager alloc]initWithFileUrl:document.URL];
    CGImageRef image = [documentManager createImageForThumbnailOfPageNumber:1 ofSize:CGSizeMake(300, 400) andScale:[[UIScreen mainScreen]scale]];
    
    UIImage * outputImage = [UIImage imageWithCGImage:image];
    
    CGImageRelease(image);
    
    UIImageWriteToSavedPhotosAlbum(outputImage,
                                   self,
                                   @selector(image:didFinishSavingWithError:contextInfo:),
                                   NULL);
    
//    NSString * documentPath = [[NSBundle mainBundle]pathForResource:kPDFReferenceFilename ofType:@"pdf"];
//    NSURL * url = [NSURL fileURLWithPath:documentPath];
//    
//    MFDocumentManager * manager = [[MFDocumentManager alloc]initWithFileUrl:url];
//    
//    CGImageRef image = [manager createImageForThumbnailOfPageNumber:1 ofSize:CGSizeMake(240, 360) andScale:[UIScreen mainScreen].scale];
//    
//    CGFloat width = CGImageGetWidth(image);
//    CGFloat height = CGImageGetHeight(image);
//    NSLog(@"Thumbnail sieze %.2f x %.2f", width, height);
//    
//    CGImageRelease(image);
}

-(void)actionOpenMultimedia:(MultimediaDocument *)document
{    
    NSString * documentPath = [MenuViewController multimediaDocumentPath:document];
    NSURL * documentURL = [NSURL fileURLWithPath:documentPath];
    
    MFDocumentManager * documentManager = [[MFDocumentManager alloc]initWithFileUrl:documentURL];
    documentManager.resourceFolder = [MenuViewController multimediaFolder:document];
    documentManager.alternateURISchemesEnabled = YES;
    documentManager.conservativeMemoryUsage = true;
    documentManager.conservativeMemoryUsageHint = 50 * 1024 * 1024;
    
    FPKBaseEmbeddedAnnotationURIHandler * uriHandler = documentManager.embeddedAnnotationURIHandler;
    NSSet * newWebPrefixes = [[uriHandler.remoteWebPrefixes mutableCopy]setByAddingObjectsFromArray:@[@"pool://"]];
    uriHandler.remoteWebPrefixes = newWebPrefixes;
    
    ReaderViewController * docViewController = [[ReaderViewController alloc]initWithDocumentManager:documentManager];
    docViewController.pageFlipOnEdgeTouchEnabled = NO;
    
    //docViewController.supportedEmbeddedAnnotations = FPKEmbeddedAnnotationsVideo|FPKEmbeddedAnnotationsWeb; // Default: ALL
    
    FPKAnnotationDrawableDataSource * annotationDS = [FPKAnnotationDrawableDataSource new];
    annotationDS.documentManager = documentManager;
    [docViewController addOverlayDataSource:annotationDS];
    
    
    OverlayManager *overlayManager = [[OverlayManager alloc] init];
    
    /** Add the FPKOverlayManager as OverlayViewDataSource to the ReaderViewController */
    [docViewController addOverlayViewDataSource:overlayManager];
    //[docViewController addOverlayViewDataSource:self.testOverlayViewDataSource]; // Add test overlay views
    
    /** Register as DocumentDelegate to receive tap */
    [docViewController addDocumentDelegate:overlayManager];
    
    /** Set the DocumentViewController to obtain access the the conversion methods */
    [overlayManager setDocumentViewController:(MFDocumentViewController <FPKOverlayManagerDelegate> *)docViewController];
    
    docViewController.documentId = document.identifier;
    
    [docViewController setAutoMode:MFDocumentAutoModeDouble];
    
    [docViewController setAutomodeOnRotation:NO];
    [docViewController setMode:MFDocumentModeOverflow];
    
    [[self navigationController]pushViewController:docViewController animated:NO];
}

#pragma mark - UIViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithUnsignedInteger:FPKImageCacheScaleTrueToPixels] forKey:@"FPKImageCacheScaling"];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

@end
