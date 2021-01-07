//
//  BookmarkViewController.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 8/27/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookmarkViewControllerDelegate.h"


@class DocumentViewController;

@interface BookmarkViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

-(IBAction)actionToggleMode:(id)sender;
-(IBAction)actionAddBookmark:(id)sender;
-(IBAction)actionDone:(id)sender;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *editBarButtonButton;
@property (nonatomic, weak) IBOutlet UITableView *bookmarksTableView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) NSMutableArray *bookmarks;

@property (nonatomic, weak) id<BookmarkViewControllerDelegate> delegate;

@property (nonatomic, readwrite) NSUInteger status;

@property (nonatomic, readwrite) BOOL attemptToConverOldBookmarks;

@end
