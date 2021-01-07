//
//  TestTouchView.m
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TestTouchView.h"

@implementation TestTouchView
@synthesize coverBox;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    
    // Cover box is the box of the page that is covered by the overlay view. Is
    // the same value you return from -rectForOverlayView
    
    CGPoint pointInView = [touch locationInView:self];  // Point in overlay view coordinates
    
    CGPoint flippedPoint = CGPointMake(pointInView.x, (-pointInView.y) + self.bounds.size.height);  //
    
    
    // Now let's calculate the coordinate proportionally to our view size
    
    CGPoint percentagePoint = CGPointZero;
    percentagePoint.x = flippedPoint.x/self.bounds.size.width; // Range 0.0-1.0
    percentagePoint.y = flippedPoint.y/self.bounds.size.height; // Range 0.0-1.0
    
    
    // Since the view is matching a page cropbox (or a subset of it), it is easy
    // to convert the point from the view to page space
    
    CGPoint pagePoint = CGPointZero;
    pagePoint.x = percentagePoint.x * coverBox.size.width + coverBox.origin.x;
    pagePoint.y = percentagePoint.y * coverBox.size.height + coverBox.origin.y;
    
    NSLog(@"Touch at page point %@",NSStringFromCGPoint(pagePoint));
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setUserInteractionEnabled:YES];
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
