//
//  FPKDocumentWrapper.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 18/05/15.
//
//

#import "FPKDocumentWrapper.h"

@interface FPKDocumentWrapper() {
    CGPDFDocumentRef _document;
}

@property (nonatomic, strong) NSMutableDictionary * readyPages;

@end

@implementation FPKDocumentWrapper

-(void)drawPage:(NSUInteger)page context:(CGContextRef)context {

    if(!_document) {
        _document = CGPDFDocumentCreateWithURL(_documentURL);
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(_document, page);
    
    self.readyPages[@(page)] = @(YES);
}

@end
