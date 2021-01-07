//
//  MFScrollDetailView.m
//  OffscreenRendererTest
//
//  Created by Nicolò Tosi on 4/20/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFScrollDetailView.h"
#import "MFDocumentManager.h"
#import "FPKDetailView.h"
#import "Stuff.h"

@implementation MFScrollDetailView

- (id)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])) {

    }
	
    return self;
}


- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event 
{	
	if (![self isDragging]) {
        //[super touchesEnded:touches withEvent:event];
		[(UIScrollView *)self.delegate touchesEnded: touches withEvent:event];
        //[super touchesEnded: touches withEvent: event];
	}
	else {
		[super touchesEnded: touches withEvent: event];
	}
		
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    BOOL retVal = YES;
    if([(FPKDetailView *)self.delegate gesturesDisabled])
        retVal =  NO;
    else 
        retVal = YES;
    
    // NSLog(@"Should Begin %i", retVal);
    
    return retVal;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    BOOL retVal = YES;
    if([(FPKDetailView *)self.delegate gesturesDisabled])
        retVal =  NO;
    else 
        retVal = YES;
    
    // NSLog(@"Should Receive Touch %i", retVal);
    
    return retVal;
    
    // return NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
