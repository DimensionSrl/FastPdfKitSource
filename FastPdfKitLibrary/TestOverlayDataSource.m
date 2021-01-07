//
//  TestOverlayDataSource.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/05/15.
//
//

#import "TestOverlayDataSource.h"
#import <CoreText/CoreText.h>

@implementation TestDrawable

-(BOOL)containsPoint:(CGPoint)point {
    return CGRectContainsPoint(_rect, point);
}

+(NSDictionary *)textAttributes {
    
    static NSDictionary * attrs = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        attrs = @{NSFontAttributeName:
                      [UIFont fontWithName:@"Helvetica-Bold" size:20.0],
                  NSForegroundColorAttributeName:[UIColor blackColor]
                  };
    });
    return attrs;
}

void drawArrow(CGContextRef ctx, CGColorRef color) {
    
    CGContextSaveGState(ctx);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0.0, 0.0);
    CGContextAddLineToPoint(ctx, 0, 10);
    CGContextAddLineToPoint(ctx, -2, 8);
    CGContextAddLineToPoint(ctx, 2, 8);
    CGContextAddLineToPoint(ctx, 0, 10);
    CGContextMoveToPoint(ctx, 0.0, 0.0);
    CGContextSetStrokeColorWithColor(ctx, color);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
}

float DEGREES_TO_RADIANS(float degs) {
    return degs * M_PI/180.0;
}

-(void)drawText:(NSString *)text position:(CGPoint)point context:(CGContextRef)context {
    
    if(!_text) {
        return;
    }
    
    CFStringRef string = (__bridge CFStringRef)text;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica", 12.0, &transform);
    
    CFStringRef keys[] = { kCTFontAttributeName };
    
    CFTypeRef values[] = { font };
    
    CFDictionaryRef attributes =
    
    CFDictionaryCreate(kCFAllocatorDefault, (const void**)&keys,
                       (const void**)&values, sizeof(keys) / sizeof(keys[0]),
                       &kCFTypeDictionaryKeyCallBacks,
                       &kCFTypeDictionaryValueCallBacks);
    
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault,
                                                                string,
                                                                attributes);
    
    CFRelease(attributes);
    CFRelease(font);
    
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    CFRelease(attrString);
    
    // Set text position and draw the line into the graphics context
    
    CGContextSetTextPosition(context, point.x, point.y);
    
    CTLineDraw(line, context);
    
    CFRelease(line);
}

-(void)drawInContext:(CGContextRef)ctx {
    
    CGContextSetStrokeColorWithColor(ctx, _color.CGColor);
    CGContextStrokeRect(ctx, _rect);
    
    CGContextSaveGState(ctx);
    
    CGContextTranslateCTM(ctx, _rect.origin.x, _rect.origin.y);
    CGContextSaveGState(ctx);
    drawArrow(ctx, [UIColor redColor].CGColor);
    CGContextRestoreGState(ctx);
    
    CGContextSaveGState(ctx);
    CGContextRotateCTM(ctx, DEGREES_TO_RADIANS(-90));
    drawArrow(ctx, [UIColor blueColor].CGColor);
    CGContextRestoreGState(ctx);

    [self drawText:_text position:CGPointMake(8, 8) context:ctx]; // Offset (8,8)
    
    CGContextRestoreGState(ctx);
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.color = [UIColor redColor];
        self.rect = CGRectMake(0, 0, 100, 100);
    }
    return self;
}

+(NSArray *)dummyDrawables {
    
    TestDrawable * d0 = [TestDrawable new];
    d0.color = [self randomColor];
    d0.text = NSStringFromCGRect(d0.rect);
    
    TestDrawable * d1 = [TestDrawable new];
    d1.rect = CGRectMake(300, 300, 50, 50);
    d1.text = NSStringFromCGRect(d1.rect);

    return @[d0, d1];
}

+(UIColor *)randomColor {
    int value = arc4random()%10;
    switch (value) {
        case 0:
            return [UIColor redColor];
        case 1:
            return [UIColor greenColor];
        case 2:
            return [UIColor blueColor];
        case 3:
            return [UIColor yellowColor];
        case 4:
            return [UIColor purpleColor];
        case 5:
            return [UIColor brownColor];
        case 6:
            return [UIColor cyanColor];
        case 7:
            return [UIColor magentaColor];
        case 8:
            return [UIColor orangeColor];
        default:
            return [UIColor blackColor];
    }
}

@end

@implementation TestOverlayDataSource


-(NSArray *)documentViewController:(MFDocumentViewController *)dvc drawablesForPage:(NSUInteger)page {
    return [TestDrawable dummyDrawables];
}

-(NSArray *)documentViewController:(MFDocumentViewController *)dvc touchablesForPage:(NSUInteger)page {
    return [TestDrawable dummyDrawables];
}

@end
