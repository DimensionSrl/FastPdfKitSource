//
//  FPKLazyCalcs.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 09/12/14.
//
//

#import <Foundation/Foundation.h>

@interface FPKLazyCalcsKey : NSObject
@property (nonatomic, readwrite) NSUInteger leftOrRight;
@property (nonatomic, readwrite) NSUInteger mode;
@property (nonatomic, readwrite) CGSize cropboxSize;
@property (nonatomic, readwrite) CGSize boundsSize;
@end

@interface FPKLazyCalcsData : NSObject
@property (nonatomic, readwrite) CGAffineTransform transform;
@property (nonatomic, readwrite) CGAffineTransform frame;
@end