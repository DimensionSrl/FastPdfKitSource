//
//  MFPDFOutline.m
//  PDFOutlineTest
//
//  Created by Nicolò Tosi on 5/16/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFPDFOutline.h"
#import "MFPDFOutlineEntry.h"
#import "MFPDFUtilities.h"
#import "MFPDFOutlineRemoteEntry.h"

@implementation MFPDFOutline

NSUInteger pageNumberForLink(CGPDFDocumentRef document, CGPDFDictionaryRef link);

void findTypeOfObjectType(CGPDFObjectType type) {
	
	switch(type) {
		case kCGPDFObjectTypeName : NSLog(@"Name"); break;
		case kCGPDFObjectTypeString : NSLog(@"String"); break;
		case kCGPDFObjectTypeStream : NSLog(@"Stream"); break;
		case kCGPDFObjectTypeReal : NSLog(@"Real"); break;
		case kCGPDFObjectTypeArray : NSLog(@"Array"); break;
		case kCGPDFObjectTypeDictionary : NSLog(@"Dictionary"); break;
		case kCGPDFObjectTypeBoolean : NSLog(@"Boolean"); break;
		case kCGPDFObjectTypeInteger : NSLog(@"Integer"); break;
		case kCGPDFObjectTypeNull : NSLog(@"Null"); break;
		default : NSLog(@"Unknow");
	}
}

void traverseNameTree(CGPDFDictionaryRef node, size_t indent) {
	
	CGPDFArrayRef limits;
	if(CGPDFDictionaryGetArray(node, "Limits", &limits)) {
		
		CGPDFStringRef lowerLimit;
		CGPDFStringRef upperLimit;
		
		if((CGPDFArrayGetString(limits, 0, &lowerLimit))&&(CGPDFArrayGetString(limits, 1, &upperLimit))) {
		
			CFStringRef lls = CGPDFStringCopyTextString(lowerLimit);
			CFStringRef uls = CGPDFStringCopyTextString(upperLimit);
			
			size_t index;
			NSString * tmp = @"";
			for(index = 0; index < indent; index++) {
				tmp = [tmp stringByAppendingString:@"\t"];
			}
			tmp = [tmp stringByAppendingFormat:@"%@ <= x <= %@",lls,uls];
			NSLog(@"%@",tmp);
			
			CFRelease(lls);
			CFRelease(uls);
		}
	}
	
	CGPDFArrayRef kids;
	if(CGPDFDictionaryGetArray(node, "Kids", &kids)) {
	
		size_t count = CGPDFArrayGetCount(kids);
		size_t index;
		
		for (index = 0; index < count; index++) {
			
			CGPDFDictionaryRef kid;
			if(CGPDFArrayGetDictionary(kids, index, &kid)) {
					
				traverseNameTree(kid,indent+1);
				
			}
		}
	}
}

