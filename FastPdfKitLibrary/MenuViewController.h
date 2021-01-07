//
//  MenuViewController.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TestOverlayViewDataSource;
@class TestOverlayDataSource;
@class TestOverlayViewDataSource2;
@class OverlayManager;

@interface Document : NSObject

@property(nonatomic, copy) NSString * filename;
@property(nonatomic, copy) NSString * name;
@property(nonatomic, copy) NSString * identifier;

+(Document *)documentWithFilename:(NSString *)filename;
+(NSArray *)documentsWithFilenames:(NSString **)filenames count:(NSUInteger)count;
-(NSURL *)URL;
@end

@interface MultimediaDocument : Document
@property (nonatomic, copy) NSString * document;

+(MultimediaDocument *)documentWithFilename:(NSString *)filename;
@end

@interface MenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView * tableView;

@property (nonatomic, strong) TestOverlayViewDataSource * testOverlayViewDataSource;
@property (nonatomic, strong) TestOverlayDataSource * testOverlayDataSource;
@property (nonatomic, strong) TestOverlayViewDataSource2 * testOverlayDataSource2;
@property (nonatomic, strong) OverlayManager *overlayManager;
@end
