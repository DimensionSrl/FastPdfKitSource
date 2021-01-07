//
//  UINavigationController+Orientation.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 13/06/14.
//
//

#import "UINavigationController+Orientation.h"

@implementation UINavigationController (Orientation)

-(BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
