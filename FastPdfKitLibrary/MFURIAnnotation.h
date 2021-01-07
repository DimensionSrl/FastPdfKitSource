//
//  MFURIAnnotation.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 11/14/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFAnnotation.h"
#import "FPKURIAnnotation.h"

@interface MFURIAnnotation : MFAnnotation

@property (nonatomic, readwrite) CGRect quadPointsRect;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, readwrite,getter=isMap) BOOL map;

-(FPKURIAnnotation *)annotation;

@end
