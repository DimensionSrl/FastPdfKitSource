//
//  MFRemoteLinkAnnotation.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 8/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFAnnotation.h"

@interface MFRemoteLinkAnnotation : MFAnnotation

@property (readwrite, nonatomic) CGRect quadPointsRect;
@property (nonatomic, copy) NSString * destination;
@property (nonatomic, copy) NSString * document;
@property (nonatomic, readwrite) NSUInteger page;

@end