void traverseOutline(CGPDFDocumentRef document, CGPDFDictionaryRef entry, NSUInteger indent, NSMutableArray * container, CGPDFDictionaryRef catalog) {
	
	
	MFPDFOutlineEntry	* bookmark = nil;
	CFStringRef titleString = NULL;
    
    CGPDFStringRef	title = NULL;
    
	// If has title, is a valid outline entry
	if(CGPDFDictionaryGetString(entry, "Title", &title)) {
        
		titleString = CGPDFStringCopyTextString(title);
        
        CGPDFObjectRef	destination = NULL;
		CGPDFDictionaryRef action = NULL;
		
		NSUInteger		pageNumber = 0;
		
		bookmark = [[MFPDFOutlineEntry alloc]initWithTitle:(__bridge NSString *)titleString];
		[bookmark setIndentation:indent];
        
		// Obtain the Destination object (a Dictionary) from either the action dictionary under the A entry
		// or directly from the Dest entry
		if (CGPDFDictionaryGetDictionary(entry, "A", &action)) {
            
            // fprintf(stdout,"\tAction\n");
            
			const char * actionName = NULL; // Must be "GoTo" or "GoToR"
			
			if(CGPDFDictionaryGetName(action, "S", &actionName)) {
                
                // NSLog(@"%s", actionName);
                
                if ((strcmp(actionName, "GoTo")==0)) {
                    
                    if(CGPDFDictionaryGetObject(action, "D", &destination)) {
                        
                        pageNumber = pageNumberForDestination(document, destination);
                        [bookmark setPageNumber:pageNumber];
                    }
                    
                }
                else if ((strcmp(actionName, "GoToR")==0)) {
                    
                    CGPDFDictionaryRef fileSpecification = NULL;
                    CFStringRef destinationName = NULL;
                    CFStringRef fileName = NULL;
                    NSUInteger pageNumber = 0;
                    
                    if(CGPDFDictionaryGetDictionary(action, "F", &fileSpecification)) {
                        
                        // parseDictionary(fileSpecification);
                        CGPDFStringRef f = NULL;
                        
                        if(CGPDFDictionaryGetString(fileSpecification, "F", &f)) {
                            fileName = CGPDFStringCopyTextString(f);
                        }
                    }
                    
                    if(CGPDFDictionaryGetObject(action, "D", &destination)) {
                        
                        destinationName = createDestinationNameForDestination(document, destination, &pageNumber);
					}
                    
                    // Release the old bookmark and replace it with an MFPDFOutlineRemoteEntry
                    
                    if(bookmark) {
                        bookmark = nil;
                    }
                    bookmark = [[MFPDFOutlineRemoteEntry alloc]initWithTitle:(__bridge NSString *)titleString];
                    [bookmark setIndentation:indent];
                    
                    if(destinationName) {
                        
                        [(MFPDFOutlineRemoteEntry *)bookmark setDestination:(__bridge NSString *)destinationName];
                    }
                    else {
                        
                        [bookmark setPageNumber:pageNumber];
                    }
                    
                    [(MFPDFOutlineRemoteEntry *)bookmark setFile:(__bridge NSString *) fileName];
                    
                    // Cleanup.
                    
                    if(fileName)
                        CFRelease(fileName);
                    if(destinationName)
                        CFRelease(destinationName);
                    
                }
                else if ((strcmp(actionName, "Named") == 0)) {
                    
                    // Future support.
                    
                }
                else if ((strcmp(actionName, "Launch") == 0)) {
                    
                    CGPDFObjectRef fileSpecificationObj = NULL;
                    CGPDFDictionaryRef fileSpecDictionary = NULL;
                    CGPDFObjectRef fileNameObj = NULL;
                    BOOL application = NO;
                    BOOL print = NO;
                    CGPDFObjectRef optionObj = NULL;
                    
                    if(CGPDFDictionaryGetObject(action, "Win", &fileSpecificationObj)) {
                        
                        
                        if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                            
                            /*
                             Check if there are application parameter. If yes
                             it is an application launch request and will be
                             ignored.
                             */
                            if(CGPDFDictionaryGetObject(fileSpecDictionary, "P", NULL)) {
                                application = YES;
                            }
                            
                            /*
                             Check if there is an option parameter. If yes, ensure
                             that's the value is 'open'.
                             */
                            if(CGPDFDictionaryGetObject(fileSpecDictionary, "O", &optionObj)) {
                                
                                if (CGPDFObjectGetType(optionObj) == kCGPDFObjectTypeString) {
                                    
                                    CGPDFStringRef optionString = NULL;
                                    CFStringRef option = NULL;
                                    
                                    if(CGPDFObjectGetValue(optionObj, kCGPDFObjectTypeString, &optionString)) {
                                        
                                        option = CGPDFStringCopyTextString(optionString);
                                        
                                        if(![((__bridge NSString *)option) compare:@"open" options:NSCaseInsensitiveSearch]) {
                                            print = YES;
                                        }
                                        
                                        if(option)
                                            CFRelease(option);
                                    }                                    
                                }
                            }
                            
                            /*
                             If it's not an application launch and it is not
                             a print action, try to parse the filename
                             */
                            if((!application) && (!print) && CGPDFDictionaryGetObject(fileSpecDictionary, "F", &fileNameObj)) {
                                
                                if(CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeName) {
                                    
                                    const char * fileName;
                                    if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeName, &fileName)) {
                                        
                                        if(bookmark) {
                                            bookmark = nil;
                                        }
                                        
                                        bookmark = [[MFPDFOutlineRemoteEntry alloc]initWithTitle:(__bridge NSString *)titleString];
                                        [bookmark setIndentation:indent];
                                        [(MFPDFOutlineRemoteEntry *)bookmark setFile:[NSString stringWithCString:fileName encoding:NSUTF8StringEncoding] ];
                                    }
                                    
                                    
                                }
                                else if (CGPDFObjectGetType(fileNameObj) == kCGPDFObjectTypeString) {
                                    
                                    CGPDFStringRef fileNameString = NULL;
                                    CFStringRef fileName = NULL;
                                    
                                    if(CGPDFObjectGetValue(fileNameObj, kCGPDFObjectTypeString, &fileNameString)) {
                                        
                                        fileName = CGPDFStringCopyTextString(fileNameString);
                                        
                                        if(bookmark) {
                                            bookmark = nil;
                                        }
                                        
                                        bookmark = [[MFPDFOutlineRemoteEntry alloc]initWithTitle:(__bridge NSString *)titleString];
                                        [bookmark setIndentation:indent];
                                        [(MFPDFOutlineRemoteEntry *)bookmark setFile:(__bridge NSString *)fileName];
                                        [bookmark setPageNumber:1];
                                        
                                        if(fileName)
                                            CFRelease(fileName);
                                    }
                                }
                            }
                        }
                        
                    }
                    else if (CGPDFDictionaryGetObject(action, "Unix", &fileSpecificationObj)) {
                        
                        // Not yet defined as of PDF Referece 1.7.
                        
                    }
                    else if (CGPDFDictionaryGetObject(action, "Mac", &fileSpecificationObj)) {
                        // Not yet defined as of PDF Referece 1.7.
                    }
                    else if (CGPDFDictionaryGetObject(action, "F", &fileSpecificationObj)) {
                        
                        // Required as fallback, likely to be the default.
                        
                        if(CGPDFObjectGetValue(fileSpecificationObj, kCGPDFObjectTypeDictionary, &fileSpecDictionary)) {
                            
                            
                            CGPDFStringRef fileNameString = NULL;
                            CFStringRef fileName = NULL;
                            
                            /*
                             Precedence to the UF entry, then F, and then Mac,
                             Unix and lastly DOS.
                             */
                            if(CGPDFDictionaryGetString(fileSpecDictionary, "UF", &fileNameString)) {
                                
                            }
                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "F", &fileNameString)) {
                                
                            }
                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "Mac", &fileNameString)) {
                                
                            }
                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "Unix", &fileNameString)) {
                                
                            }
                            else if (CGPDFDictionaryGetString(fileSpecDictionary, "DOS", &fileNameString)) {
                                
                            }
                            
                            /*
                             If we have a valid file name string, we can create
                             the outline entry.
                             */
                            if(fileNameString) {
                                
                                fileName = CGPDFStringCopyTextString(fileNameString);
                                
                                if(bookmark) {
                                    bookmark = nil;
                                }
                                
                                bookmark = [[MFPDFOutlineRemoteEntry alloc]initWithTitle:(__bridge NSString *)titleString];
                                [bookmark setIndentation:indent];
                                [(MFPDFOutlineRemoteEntry *)bookmark setFile:(__bridge NSString *)fileName];
                                [bookmark setPageNumber:1];
                                
                                if(fileName ) {
                                    CFRelease(fileName);
                                }
                            }
                        }
                    } // End of if 'F'
                }
			}
			
		} // End of A
        
        else if (CGPDFDictionaryGetObject(entry, "Dest", &destination)) {
            
            pageNumber = pageNumberForDestination(document, destination);
            [bookmark setPageNumber:pageNumber];
        }
		
		
		
        //fprintf(stdout,"\t-> page %d\n",pageNumber);
        
		
	} 	// end of Title entry processing
	
    
    if(bookmark)
        [container addObject:bookmark];
    
    // Current entry cleanup
   	if(titleString)
        CFRelease(titleString);
    
    
    // Now parse the children
    
	CGPDFDictionaryRef first;
	if(CGPDFDictionaryGetDictionary(entry, "First", &first)) {
		
		NSMutableArray * tmp = [[NSMutableArray alloc]init];
		
		traverseOutline(document,first,indent+1, tmp,catalog);
		
		[bookmark setBookmarks:[NSArray arrayWithArray:tmp]];
	}
	
	// Then breadth (sieblings)
	CGPDFDictionaryRef next;
	if(CGPDFDictionaryGetDictionary(entry, "Next", &next)) {
		
		traverseOutline(document,next,indent,container,catalog); // Same indent, same container
	}
	
	
}

