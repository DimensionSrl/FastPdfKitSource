    //
//  BookmarkViewController.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 8/27/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "BookmarkViewController.h"
#import "FPKUserDefaultsBookmarkManager.h"
#import "FPKBookmark.h"
#import "ReaderViewController.h"
#import "FPKBookmarkTableViewCell.h"

#define STATUS_NORMAL 0
#define STATUS_EDITING 1

static NSUInteger const FPKBookmarkStatusNormal = STATUS_NORMAL;
static NSUInteger const FPKBookmarkStatusEditing = STATUS_EDITING;

static NSString * const cellId = @"FPKBookmarkCellId";

@interface BookmarkViewController()<FPKBookmarkTableViewCellDelegate>

@end

@implementation BookmarkViewController

-(void)saveBookmarks {
    
    NSString * documentId = [self.delegate documentId];
    
    FPKUserDefaultsBookmarkManager * bookmarkManager = [FPKUserDefaultsBookmarkManager defaultManager];
    [bookmarkManager saveBookmarks:self.bookmarks forDocumentId:documentId];
}

-(NSMutableArray *) loadBookmarks {
    
    NSString * documentId = [self.delegate documentId];
    
    FPKUserDefaultsBookmarkManager * bookmarkManager = [FPKUserDefaultsBookmarkManager defaultManager];
    
    NSArray * bookmarks = [bookmarkManager loadBookmarksForDocumentId:documentId];
    
    if(bookmarks.count > 0 && [bookmarks[0] isKindOfClass:[NSNumber class]] && self.attemptToConverOldBookmarks) {
        
        NSArray * oldBookmarks = bookmarks;
        
        bookmarks = [BookmarkViewController convertOldBookmarksToNewBookmarks:oldBookmarks];
    }
    
    if(bookmarks) {
        
        return [bookmarks mutableCopy];
    }
    
    return [NSMutableArray array];
}

/**
 * This method will attempt to recover old bookmarks that were saved as NSNumber in an NSArray
 * in UserDefaults with a key string in the form "bookmarks_<DOCUMENT_ID>".
 * @param documentId The document id.
 * @return An NSArray if an array is found, nil otherwise.
 */
-(NSArray *)attemptToLoadOldBookmarksForDocumentId:(NSString *)documentId {

    NSString * oldKey = [NSString stringWithFormat:@"bookmarks_%@", documentId];
    id object = [[NSUserDefaults standardUserDefaults]objectForKey:oldKey];
    if([object isKindOfClass:[NSArray class]]) {
        return (NSArray *)object;
    }
    
    return nil;
}

/**
 * This method will convert the old bookmarks, expected to be an array of NSNumber,
 * to the new bookmarks, an array of FPKBookmark.
 * @param oldBookmarks An array of NSNumber.
 * @return An array of FPKBookmark.
 */
+(NSArray *)convertOldBookmarksToNewBookmarks:(NSArray *)oldBookmarks {
    
    NSMutableArray * newBookmarks = [NSMutableArray array];
    for(id oldBookmark in oldBookmarks) {
        if([oldBookmark isKindOfClass:[NSNumber class]]) {
            NSNumber * pageNumber = (NSNumber *)oldBookmark;
            NSString * title = @"";
            FPKBookmark * newBookmark = [FPKBookmark newBookmarkWithPageNumber:pageNumber title:title];
            [newBookmarks addObject:newBookmark];
        }
    }
    
#if DEBUG
    NSLog(@"%d old bookmarks have been converted to %d new bookmarks", oldBookmarks.count, newBookmarks.count);
#endif
    
    return newBookmarks;
}


-(void)enableEditing {

    [self.bookmarksTableView setEditing:YES animated:YES];
    self.status = FPKBookmarkStatusEditing;
}

-(void)disableEditing {
    
    [self.bookmarksTableView setEditing:NO animated:YES];
    self.status = FPKBookmarkStatusNormal;
}

-(IBAction)actionDone:(id)sender {

	if(self.status == STATUS_EDITING)
		[self disableEditing];
    
	[self saveBookmarks];
       
	[[self delegate] dismissBookmarkViewController:self];
}

-(IBAction)actionToggleMode:(id)sender {

	if(self.status == FPKBookmarkStatusNormal) {
		
		[self enableEditing];
        
	} else if (self.status == FPKBookmarkStatusEditing) {
		[self disableEditing];
	}
}

-(IBAction)actionAddBookmark:(id)sender {
	
	NSUInteger currentPage = [self.delegate page];
	
    FPKBookmark * bookmark = [FPKBookmark newBookmarkWithPageNumber:@(currentPage) title:nil];
    
    [self.bookmarks addObject:bookmark];
	
    [self saveBookmarks];
    
	[self.bookmarksTableView reloadData];
}

#pragma mark UIViewController

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
		self.status = FPKBookmarkStatusNormal;
        self.attemptToConverOldBookmarks = YES;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.bookmarks = [self loadBookmarks];
    
    UINib * nib = [UINib nibWithNibName:@"FPKBookmarkTableViewCell" bundle:nil];
    [self.bookmarksTableView registerNib:nib forCellReuseIdentifier:cellId];
    
    [self.bookmarksTableView reloadData];
}

-(NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - FPKBookmarkTableViewCellDelegate

-(void)bookmarkTableViewCell:(FPKBookmarkTableViewCell *)cell
                 didEditText:(NSString *)text
                    bookmark:(FPKBookmark *)bookmark
{    
    bookmark.title = text;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if(!tableView.isEditing) {
    FPKBookmark * bookmark = self.bookmarks[indexPath.row];
    NSUInteger page = bookmark.pageNumber.unsignedIntegerValue;
    
	[self.delegate bookmarkViewController:self didRequestPage:page];
    }
}

-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSUInteger index = indexPath.row;
		[self.bookmarks removeObjectAtIndex:index];
        
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	
	NSInteger count = [self.bookmarks count];
	return count;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    FPKBookmark * bookmark = self.bookmarks[indexPath.row];
	
	FPKBookmarkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    cell.bookmark = bookmark;
    cell.delegate = self;
	return cell;
}

@end
