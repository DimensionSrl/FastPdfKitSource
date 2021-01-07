//
//  FPKLazyCalcs.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 09/12/14.
//
//

#import "FPKLazyCalcs.h"

@interface FPKLazyCalcsKey() {
    NSUInteger _hash;
}

@end

@implementation FPKLazyCalcsKey

-(NSUInteger)hash {
    NSUInteger hash = 37;
    hash = hash * 37 + _leftOrRight;
    hash = hash * 37 + _mode;
    hash = hash * 37 + (*(NSUInteger *)&_cropboxSize.width) + (*(NSUInteger *)&_cropboxSize.height);
    hash = hash * 37 + (*(NSUInteger *)&_boundsSize.width) + (*(NSUInteger *)&_boundsSize.height);
    return hash;
}

-(BOOL)isEqual:(id)object {
    if(!object)
        return NO;
    if(![object isKindOfClass:[FPKLazyCalcsKey class]])
        return NO;
    FPKLazyCalcsKey * other = (FPKLazyCalcsKey *)object;
    if(self.hash != [other hash])
        return NO;
    return YES;
}

@end