+(NSMutableArray *)outlineForDocument:(CGPDFDocumentRef)document {
	
	NSMutableArray *array = [[NSMutableArray alloc]init];
		CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
		
		// Parse the dictionary here. Consider moving it to an NSOperation or background thread
		CGPDFDictionaryRef outlines;
		
		if(CGPDFDictionaryGetDictionary(catalog, "Outlines", &outlines)) {
			
			CGPDFDictionaryRef firstTopLevel;
			
			if(CGPDFDictionaryGetDictionary(outlines, "First", &firstTopLevel)) {
				//NSLog(@"Traversing outline");
				traverseOutline(document, firstTopLevel, 0, array, catalog);

			}
		}
	
	return array;
}


/*
-(NSArray *)visibleBookmarks {
	
	NSArray * openBookmarks;
	
	NSMutableArray * tmp = [[NSMutableArray alloc]init];
	
	[tmp addObjectsFromArray:bookmarks];
	
	for(MFPDFOutlineEntry * bookmark in bookmarks) {
		[bookmark addBookmarksToArray:tmp onlyIfOpen:YES];
	}
	openBookmarks = [NSArray arrayWithArray:tmp];
	return openBookmarks;
}
*/

/*
-(NSString *)description {
	
	NSMutableString * tmp = [[NSMutableString alloc]init];
	NSString * description;
	[tmp appendString:@"Outline\n"];
	
	for(MFPDFOutlineEntry * bookmark in bookmarks) {
	
		[tmp appendFormat:@"%@\n",[bookmark description]];
	
	}
	
	description = [NSString stringWithString:tmp];
	[tmp release];
	
	return description;
	
}
*/

/*
-(NSUInteger)openBookmarksCount {
	
	NSUInteger count = [bookmarks count];
	
	for(MFPDFOutlineEntry * bookmark in bookmarks) {
		count+= [bookmark numberOfVisibleChilds];
	}
	
	return count;
	
}
*/


@end
