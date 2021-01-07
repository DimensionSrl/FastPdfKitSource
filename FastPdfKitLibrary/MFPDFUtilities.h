/*
 *  MFPDFUtilities.h
 *  FastPDFKitTest
 *
 *  Created by Nicolò Tosi on 11/14/10.
 *  Copyright 2010 MobFarm S.r.l. All rights reserved.
 *
 */
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

NSUInteger pageNumberForLink(CGPDFDocumentRef document, CGPDFDictionaryRef link);
NSUInteger pageNumberForDestination(CGPDFDocumentRef document, CGPDFObjectRef destination);
NSUInteger pageNumberForDestinationNamed(CGPDFDocumentRef document, NSString * destinationName);

void valueForNameInNameTreeNode(CFStringRef name, CGPDFDictionaryRef node, CGPDFObjectRef * value);
CGRect rectFromRectangleArray(CGPDFArrayRef rectangle);
void codeSequenceFromString(CGPDFStringRef string, unsigned char ** sequence, int * length);
CFStringRef createDestinationNameForDestination(CGPDFDocumentRef document, CGPDFObjectRef destination, NSUInteger * fallbackPageNumber);

void parseDictionary(CGPDFDictionaryRef dictionary);
char * objectGetType(CGPDFObjectRef object);

@interface MFPDFObjectParser : NSObject {
 
    NSMutableArray * storage;      // Retains parsed objects
    CFMutableDictionaryRef cache;  // Contains {CGPDF objects, Cocoa objects} pairs
    id object;              // The top level object that will be returned by the parser
}

@property (nonatomic, strong) NSMutableArray * storage;
@property (nonatomic, strong) id object;

+(MFPDFObjectParser *)parser;
-(id)parse:(CGPDFObjectRef)obj;
-(id)objectForPDFObject:(CGPDFObjectRef) obj;

@end