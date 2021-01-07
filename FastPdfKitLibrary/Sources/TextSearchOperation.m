//
//  MFSearchOperation.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/21/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "TextSearchOperation.h"
#import "MFDocumentManager.h"

@implementation TextSearchOperation
@synthesize page, searchTerm, delegate, document;
@synthesize profile;

-(void)main {
	
	// Allocate an autorelease pool.
	
    @autoreleasepool {
    
    // Get the result from the document.
    NSArray *searchResult = [document searchResultOnPage:page forSearchTerms:searchTerm];
        
	if(![self isCancelled]) {
		
		if([delegate respondsToSelector:@selector(handleSearchResult:)])
			[(NSObject *)delegate performSelectorOnMainThread:@selector(handleSearchResult:)
                                                   withObject:searchResult
                                                waitUntilDone:YES];
	}
    }
}

-(void)dealloc {

    self.delegate = nil;
	self.searchTerm = nil;
	self.document = nil;
    
    [super dealloc];
}

@end
