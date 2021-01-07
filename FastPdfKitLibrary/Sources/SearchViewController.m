    //
//  MFSearchViewController.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/21/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "SearchViewController.h"
#import "FPKSearchMatchItem.h"
#import "MFDocumentManager.h"
#import "ReaderViewController.h"
#import "TextSearchOperation.h"
#import "SearchManager.h"
#import "SearchResultCellView.h"

#define ZOOM_LEVEL 4.0

@implementation SearchViewController

#pragma mark - Notification listeners

-(void)handleSearchResultsAvailableNotification:(NSNotification *)notification {
 
    NSDictionary * userInfo = notification.userInfo;
    
    NSArray * searchResult = userInfo[kNotificationSearchInfoResults];
    
    if(searchResult.count > 0) {
        
        [self.searchTableView reloadData];
    }
}

-(void)handleSearchDidStopNotification:(NSNotification *)notification {
    
    [self.cancelStopBarButtonItem setTitle:NSLocalizedString(@"SEARCH_CANCEL_BTN_TITLE", @"Cancel")];
	[self.activityIndicatorView stopAnimating];
}

-(void)handleSearchDidStartNotification:(NSNotification *)notification {
    
    // Clean up if there are old search results.
    
    [self.searchTableView reloadData];
		
	// Set up the view status accordingly.
	
	[self.cancelStopBarButtonItem setTitle:NSLocalizedString(@"SEARCH_STOP_BTN_TITLE", @"Stop")];
	[self.activityIndicatorView startAnimating];
    self.cancelStopBarButtonItem.enabled = YES;
    self.switchToMiniBarButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark Start and Stop

-(void)stopSearch {
	
	// Tell the manager to stop the search and let the delegate's methods to refresh this view.
    if(self.searchManager) {
        [self.searchManager stopSearch];
    }
}

-(void)startSearchWithTerm:(NSString *)aSearchTerm {
	
	// Create a new search manager with the search term
    SearchManager * searchManager = [SearchManager new];
    self.searchManager = searchManager;

    self.searchManager.searchTerm = aSearchTerm;
    self.searchManager.startingPage = [self.delegate pageForSearchViewController:self];
    self.searchManager.document = [self.delegate documentForSearchViewController:self];
    
    // Start the search
    [self.searchManager startSearch];
    
    // Inform the delegate of the search in progress
    [self.delegate searchViewController:self addSearch:self.searchManager];
}

-(void)cancelSearch {
	
	// Tell the manager to cancel the search and let the delegate's  methods to refresh this view.
    if(self.searchManager) {
        [self.searchManager stopSearch];
        [self.delegate searchViewController:self removeSearch:self.searchManager];
        self.searchManager = nil;
        [self.searchTableView reloadData];
    }
}

#pragma mark -
#pragma mark Actions

-(IBAction)actionCancelStop:(id)sender {
	
    if(!self.searchManager) {
        return; // Nothing to do here
    }
    
    // If the search is running, stop it. Otherwise, cancel the
    // search entirely.
    
    if(self.searchManager.running) {
        
        [self stopSearch];
        
    } else {
        
        [self cancelSearch];
    }
}

-(IBAction)actionBack:(id)sender {
	
	[[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)actionMinimize:(id)sender {
	
	// We are going to use the first item to initialize the mini view.
	
    NSIndexPath * visibleIndexPath = nil;
    
	FPKSearchMatchItem * firstItem = nil;
    
    NSArray * results = [self.searchManager allSearchResults];
    
    if(results.count > 0) {
        
        visibleIndexPath = [[self.searchTableView indexPathsForVisibleRows]objectAtIndex:0];
        firstItem = [[results objectAtIndex:visibleIndexPath.section] objectAtIndex:visibleIndexPath.row];
        
        if(firstItem!=nil) {
            
            [self.delegate searchViewController:self switchToMiniSearchView:firstItem];
        }
    }
}

#pragma mark - UISearchBarDelegate

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
	
	[searchBar resignFirstResponder];
	
	return YES;
}

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	
	// Dismiss the keyboard and cancel the search
	
	[searchBar resignFirstResponder];
	[self cancelSearch];
}

-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    // Get the search term from the search bar and start searching for it

	[searchBar resignFirstResponder];
    
    NSString * searchTerm = searchBar.text;
	[self startSearchWithTerm:searchTerm];
}

-(BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    [self cancelSearch];
    
    return YES;
}

#pragma mark - UITableViewDelegate and DataSource

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// Let's get the MFTextItem from its container array.
	
    NSArray *searchResult = self.searchManager.sequentialSearchResults[indexPath.section];
	FPKSearchMatchItem * item = [searchResult objectAtIndex:indexPath.row];
	
	// Dismiss this viewcontroller and tell the DocumentViewController to move to the selected page after
	// displaying the mini search view.
	
    [self.delegate searchViewController:self switchToMiniSearchView:item];
	
	[self.delegate searchViewController:self setPage:item.textItem.page withZoomOfLevel:ZOOM_LEVEL onRect:item.boundingBox];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellId = @"searchResultCellId";
	
	// Just costumize the cell with the content of the MFSearchItem for the right row in the right section.
	
    NSArray *searchResult = self.searchManager.sequentialSearchResults[indexPath.section];
	FPKSearchMatchItem *searchItem = [searchResult objectAtIndex:indexPath.row];
	
	// This is a custom view cell that display an MFTextItem directly.
	
	SearchResultCellView *cell = (SearchResultCellView *)[tableView dequeueReusableCellWithIdentifier:cellId];
	
	if(nil == cell) {
	
		// Simple initialization.
        cell = [[SearchResultCellView alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
	}
	
	[cell setTextSnippet:searchItem.textItem.text];
	[cell setPage:searchItem.textItem.page];
	[cell setBoldRange:searchItem.textItem.searchTermRange];
	
	return cell;
}

-(NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	
	// Nothing special here.
    NSArray *searchResult = self.searchManager.sequentialSearchResults[section];
    
	return [searchResult count];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	
	// Nothing special here.
    return self.searchManager.sequentialSearchResults.count;
}

#pragma mark UIViewController


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        
        self.switchToMiniBarButtonItem.enabled = NO;
        
        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleSearchDidStartNotification:) name:kNotificationSearchDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(handleSearchDidStopNotification:) name:kNotificationSearchDidStop object:nil];
        [notificationCenter addObserver:self selector:@selector(handleSearchResultsAvailableNotification:) name:kNotificationSearchResultAvailable object:nil];
	}
    return self;
}

-(void)viewWillAppear:(BOOL)animated {

	// Different setup if search is running or not.
	[super viewWillAppear:animated];
    
    self.searchManager = [self.delegate searchForSearchViewController:self]; // Retrieve the searh currently displayed
    
	if(self.searchManager.running) {
		
		[self.activityIndicatorView startAnimating];
		[self.cancelStopBarButtonItem setTitle:NSLocalizedString(@"SEARCH_STOP_BTN_TITLE", @"Stop")];
		
	} else {
	
		[self.cancelStopBarButtonItem setTitle:NSLocalizedString(@"SEARCH_CANCEL_BTN_TITLE", @"Cancel")];
	} 
	
	// Common setup.
	
    self.searchBar.text = self.searchManager.searchTerm;
	
	[self.searchTableView reloadData];
    
    if(self.searchManager.sequentialSearchResults.count <= 0) {
        [self.searchBar becomeFirstResponder];
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return YES;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
