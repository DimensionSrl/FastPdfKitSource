//
//  FPKTextAnnotation.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/24/12.
//
//

#import <Foundation/Foundation.h>
#import "FPKAnnotation.h"

@interface FPKTextAnnotation : FPKAnnotation

@property (nonatomic, copy) NSString * contents;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, readwrite) BOOL open;

@end
