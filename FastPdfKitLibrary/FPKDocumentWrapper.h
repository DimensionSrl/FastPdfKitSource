//
//  FPKDocumentWrapper.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/05/15.
//
//

#import <Foundation/Foundation.h>

@interface FPKDocumentWrapper : NSObject

@property (nonatomic, readwrite) BOOL needsClear;
@property (nonatomic, copy) NSURL * documentURL;

-(void)drawPage:(NSUInteger)page context:(CGContextRef)context;

@end
