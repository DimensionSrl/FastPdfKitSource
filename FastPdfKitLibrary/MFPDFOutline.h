//
//  MFPDFOutline.h
//  PDFOutlineTest
//
//  Created by Nicolò Tosi on 5/16/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface MFPDFOutline : NSObject {
	
}

+(NSMutableArray *)outlineForDocument:(CGPDFDocumentRef)document;

@end
