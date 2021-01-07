//
//  TestOverlayViewDataSource2.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 01/07/15.
//
//

#import "TestOverlayViewDataSource2.h"

@implementation TestOverlayViewDataSource2

-(NSArray *)documentViewController:(MFDocumentViewController *)dvc
               overlayViewsForPage:(NSUInteger)page
{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    view.backgroundColor = [UIColor greenColor];
    return @[view];
}

-(CGRect)documentViewController:(MFDocumentViewController *)dvc
             rectForOverlayView:(UIView *)view
                         onPage:(NSUInteger)page
{
    return CGRectNull;
}

@end
