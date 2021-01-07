//
//  TestOverlayViewDataSource.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 05/03/14.
//
//

#import "TestOverlayViewDataSource.h"

#define TAG_RED 11
#define TAG_GREEN 10
#define TAG_BLUE 12
#define TAG_PURPLE 13

@interface TestOverlayViewDataSource()

@property (nonatomic, strong) NSMutableArray * viewsByPage;
@property (nonatomic, strong) NSMutableDictionary * cache;
@property (nonatomic, strong) NSMutableArray * views;

@property (nonatomic, strong) UIView * viewA;
@property (nonatomic, strong) NSValue * viewAFrame;

@property (nonatomic, strong) UIView * viewB;
@property (nonatomic, strong) NSValue * viewBFrame;

@property (nonatomic, strong) UIView * viewC;
@property (nonatomic, strong) NSValue * viewCFrame;

@property (nonatomic, strong) UIView * viewD;
@property (nonatomic, strong) NSValue * viewDFrame;

@property (nonatomic, strong) UIView * viewE;
@property (nonatomic, strong) NSValue * viewEFrame;

@property (nonatomic, strong) UIView * viewF;
@property (nonatomic, strong) NSValue * viewFFrame;

@end

@interface ViewWrapper : NSObject
@property (nonatomic, strong) UIView * view;
@property (nonatomic, readwrite) CGRect frame;
@end

@implementation ViewWrapper

@end

@interface TestView : UIView
@property (weak, nonatomic) UILabel * title;
@end

@implementation TestView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    {
        
        UIView * centerView = [UIView new];
        centerView.frame = CGRectInset(CGRectMake(0, 0, frame.size.width, frame.size.height), 10, 10);
        centerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        centerView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        [self addSubview:centerView];
        
        UILabel * label = [UILabel new];
        self.title = label;
        label.frame = CGRectInset(CGRectMake(0, 0, frame.size.width, frame.size.height), 10, 10);
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        label.adjustsFontSizeToFitWidth = true;
        [self addSubview:label];
        
        /*
        NSMutableArray * constraints = [NSMutableArray new];
        
        NSDictionary * views = @{@"c":centerView,@"l":label};
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[c]-|" options:0 metrics:nil views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[c]-|" options:0 metrics:nil views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-|" options:0 metrics:nil views:views]];
        
        [self addConstraints:constraints];
         */
    }
    
    return self;
}

@end


@implementation TestOverlayViewDataSource

-(id)init
{
    self = [super init];
    if(self)
    {
        self.cache = [NSMutableDictionary dictionary];
     
        NSMutableArray * oddViews = [NSMutableArray new];
        
        /*
        CGRect viewAFrame = CGRectMake(0, 0, 200, 200);
        UIView * viewA = [[TestView alloc]initWithFrame:viewAFrame];
        viewA.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
*/
        
        ViewWrapper * wrapperA = [ViewWrapper new];
        wrapperA.frame = CGRectMake(0, 0, 200, 200);
        TestView * testViewA = [[TestView alloc]initWithFrame:wrapperA.frame];
        testViewA.title.text = NSStringFromCGRect(wrapperA.frame);
        wrapperA.view = testViewA;
        wrapperA.view.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
        [oddViews addObject:wrapperA];
        
        ViewWrapper * wrapperB = [ViewWrapper new];
        wrapperB.frame = CGRectMake(200, 150, 50, 50);
        
        TestView * testViewB = [[TestView alloc]initWithFrame:wrapperB.frame];
        testViewB.title.text = NSStringFromCGRect(wrapperB.frame);
        wrapperB.view = testViewB;
        wrapperB.view.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
        [oddViews addObject:wrapperB];
        
        ViewWrapper * wrapperC = [ViewWrapper new];
        wrapperC.frame = CGRectMake(50, 400, 100, 100);
        TestView * testViewC = [[TestView alloc]initWithFrame:wrapperC.frame];
        testViewC.title.text = NSStringFromCGRect(wrapperC.frame);
        wrapperC.view = testViewC;
        wrapperC.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        [oddViews addObject:wrapperC];
        
        self.cache[@(1)] = oddViews;
        
        NSMutableArray * evenViews = [NSMutableArray new];
        ViewWrapper * wrapperD = [ViewWrapper new];
        wrapperD.frame = CGRectMake(300, 300, 100, 100);
        wrapperD.view = [[TestView alloc]initWithFrame:wrapperD.frame];
        wrapperD.view.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
        [evenViews addObject:wrapperD];
        
        ViewWrapper * wrapperE = [ViewWrapper new];
        wrapperE.frame = CGRectMake(50, 50, 200, 200);
        wrapperE.view = [[TestView alloc]initWithFrame:wrapperE.frame];
        wrapperE.view.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
        [evenViews addObject:wrapperE];
        
        self.cache[@(0)] = evenViews;
        
    }
    return self;
}

