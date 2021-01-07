//
//  FPKAnnotationBuilder.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 25/11/15.
//
//

#import <Foundation/Foundation.h>


@class MFDocumentManager;
@class MFFPKAnnotation;
@interface FPKAnnotationBuilder : NSObject

/*!
 Return the appropriate annotation object for the given URI string.
 
 @return An annotation object, or nil if no valid annotation could be instantiated.
 */
-(MFFPKAnnotation *)annotationFromURI:(NSString *)uri rect:(CGRect)rect frame:(CGRect)frame;

@property (nonatomic, weak) MFDocumentManager * document;
@property (nonatomic, readwrite) BOOL multimediaAnnotationEnabled;

@end
