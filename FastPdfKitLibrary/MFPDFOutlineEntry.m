//
//  MFPDFBookmark.m
//  PDFOutlineTest
//
//  Created by Nicolò Tosi on 5/16/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFPDFOutlineEntry.h"

@implementation MFPDFOutlineEntry

@synthesize indentation, pageNumber, bookmarks;
@synthesize title;

-(id)initWithTitle:(NSString *)aTitle {
	if((self = [super init])) {
		[self setTitle:aTitle];
	}
	return self;
}


@end
