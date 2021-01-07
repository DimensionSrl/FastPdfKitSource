//
//  MFLinkAnnotation.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 11/14/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFAnnotation.h"

@interface MFLinkAnnotation : MFAnnotation

@property (nonatomic, readwrite) NSUInteger destinationPage;
@property (nonatomic, readwrite) CGRect quadPointsRect;

@end
