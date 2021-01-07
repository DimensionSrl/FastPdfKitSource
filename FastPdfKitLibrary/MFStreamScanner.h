//
//  MFStreamScanner.h
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MFSearchResult;
@class MFTextState;

@interface MFStreamScanner : NSObject {

	CGPDFPageRef page;
	
	CGPDFOperatorTableRef operatorTable;
	
	NSMutableDictionary * fonts;
	NSMutableDictionary * fontCache;
    BOOL useCache;
	MFTextState *state;
}

-(id)initWithTextState:(MFTextState *)aSearchTerm andPage:(CGPDFPageRef)aPage;
-(void)scan;
@property (nonatomic,assign) BOOL useCache;
@property (nonatomic,retain) MFTextState * state;
@property (nonatomic,assign) NSMutableDictionary * fontCache;

@end
