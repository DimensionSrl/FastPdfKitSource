//
//  MFAudioAnnotation.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 4/10/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFFPKAnnotation.h"

@interface MFAudioAnnotation : MFFPKAnnotation
@property(nonatomic, copy) NSNumber * showView;
@property(nonatomic, copy) NSNumber * autoplay;
@property(nonatomic, copy) NSNumber * loop;
@end
