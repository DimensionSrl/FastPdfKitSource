//
//  FPKChildViewControllerHelper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 15/12/14.
//
//

#import <Foundation/Foundation.h>

@class MFDocumentViewController;
@class MFDocumentManager;

@interface FPKChildViewControllersHelper : NSObject

-(NSArray *)childViewControllersForPage:(NSUInteger)page;

-(void)removeAllObjects;

@property (nonatomic,strong) MFDocumentManager * document;
@property (nonatomic,weak) MFDocumentViewController * documentViewController;
@property (nonatomic,readwrite) NSUInteger supportedEmbeddedAnnotations;
@end
