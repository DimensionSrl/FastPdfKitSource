//
//  MFVideoAnnotation.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 3/15/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFFPKAnnotation.h"

@interface MFVideoAnnotation : MFFPKAnnotation
@property(nonatomic, copy) NSNumber * autoplay;
@property(nonatomic, copy) NSNumber * loop;
@property(nonatomic, copy) NSNumber * controls;
@end