-(NSArray *)viewsAtPage2:(NSUInteger)page {
    
    if(page == 0) {
        return @[];
    }
    
    if(page % 2 == 0) {
     
        TestView * view = [[TestView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.title.text = NSStringFromCGRect(CGRectMake(100, 100, 200, 200));
        view.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
        view.tag = TAG_GREEN;
        
        TestView * viewB = [[TestView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
        viewB.title.text = @"BL";
        viewB.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];
        viewB.tag = TAG_BLUE;
        
        return @[view, viewB];
        
    } else {

        TestView * view = [[TestView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
        view.title.text = NSStringFromCGRect(CGRectMake(200, 200, 100, 100));
        view.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        view.tag = TAG_RED;
        
        TestView * viewB = [[TestView alloc]initWithFrame:CGRectMake(300, 500, 20, 20)];
        viewB.title.text = @"UR";
        viewB.backgroundColor = [UIColor colorWithRed:0.5 green:0.0 blue:1.0 alpha:0.5];
        viewB.tag = TAG_PURPLE;
        
        return @[view, viewB];
    }
}

-(NSArray *)viewsAtPage:(NSUInteger)page
{
    NSMutableArray * views = [NSMutableArray new];
    
    NSArray * cachedViews = self.cache[@(page%2)];
    
    for(ViewWrapper * wrapper in cachedViews) {
        [views addObject:wrapper.view];
    }
    
    return views;
}

#pragma mark - FPKOverlayViewDataSource

-(NSArray *)documentViewController:(MFDocumentViewController *)dvc overlayViewsForPage:(NSUInteger)page
{
    return [self viewsAtPage2:page];
}

-(CGRect)documentViewController:(MFDocumentViewController *)dvc frameForOverlayView:(UIView *)view onPage:(NSUInteger)page {
    switch(view.tag) {
        case TAG_GREEN:
            return CGRectMake(100, 100, 200, 200);
    }
    return CGRectNull;
}

-(CGRect)documentViewController:(MFDocumentViewController *)dvc
             rectForOverlayView:(UIView *)view
                         onPage:(NSUInteger)page
{
    
    switch(view.tag) {
       
        case TAG_PURPLE:
            return CGRectMake(300, 500, 20, 20);
        case TAG_RED:
            return CGRectMake(200, 200, 100, 100);
        case TAG_BLUE:
            return CGRectMake(0, 0, 20, 20);
    }
    
    return CGRectNull;
}

-(void)documentViewController:(MFDocumentViewController *)dvc
           willAddOverlayView:(UIView *)view
{
    // Do nothing.
}

-(void)documentViewController:(MFDocumentViewController *)dvc
            didAddOverlayView:(UIView *)view
{
    // Do nothing.
}

-(void)documentViewController:(MFDocumentViewController *)dvc
        willRemoveOverlayView:(UIView *)view
{
    // Do nothing.
}

-(void)documentViewController:(MFDocumentViewController *)dvc
         didRemoveOverlayView:(UIView *)view
{
    // Do nothing.
}

@end
