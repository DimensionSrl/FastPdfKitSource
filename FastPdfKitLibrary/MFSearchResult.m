//
//  MFSearchResult.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/25/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFSearchResult.h"


@implementation MFSearchResult
@synthesize page, searchItems;

-(id)initWithSearchItems:(NSArray *)someItems forPage:(NSUInteger)aPage {
	if((self = [super init])) {
		searchItems = [someItems copy];
		page = aPage;
	}
	return self;
}

-(NSUInteger)size {
	return [searchItems count];
}

-(void)dealloc {
	
	[searchItems release],searchItems = nil;
	
	[super dealloc];
}

@end
