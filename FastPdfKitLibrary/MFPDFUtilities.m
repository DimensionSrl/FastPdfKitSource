/*
 *  MFPDFUtilities.c
 *  FastPDFKitTest
 *
 *  Created by Nicolò Tosi on 11/14/10.
 *  Copyright 2010 MobFarm S.r.l. All rights reserved.
 *
 */

#include "MFPDFUtilities.h"
#include <UIKit/UIKit.h>

#define LOG_PARSER 0

void objectForKeyInArray(CFStringRef key, CGPDFArrayRef array, CGPDFObjectRef * obj);
CGPDFDictionaryRef pageDictionaryForNameInNameTree(CFStringRef name, CGPDFDictionaryRef nameTree);
BOOL isNameInsideLimits(CGPDFArrayRef limits, CFStringRef name);

NSMutableArray *aRefImgs;

void setRefImgs(NSMutableArray *ref){
    aRefImgs=ref;
}

NSMutableArray* ImgArrRef(){
    return aRefImgs;
}

CGFloat* decodeValuesFromImageDictionary(CGPDFDictionaryRef dict, CGColorSpaceRef cgColorSpace, NSInteger bitsPerComponent) {
    
    CGFloat *decodeValues = NULL;
    CGPDFArrayRef decodeArray = NULL;
    
    if (CGPDFDictionaryGetArray(dict, "Decode", &decodeArray)) {
        size_t count = CGPDFArrayGetCount(decodeArray);
        decodeValues = malloc(sizeof(CGFloat) * count);
        CGPDFReal realValue;
        int i;
        for (i = 0; i < count; i++) {
            CGPDFArrayGetNumber(decodeArray, i, &realValue);
            decodeValues[i] = realValue;
        }
    } else {
        size_t n;
        switch (CGColorSpaceGetModel(cgColorSpace)) {
            case kCGColorSpaceModelMonochrome:
                decodeValues = malloc(sizeof(CGFloat) * 2);
                decodeValues[0] = 0.0;
                decodeValues[1] = 1.0;
                break;
            case kCGColorSpaceModelRGB:
                decodeValues = malloc(sizeof(CGFloat) * 6);
                for (int i = 0; i < 6; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0 : 1;
                }
                break;
            case kCGColorSpaceModelCMYK:
                decodeValues = malloc(sizeof(CGFloat) * 8);
                for (int i = 0; i < 8; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    1.0;
                }
                break;
            case kCGColorSpaceModelLab:
                // ????
                break;
            case kCGColorSpaceModelDeviceN:
                n =
                CGColorSpaceGetNumberOfComponents(cgColorSpace) * 2;
                decodeValues = malloc(sizeof(CGFloat) * (n *
                                                         2));
                for (int i = 0; i < n; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    1.0;
                }
                break;
            case kCGColorSpaceModelIndexed:
                decodeValues = malloc(sizeof(CGFloat) * 2);
                decodeValues[0] = 0.0;
                decodeValues[1] = pow(2.0,
                                      (double)bitsPerComponent) - 1;
                break;
            default:
                break;
        }
    }
    
    return (CGFloat *)CFMakeCollectable(decodeValues);
}

/*!
 Unused method to retrieve UIImage from a CGPDFStream representing an RAW or JPEG image.
 
 @param myStream The stream to decode.
 */
UIImage *getImageRef(CGPDFStreamRef myStream) {
    
    CGPDFArrayRef colorSpaceArray = NULL;
    CGPDFStreamRef dataStream;
    CGPDFDataFormat format;
    CGPDFDictionaryRef dict;
    CGPDFInteger width, height, bps, spp;
    CGPDFBoolean interpolation = 0;
    
    //  NSString *colorSpace = nil;
    
    CGColorSpaceRef cgColorSpace;
    const char *name = NULL, *colorSpaceName = NULL, *renderingIntentName = NULL;
    CFDataRef imageDataPtr = NULL;
    CGImageRef cgImage;
    
    //maskImage = NULL,
    
    CGImageRef sourceImage = NULL;
    CGDataProviderRef dataProvider;
    CGColorRenderingIntent renderingIntent;
    CGFloat *decodeValues = NULL;
    UIImage *image;
    
    if (myStream == NULL)
        return nil;
    
    dataStream = myStream;
    dict = CGPDFStreamGetDictionary(dataStream);
    
    // obtain the basic image information
    if (!CGPDFDictionaryGetName(dict, "Subtype", &name))
        return nil;
    
    if (strcmp(name, "Image") != 0)
        return nil;
    
    if (!CGPDFDictionaryGetInteger(dict, "Width", &width))
        return nil;
    
    if (!CGPDFDictionaryGetInteger(dict, "Height", &height))
        return nil;
    
    if (!CGPDFDictionaryGetInteger(dict, "BitsPerComponent", &bps))
        return nil;
    
    if (!CGPDFDictionaryGetBoolean(dict, "Interpolate", &interpolation))
        interpolation = NO;
    
    if (!CGPDFDictionaryGetName(dict, "Intent", &renderingIntentName))
        renderingIntent = kCGRenderingIntentDefault;
    else{
        renderingIntent = kCGRenderingIntentDefault;
        //      renderingIntent = renderingIntentFromName(renderingIntentName);
    }
    
    imageDataPtr = CGPDFStreamCopyData(dataStream, &format);
    dataProvider = CGDataProviderCreateWithCFData(imageDataPtr);
    CFRelease(imageDataPtr);
    
    if (CGPDFDictionaryGetArray(dict, "ColorSpace", &colorSpaceArray)) {
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        //      cgColorSpace = colorSpaceFromPDFArray(colorSpaceArray);
        spp = CGColorSpaceGetNumberOfComponents(cgColorSpace);
    } else if (CGPDFDictionaryGetName(dict, "ColorSpace", &colorSpaceName)) {
        if (strcmp(colorSpaceName, "DeviceRGB") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceRGB();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            spp = 3;
        } else if (strcmp(colorSpaceName, "DeviceCMYK") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceCMYK();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
            spp = 4;
        } else if (strcmp(colorSpaceName, "DeviceGray") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
            spp = 1;
        } else if (bps == 1) { // if there's no colorspace entry, there's still one we can infer from bps
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            //          colorSpace = NSDeviceBlackColorSpace;
            spp = 1;
        }
    }
    
    decodeValues = decodeValuesFromImageDictionary(dict, cgColorSpace, bps);
    
    int rowBits = bps * spp * width;
    int rowBytes = rowBits / 8;
    // pdf image row lengths are padded to byte-alignment
    if (rowBits % 8 != 0)
        ++rowBytes;
    
    //  maskImage = SMaskImageFromImageDictionary(dict);
    
    if (format == CGPDFDataFormatRaw)
    {
        sourceImage = CGImageCreate(width, height, bps, bps * spp, rowBytes, cgColorSpace, 0, dataProvider, decodeValues, interpolation, renderingIntent);
        CGDataProviderRelease(dataProvider);
        cgImage = sourceImage;
        //      if (maskImage != NULL) {
        //          cgImage = CGImageCreateWithMask(sourceImage, maskImage);
        //          CGImageRelease(sourceImage);
        //          CGImageRelease(maskImage);
        //      } else {
        //          cgImage = sourceImage;
        //      }
    } else {
        if (format == CGPDFDataFormatJPEGEncoded){ // JPEG data requires a CGImage; AppKit can't decode it {
            sourceImage =
            CGImageCreateWithJPEGDataProvider(dataProvider,decodeValues,interpolation,renderingIntent);
            CGDataProviderRelease(dataProvider);
            cgImage = sourceImage;
            //          if (maskImage != NULL) {
            //              cgImage = CGImageCreateWithMask(sourceImage,maskImage);
            //              CGImageRelease(sourceImage);
            //              CGImageRelease(maskImage);
            //          } else {
            //              cgImage = sourceImage;
            //          }
        }
        // note that we could have handled JPEG with ImageIO as well
        else if (format == CGPDFDataFormatJPEG2000) { // JPEG2000 requires ImageIO {
            CFDictionaryRef dictionary = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
            sourceImage=
            CGImageCreateWithJPEGDataProvider(dataProvider, decodeValues, interpolation, renderingIntent);
            
            
            //          CGImageSourceRef cgImageSource = CGImageSourceCreateWithDataProvider(dataProvider, dictionary);
            CGDataProviderRelease(dataProvider);
            
            cgImage=sourceImage;
            
            //          cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, dictionary);
            CFRelease(dictionary);
        } else // some format we don't know about or an error in the PDF
            return nil;
    }
    image=[UIImage imageWithCGImage:cgImage];
    return image;
}







//void codeSequenceFromUTF16BEString(CGPDFStringRef string unsigned short ** sequence, int * length) {
//
//	const unsigned char * bytes = CGPDFStringGetBytePtr(string);
//	int bytes_len = CGPDFStringGetLength(string);
//	
//	if(bytes_len == 0) {
//		*sequence = NULL;
//		*length = 0;
//		return;
//	}
//	
//	*sequence = calloc(bytes_len,sizeof(unsigned char));
//	
//}

char * objectGetType(CGPDFObjectRef object) {
    CGPDFObjectType type = CGPDFObjectGetType(object);
    char * typeName;
    switch(type) {
        case kCGPDFObjectTypeName:
            typeName = "Name";
            break;
        case kCGPDFObjectTypeInteger:
            typeName = "Integer";
            break;
        case kCGPDFObjectTypeArray:
            typeName = "Array";
            break;
        case kCGPDFObjectTypeBoolean:
            typeName = "Boolean";
            break;
        case kCGPDFObjectTypeDictionary:
            typeName = "Dictionary";
            break;
        case kCGPDFObjectTypeString:
            typeName = "String";
            break;
        case kCGPDFObjectTypeStream:
            typeName = "Stream";
            break;
        case kCGPDFObjectTypeReal:
            typeName = "Real";
            break;
        case kCGPDFObjectTypeNull:
            typeName = "Null";
            break;
            default: typeName = "Other";
    }
    return typeName;
}

void dictionaryParsingFunction(const char *key, CGPDFObjectRef value,void *info) {
    
    char * type;    
    type = objectGetType(value);
    fprintf(stdout,"Key %s of type %s\n",key,type);
    
//    CGPDFObjectType objType = CGPDFObjectGetType(value);
//    
//    if(objType == kCGPDFObjectTypeDictionary) {
//        
//        CGPDFDictionaryRef dictionary;
//        
//        if(CGPDFObjectGetValue(value, kCGPDFObjectTypeDictionary, &dictionary)) {
//            
//            if(dictionary == (CGPDFDictionaryRef) info) {
//                fprintf(stdout, "\tself reference");
//            } else {
//                parseDictionary(dictionary);
//            }
//        }
//    }
}


void parseDictionary(CGPDFDictionaryRef dictionary) {
 
    CGPDFDictionaryApplyFunction(dictionary, &dictionaryParsingFunction, dictionary);
}

void codeSequenceFromString(CGPDFStringRef string, unsigned char ** sequence, int * length) {
    
    const unsigned char * bytes = CGPDFStringGetBytePtr(string);
	int bytes_len = CGPDFStringGetLength(string);
	
    if(bytes_len == 0) {
		*sequence = NULL;
		*length = 0;
		return;
	}
    
    *length = bytes_len;
    *sequence = calloc(bytes_len,sizeof(unsigned char));
	memcpy(*sequence,bytes,bytes_len);
    
    /*
     OLD IMPLEMENTATION, BUT DO NOT DELETE!
	const unsigned char * bytes = CGPDFStringGetBytePtr(string);
	int bytes_len = CGPDFStringGetLength(string);
	
	if(bytes_len == 0) {
		*sequence = NULL;
		*length = 0;
		return;
	}
	
	*sequence = calloc(bytes_len,sizeof(unsigned char));
	
	
	unsigned char * bytes_ptr = bytes;
	unsigned char * sequence_ptr = *sequence;
	
	int processed_bytes_count = 0;
	int written_codes = 0;
	
    fprintf(stdout,"(");
    while(processed_bytes_count < bytes_len) {
        
        fprintf(stdout,"%02X",bytes_ptr[processed_bytes_count++]);
        
    }
    processed_bytes_count = 0;
    fprintf(stdout,") -> ");
	while(processed_bytes_count < bytes_len) {
		
		unsigned char byte = *bytes_ptr;
		if(byte!='\\') {
			
			if(byte == 015) { // CR
				
				// CR and CR+LF are handled as \n, thus write a single LF.
				
				unsigned char next = *(bytes_ptr+1);
				
				if(next == 012) { // CR + LF
					
					
					*sequence_ptr = 012;
					sequence_ptr++;
					written_codes++;
					
					bytes_ptr+=2;
					processed_bytes_count+=2;
					
				} else { // CR only
					
					*sequence_ptr = 012;
					sequence_ptr++;
					written_codes++;
					
					bytes_ptr++;
					processed_bytes_count++;
				}
				
			} else { // Simple char code.
				
				// Write the code to the sequence.
				
				*sequence_ptr = byte;
				
				// Move the pointers.
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr++;
				processed_bytes_count++;
			}
			
		} else {
			
			// Escape character found, look for the next byte.
			
			unsigned char following = *(bytes_ptr+1);
			
			if(following == 'n') {
				
				*sequence_ptr = 012; // LF.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == 'r') {
				
				*sequence_ptr = 015; // CR.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == 't') {
				
				*sequence_ptr = 011; // HT.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == 'b') {
				
				*sequence_ptr = 010; // BS.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == 'f') {
				
				*sequence_ptr = 014; // FF.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == '(') {
				
				*sequence_ptr = 050; // (.
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
				
			} else if (following == ')') {
				
				*sequence_ptr = 051; // ).
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
				
			} else if (following == '\\') {
				
				*sequence_ptr = '\\'; // \ (backslash).
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following <= '7' && following >= '0') {
				
				// Meh, handle octals.
				
				// Octals can be written with 1 to 3 digits.
				
				unsigned char octal_value;
				int bytes_processed;
				
				unsigned char next = *(bytes_ptr+2);
				
				if(next <= '7' && next >= '0') {
					
					unsigned char last = *(bytes_ptr+3);
					
					if(last <= '7' && last >= '0') {
						
						// Three digit octal (/following next last).
						
						octal_value = (unsigned char)((following-'0')*64+(next-'0')*8+(last-'0'));
						bytes_processed = 3;
						
					} else {
						
						// Two digit octal (/following next).
						octal_value = (unsigned char)((following-'0')*8+(next-'0'));
						bytes_processed = 2;
					}
					
				} else {
					
					// Single digit octal (/following).
					octal_value = (unsigned char)(following-'0');
					bytes_processed = 1;
				}
				
				// Write the octal and update the pointers/counters.
				*sequence_ptr = octal_value;
				
				sequence_ptr++;
				written_codes++;
				
				bytes_ptr+=(1+bytes_processed);
				processed_bytes_count+=(1+bytes_processed);
				
			} else if (following == 012) { // LF
				
				// Skip / and LF since it is not part of the string.
				
				bytes_ptr+=2;
				processed_bytes_count+=2;
				
			} else if (following == 015) { // CR
				
				// Skip / and CR or CR+LF since it is not part of the string.
				
				unsigned char next = *(bytes_ptr+2);
				
				if(next == 012) {
					
					bytes_ptr+=3;
					processed_bytes_count+=3;
					
				} else {
					
					bytes_ptr+=2;
					processed_bytes_count+=2;
				}
				
			} else {
				
				// Skip the / since the following char doesn't match any of the valid ones.
				
				bytes_ptr++;
				processed_bytes_count++;
			}
		}
	}
	
	*length = written_codes;
    
    int tmp = 0;
    unsigned char * tmp_ptr = *sequence;
    fprintf(stdout,"(");
    while(tmp < written_codes) {
        fprintf(stdout,"%02X",tmp_ptr[tmp]);
        tmp++;
    }
    fprintf(stdout,") -> ");
     */
}

CGRect rectFromRectangleArray(CGPDFArrayRef rectangle) {

	CGPDFReal llx, lly, urx, ury;
    llx = lly = urx = ury = 0.0f;
    
    CGRect rect = CGRectNull;
    
	CGPDFArrayGetNumber(rectangle, 0, &llx);
	CGPDFArrayGetNumber(rectangle, 1, &lly);
	CGPDFArrayGetNumber(rectangle, 2, &urx);
	CGPDFArrayGetNumber(rectangle, 3, &ury);
    
    rect = CGRectStandardize(CGRectMake(llx, lly, (urx-llx), (ury-lly)));
   
    //NSLog(@"Array %.3f, %.3f, %.3f, %.3f to rect (%.3f, %.3f) [%.3f x %.3f]", llx, lly, urx, ury, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	return rect;
}

NSUInteger pageNumberForLink(CGPDFDocumentRef document, CGPDFDictionaryRef link) {
	
	NSUInteger pageNumber = 0;
	
	size_t pages = CGPDFDocumentGetNumberOfPages(document);
	size_t counter;
	// fprintf(stdout,"-> pinter %p\n",link);
	for(counter = 1; counter <= pages; counter++) {
		
		CGPDFPageRef page = CGPDFDocumentGetPage(document, counter);
		CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
		if(link == pageDictionary) {
			pageNumber = counter;
			break;
		}
	}
	
	return pageNumber;
}

NSUInteger pageNumberForDestinationNamed(CGPDFDocumentRef document, NSString * destinationName) {
    
    NSUInteger pageNumber = 0;
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
    BOOL found = NO;
    
    if(destinationName) {
        
        const char * name = [destinationName cStringUsingEncoding:NSUTF8StringEncoding];
        CGPDFDictionaryRef destinations = NULL;
        
        if(CGPDFDictionaryGetDictionary(catalog, "Dests", &destinations)) {
            
            // Get the entry corresponding to the name
            CGPDFObjectRef entry = NULL;
            
            if(CGPDFDictionaryGetObject(destinations, name, &entry)) {
                
                // The entry could be an array or a dictionary with the array as the D entry
                CGPDFObjectType type = CGPDFObjectGetType(entry);
                
                if(type == kCGPDFObjectTypeArray) {
                    
                    CGPDFArrayRef destinationArray = NULL;
                    if(CGPDFObjectGetValue(entry, kCGPDFObjectTypeArray, &destinationArray)) {
                        
                        // Get the page dictionary
                        CGPDFDictionaryRef link = NULL;
                        if(CGPDFArrayGetDictionary(destinationArray, 0, &link)){
                            
                            pageNumber = pageNumberForLink(document, link);
                            found = YES;
                        }
                    }
                    
                } else if (type == kCGPDFObjectTypeDictionary) {
                    
                    CGPDFDictionaryRef destinationDictionary = NULL;
                    if(CGPDFObjectGetValue(entry, kCGPDFObjectTypeDictionary, &destinationDictionary)) {
                        
                        // Get the array under the D entry
                        CGPDFArrayRef destinationArray = NULL;
                        if(CGPDFDictionaryGetArray(destinationDictionary, "D", &destinationArray)) {
                            
                            // Get the page dictionary
                            CGPDFDictionaryRef link = NULL;
                            if(CGPDFArrayGetDictionary(destinationArray, 0, &link)){
                                
                                pageNumber = pageNumberForLink(document, link);
                                found = YES;
                            }
                        }
                    }
                }
            }
        }
    }
    
    if(!found) {
        
        CFStringRef destinationString = (CFStringRef)destinationName;
        CGPDFDictionaryRef names = NULL;
        CGPDFDictionaryRef namedDestinations = NULL;
        
        if(CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
            
            if(CGPDFDictionaryGetDictionary(names, "Dests", &namedDestinations)) {
                
                CGPDFDictionaryRef link = pageDictionaryForNameInNameTree(destinationString, namedDestinations);
                
                pageNumber = pageNumberForLink(document, link);
            }
        }
    }
    
    return pageNumber;
}

CFStringRef createDestinationNameForDestination(CGPDFDocumentRef document, CGPDFObjectRef destination, NSUInteger * fallbackPageNumber) {
    
    CFStringRef destinationName = NULL;
    
    if(destination) {
        
        switch(CGPDFObjectGetType(destination)) {
				
			case kCGPDFObjectTypeArray : {
				
				// Esplicit destination, abort.
                
                CGPDFArrayRef array = NULL;
                long number = 0;
                
                if(CGPDFObjectGetValue(destination, kCGPDFObjectTypeArray, &array)) {
                    
                    if(CGPDFArrayGetInteger(array, 0, &number)) {
                        *fallbackPageNumber = (number+1);    
                    }
                }
                
                
			}; break;
				
			case kCGPDFObjectTypeName : {
				
				char * name;
                
				CGPDFObjectGetValue(destination, kCGPDFObjectTypeName, &name);
                
                destinationName = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
                
                }; break;
				
			case kCGPDFObjectTypeString : {
                
                //fprintf(stdout,"\t\t\tNamed esplicit");
				
				CGPDFStringRef destinationString = NULL;
				if(CGPDFObjectGetValue(destination, kCGPDFObjectTypeString, &destinationString)) {
					
                    destinationName = CGPDFStringCopyTextString(destinationString);
				}
                
			}; break;
                
            default: {
                // Should not happen.
                
            };
                break;
        }
    }
    
    return destinationName;
}

NSUInteger pageNumberForDestination(CGPDFDocumentRef document, CGPDFObjectRef destination) {
	
	CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
	NSUInteger pageNumber = 0;
	
	// Process the destination, if any
	if(destination){
		
		// Dest can be an Array (esplicit), or a name (char *) or bytestring (CGPDFStringRef)
		
		switch(CGPDFObjectGetType(destination)) {
				
			case kCGPDFObjectTypeArray : {
				
				// Esplicit destination
				
                // fprintf(stdout,"\t\t\tEsplicit destination\n");
                
                CGPDFArrayRef destinationArray = NULL;
                CGPDFObjectRef destinationObject = NULL;
                CGPDFObjectType destObjType;
                
				if(CGPDFObjectGetValue(destination, kCGPDFObjectTypeArray, &destinationArray)) {
				
                    if(CGPDFArrayGetObject(destinationArray, 0, &destinationObject)) {
                     
                        destObjType = CGPDFObjectGetType(destinationObject);
                        
                        if(destObjType == kCGPDFObjectTypeDictionary) {
                            
                            //fprintf(stdout,"\t\t\tDictionary\n");
                            
                            CGPDFDictionaryRef link = NULL;
                            if(CGPDFArrayGetDictionary(destinationArray, 0, &link)){
                                
                                //parseDictionary(link);
                                pageNumber = pageNumberForLink(document, link);
                                
                            }
                            
                        } else if (destObjType == kCGPDFObjectTypeInteger) {
                            
                            // This has been required to support certain type of outline where the first destination entry is the page number, starting at 0.
                            //fprintf(stdout,"\t\t\t\tPage number\n");
                            CGPDFObjectGetValue(destinationObject, destObjType, &pageNumber);
                            
                            pageNumber++;
                            
                            
                        } else {
                            NSLog(@"Unsupported outline destination object type %d",destObjType);
                        }
                        
                        
                    }
                }
                    
			}; break;
				
			case kCGPDFObjectTypeName : {
				
				char * name;
				//fprintf(stdout,"\t\t\tNamed implicit (looking through the tables\n");
				CGPDFObjectGetValue(destination, kCGPDFObjectTypeName, &name);
				
				// Now that we have a name, get the Dests dictionary from the Catalog
				
                //NSLog(@"Named destination %s",name);
                
				CGPDFDictionaryRef destinations = NULL;
				if(CGPDFDictionaryGetDictionary(catalog, "Dests", &destinations)) {
					
					// Get the entry corresponding to the name
					CGPDFObjectRef entry = NULL;
					if(CGPDFDictionaryGetObject(destinations, name, &entry)) {
						
						
						// The entry could be an array or a dictionary with the array as the D entry
						CGPDFObjectType type = CGPDFObjectGetType(entry);
						
						if(type == kCGPDFObjectTypeArray) {
							
							CGPDFArrayRef destinationArray = NULL;
							if(CGPDFObjectGetValue(entry, kCGPDFObjectTypeArray, &destinationArray)) {
								
								// Get the page dictionary
								CGPDFDictionaryRef link = NULL;
								if(CGPDFArrayGetDictionary(destinationArray, 0, &link)){
									
									pageNumber = pageNumberForLink(document, link);
									
								}
							}
							
						} else if (type == kCGPDFObjectTypeDictionary) {
							
							CGPDFDictionaryRef destinationDictionary = NULL;
							if(CGPDFObjectGetValue(entry, kCGPDFObjectTypeDictionary, &destinationDictionary)) {
								
								// Get the array under the D entry
								CGPDFArrayRef destinationArray = NULL;
								if(CGPDFDictionaryGetArray(destinationDictionary, "D", &destinationArray)) {
									
									// Get the page dictionary
									CGPDFDictionaryRef link = NULL;
									if(CGPDFArrayGetDictionary(destinationArray, 0, &link)){
										
										pageNumber = pageNumberForLink(document, link);
									}
								}
							}
						}
					}
				}
			}; break;
				
			case kCGPDFObjectTypeString : {
                
                //fprintf(stdout,"\t\t\tNamed esplicit");
				
				CGPDFStringRef destinationString = NULL;
				if(CGPDFObjectGetValue(destination, kCGPDFObjectTypeString, &destinationString)) {
					
					CGPDFDictionaryRef names = NULL;
					if(CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
						
						CGPDFDictionaryRef namedDestinations = NULL;
						if(namedDestinations||CGPDFDictionaryGetDictionary(names, "Dests", &namedDestinations)) {
							
                            CFStringRef destinationName = CGPDFStringCopyTextString(destinationString);
							
							if(destinationName) {
                                CGPDFDictionaryRef link = pageDictionaryForNameInNameTree(destinationName, namedDestinations);
                                pageNumber = pageNumberForLink(document, link);
                                CFRelease(destinationName);
                            }
							
						}
					}
				}
			}; break;
			default : {
				
				pageNumber = 0;
				
			}; break;
		} // end of switch(type)
	} // end of if(destination)	
	
	return pageNumber;
}

CGPDFDictionaryRef pageDictionaryForNameInNameTree(CFStringRef name, CGPDFDictionaryRef nameTree) {
	
	CGPDFObjectRef	value = NULL;
	
	// Try to find the value associated to the name
	valueForNameInNameTreeNode(name,nameTree,&value);
	
	if(value!=NULL) {
		
		CGPDFObjectType type = CGPDFObjectGetType(value);
		
		CGPDFObjectRef page = NULL;
		CGPDFArrayRef array = NULL;
		CGPDFDictionaryRef dictionary = NULL;
		
		// Should be either an Array or a Dictionary
		
		switch (type) {
				
			case kCGPDFObjectTypeArray:
				
				CGPDFObjectGetValue(value, kCGPDFObjectTypeArray, &array);
				
				CGPDFArrayGetObject(array, 0, &page);
				
				break;
				
			case kCGPDFObjectTypeDictionary:
				
				CGPDFObjectGetValue(value, kCGPDFObjectTypeDictionary, &dictionary);
				
				CGPDFDictionaryGetArray(dictionary, "D", &array);
				
				CGPDFArrayGetObject(array, 0, &page);
				
				break;
				
			default:
				break;
		} // eof switch(type)
		
		
		CGPDFDictionaryRef pageDictionary = NULL;
		if(CGPDFObjectGetValue(page, kCGPDFObjectTypeDictionary, &pageDictionary)) {
			
			return pageDictionary;
		}
		// pageNumber = pageNr;
		
	} 
	
	return NULL;
}

void valueForNameInNameTreeNode(CFStringRef name, CGPDFDictionaryRef node, CGPDFObjectRef * value) {
	
	CGPDFArrayRef values;
	CGPDFArrayRef limits;
	
	// If there's a limits entry, check against it, no matter if leaf or intermediate node
	if(CGPDFDictionaryGetArray(node, "Limits", &limits)) {
		if(!isNameInsideLimits(limits, name)) {
			return;
		}
	}
	
	// Now look at the node
	if(CGPDFDictionaryGetArray(node, "Names", &values)) {
		
		// It's a leaf, try to find the value
		objectForKeyInArray(name, values, value);
		
	} else if (CGPDFDictionaryGetArray(node, "Kids", &values)) {
		
		// It's an intermediate node or the root node, get all the kids and iterate over them
		
		size_t kidsCount = CGPDFArrayGetCount(values);
		size_t index;
		for( index = 0; index < kidsCount; index++) {
			
			CGPDFDictionaryRef kid;
			if(CGPDFArrayGetDictionary(values, index, &kid)) {
				
				valueForNameInNameTreeNode(name,kid,value);
				if((*value)!=NULL){
					break;
				}
			}
			
		} // eof for
	}
}

void objectForKeyInArray(CFStringRef key, CGPDFArrayRef array, CGPDFObjectRef * obj) {
	
	CGPDFStringRef k1;
	CFStringRef k1s;
	NSUInteger coupleCounts;
	
	coupleCounts = CGPDFArrayGetCount(array)/2;
	
	NSUInteger index = 0;
	
	//NSLog(@"Looking for %@",keyString);
	
	for( ; index < coupleCounts; index++) {
		
		if(CGPDFArrayGetString(array, index*2, &k1)) {
			
			k1s = CGPDFStringCopyTextString(k1);
			
			if(CFStringCompare(key, k1s, 0) == kCFCompareEqualTo) {
				
				// Found it
				
				CGPDFArrayGetObject(array, index*2+1, obj);
				
				CFRelease(k1s);
				
				break;
				
			} else {
				
				// Keep searching
				
				CFRelease(k1s);	
			}
			
		}
	}
}

BOOL isNameInsideLimits2(CGPDFArrayRef limits, CFStringRef name) {
    
    CGPDFStringRef lowerLimit;
	CGPDFStringRef upperLimit;
	CFStringRef lls; 
	CFStringRef uls; 
	
	if((!(CGPDFArrayGetString(limits, 0, &lowerLimit)&&CGPDFArrayGetString(limits, 1, &upperLimit)))) {
		return NO;
	};
	
	lls = CGPDFStringCopyTextString(lowerLimit);
	uls = CGPDFStringCopyTextString(upperLimit);
	
	BOOL result = YES;
	if((CFStringCompare(name, lls, 0) == kCFCompareLessThan)||(CFStringCompare(name, uls, 0) == kCFCompareGreaterThan)) {
		result = NO;
	} else {
	}
	
	CFRelease(lls);
	CFRelease(uls);
	
	return result;
}

BOOL isNameInsideLimits(CGPDFArrayRef limits, CFStringRef name) {
	
	CGPDFStringRef lowerLimit;
	CGPDFStringRef upperLimit;
	CFStringRef lls; 
	CFStringRef uls; 
	
	if((!(CGPDFArrayGetString(limits, 0, &lowerLimit)&&CGPDFArrayGetString(limits, 1, &upperLimit)))) {
		return NO;
	};
	
	lls = CGPDFStringCopyTextString(lowerLimit);
	uls = CGPDFStringCopyTextString(upperLimit);
	
	BOOL result = YES;
	if((CFStringCompare(name, lls, 0) == kCFCompareLessThan)||(CFStringCompare(name, uls, 0) == kCFCompareGreaterThan)) {
		result = NO;
	} else {
	}
	
	CFRelease(lls);
	CFRelease(uls);
	
	return result;
}

@implementation MFPDFObjectParser

#pragma mark CGPDFObjects to COCOA objects

@synthesize storage, object;

+(MFPDFObjectParser *)parser {
    
    MFPDFObjectParser * parser = [[MFPDFObjectParser alloc]init];
    
    return [parser autorelease];
}

-(NSDictionary *)parse:(CGPDFObjectRef)obj {
    
    [storage removeAllObjects];
    CFDictionaryRemoveAllValues(cache);
    
    self.object = [self objectForPDFObject:obj];
    
    if(self.object) {
        
        return [NSDictionary dictionaryWithObjectsAndKeys:storage, @"cache", object, @"object", nil];
        
    }
    
    return nil;
}

-(id)init {
  
    self = [super init];
    if(self) {
        
        cache = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
        self.storage = [[[NSMutableArray alloc]init]autorelease];
    }
    
    return self;
}

-(void)dealloc {
    
    //CFDictionaryRemoveAllValues(cache);
    if(cache)
        CFRelease(cache), cache = NULL;
    
    [storage release], storage = nil;
    
    [object release], object = nil;
    
    [super dealloc];
}

-(id)booleanWithPDFObject:(CGPDFObjectRef) obj {
    
    BOOL yesOrNot = NO;
    
    if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeBoolean, &yesOrNot)) {
        
        return [NSNumber numberWithBool:yesOrNot];
    }
    
    return nil;
}

-(void)cacheCocoaObject:(id)cocoaObj forPDFObject:(CGPDFObjectRef)pdfObj {
    
    if(cocoaObj && pdfObj) {
        [storage addObject:cocoaObj];
        CFDictionarySetValue(cache, pdfObj, cocoaObj);
    }
}

-(id)cachedCocoaObjectForPDFObject:(CGPDFObjectRef)pdfObj {
    
    return CFDictionaryGetValue(cache, pdfObj);
}

//-(id)stringWithPDFObject:(CGPDFObjectRef) obj {
//    
//    NSString * string = nil;
//    
//    CGPDFStringRef stringObj = NULL;
//    if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeString, &stringObj)) {
//
//        CFStringRef foundationString = NULL;
//        foundationString = CGPDFStringCopyTextString(stringObj);
//        
//        string = [[NSString stringWithString:(NSString *)foundationString]copy];
//        
//        if(foundationString)
//            CFRelease(foundationString);
//    }
//
//    return string;
//}

//-(id)nameWithPDFObject:(CGPDFObjectRef) obj {
//    
//    NSString * string = nil;
//    
//    const char * name = NULL;
//    
//    if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeName, &name)) {
//        string = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
//    }
//    
//    return string;
//}

/**
 Helper function used by the CGPDFDictionaryApplierFunction to get reference of both the parser
 and the dictionary in which parsed object will be added.
 */
typedef struct CocaizePDFDictionaryEntryHelper {
    
    void * parserInstance;
    void * dictionaryInstance;

} CocaizePDFDictionaryEntryHelper;

/**
 This function will run on each CGPDFDictionary entry. CGPDFObject will be 'cocoized', cached and
 added to the cocoa dictionary.
 */
void cocoaizePDFDictionaryEntry(const char * key, CGPDFObjectRef object, void * info) {
    
    CocaizePDFDictionaryEntryHelper * helper = (CocaizePDFDictionaryEntryHelper *)info;
    MFPDFObjectParser * parser = (MFPDFObjectParser *) helper->parserInstance;
    CFMutableDictionaryRef dictionary = (CFMutableDictionaryRef) helper->dictionaryInstance;
    
    NSString * dictionaryEntryKey = nil;
    id dictionaryEntryObject = [parser objectForPDFObject:object];
    
    if(dictionaryEntryObject) {
        
        dictionaryEntryKey = [[NSString alloc] initWithCString:key encoding:NSUTF8StringEncoding];
        
#if LOG_PARSER
        NSLog(@"Storing object for key %@", dictionaryEntryKey);
#endif
        
        CFDictionarySetValue(dictionary, dictionaryEntryKey, dictionaryEntryObject);
        [dictionaryEntryKey release];   
    }
}

-(CFDictionaryRef)createUncachedDictionaryForPDFStreamDictionary:(CGPDFDictionaryRef)pdfDictionary {
    
    CFMutableDictionaryRef dictionary = NULL;
    CocaizePDFDictionaryEntryHelper * helper;
    
    size_t size = CGPDFDictionaryGetCount(pdfDictionary);
    
    dictionary = CFDictionaryCreateMutable(NULL, size, &kCFCopyStringDictionaryKeyCallBacks, NULL);
    
    helper = calloc(1, sizeof(CocaizePDFDictionaryEntryHelper));
    helper->dictionaryInstance = (void *)dictionary;
    helper->parserInstance = (void *)self;
    
#if LOG_PARSER
    NSLog(@"Found dictionary with %lu entries", size);
#endif
    
    CGPDFDictionaryApplyFunction(pdfDictionary, cocoaizePDFDictionaryEntry, (void *)helper);
    
    if(helper)
        free(helper);
    
    return dictionary;
}

/**
 This function will return the cocoa representation of a CGPDFObject.
 */
-(id)objectForPDFObject:(CGPDFObjectRef) obj {

    
    if(CFDictionaryContainsKey(cache, obj)) {
    
        // Object has been already generated, get the cached one
        
#if LOG_PARSER
        NSLog(@"Cache hit");
#endif
        return CFDictionaryGetValue(cache, obj);
    }
    
    
    // First time we meet this pdf object, we need to generate and cache
    // a new cocoa object (in some case it will be a Core Foundation object) for it
    
    CGPDFObjectType type;
    type = CGPDFObjectGetType(obj);
    
    switch (type) {
            
        case kCGPDFObjectTypeArray: {
            
            CGPDFArrayRef pdfArray = NULL;
            size_t size = 0; // Array size
            CFMutableArrayRef array = NULL; // Array to be cached and returned
            
            CGPDFObjectRef pdfArrayItem = NULL;
            id cocoaArrayItem = NULL;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeArray, &pdfArray)) {
    
                size = CGPDFArrayGetCount(pdfArray);
                
                array = CFArrayCreateMutable(NULL, size, NULL); // Create the cocoa object
                
#if LOG_PARSER
                NSLog(@"Found array of %lu items", size);
#endif
                [self cacheCocoaObject:(id)array forPDFObject:obj];
                
                // Now iterate over the array items
                size_t index;
                for (index = 0; index < size; index++) {
                    
                    if(CGPDFArrayGetObject(pdfArray, index, &pdfArrayItem)) {
                     
                        cocoaArrayItem = [self objectForPDFObject:pdfArrayItem];
                        
#if LOG_PARSER
                        NSLog(@"Adding object %lu to array", index);
#endif
                        
                        CFArrayAppendValue(array, cocoaArrayItem);
                    }
                }
                
                if(array)
                    CFRelease(array);
                
                return (NSArray *)array;
                
            }
        }
            break;
        case kCGPDFObjectTypeBoolean: {
            
            BOOL yesOrNot = NO;
            NSNumber * cocoaBoolean = NULL;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeBoolean, &yesOrNot)) {
                
                cocoaBoolean = [[NSNumber alloc]initWithBool:yesOrNot];
                
#if LOG_PARSER
                NSLog(@"Found boolean %d", yesOrNot);
#endif
                [self cacheCocoaObject:cocoaBoolean forPDFObject:obj];
                
                [cocoaBoolean release];
                
                return cocoaBoolean;
            }
        }
            
            break;
        case kCGPDFObjectTypeDictionary: {
            
            CGPDFDictionaryRef pdfDictionary = NULL;
            CFDictionaryRef dictionary = NULL;
            CocaizePDFDictionaryEntryHelper * helper;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &pdfDictionary)) {
            
                size_t size = CGPDFDictionaryGetCount(pdfDictionary);
                
                dictionary = CFDictionaryCreateMutable(NULL, size, &kCFCopyStringDictionaryKeyCallBacks, NULL);
            
                helper = calloc(1, sizeof(CocaizePDFDictionaryEntryHelper));
                helper->dictionaryInstance = (void *)dictionary;
                helper->parserInstance = (void *)self;
                
#if LOG_PARSER
                NSLog(@"Found dictionary with %lu entries", size);
#endif
                
                [self cacheCocoaObject:(id)dictionary forPDFObject:obj];
                
                CGPDFDictionaryApplyFunction(pdfDictionary, cocoaizePDFDictionaryEntry, (void *)helper);
                
                if(dictionary)
                    CFRelease(dictionary);
                
                if(helper)
                    free(helper);
                
                return (NSDictionary *)dictionary;
            }
        }
            
            break;
        case kCGPDFObjectTypeInteger: {
            
            long int integer = 0;
            NSNumber * number = nil;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeInteger, &integer)) {
            
                number = [[NSNumber alloc]initWithLong:integer];
#if LOG_PARSER
                NSLog(@"Found integer %ld", integer);
#endif
                [self cacheCocoaObject:number forPDFObject:obj];
                
                [number release];
                
                return number;
            }
        }
            break;
        case kCGPDFObjectTypeName: {
            
            const char * name = NULL;
            NSString * string = NULL;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeName, &name)) {
                
                string = [[NSString alloc]initWithCString:name encoding:NSASCIIStringEncoding];
                
#if LOG_PARSER
                NSLog(@"Found name %@", string);
#endif
                [self cacheCocoaObject:string forPDFObject:obj];
                
                [string release];
                
                return string;
            }
        }
            break;
        case kCGPDFObjectTypeNull: {
            
#if LOG_PARSER
            NSLog(@"Found NULL");
#endif
            return [NSNull null];
            
        }
            break;
        case kCGPDFObjectTypeReal: {
            
            CGFloat floatValue = 0;
            NSNumber * number = nil;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeReal, &floatValue)) {
                
                number = [[NSNumber alloc]initWithFloat:floatValue];
                
#if LOG_PARSER
                NSLog(@"Found real %f", floatValue);
#endif
                [self cacheCocoaObject:number forPDFObject:obj];
                
                [number release];
                
                return number;
            }
        }
            
            break;
        case kCGPDFObjectTypeStream: {
            
            CGPDFDictionaryRef streamDictionary = NULL;
            CGPDFStreamRef stream = NULL;
            NSString * streamType = nil;
            CFDataRef streamData = NULL;
            CGPDFDataFormat format;
            CFDictionaryRef dictionary = NULL;
            NSMutableDictionary * wrapper = nil;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeStream, &stream)) {
            
                //wrapper = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // Wrapper will retain stuff and will be the only object to be directly cached
                wrapper = [[NSMutableDictionary alloc]init];
                
                [self cacheCocoaObject:(id)wrapper forPDFObject:obj]; // Cache the wrapper dictionary for the object
                
                
                // 1. Get the data and add it to the wrapper
                
                streamData = CGPDFStreamCopyData(stream, &format);
                
                // NSLog(@"%ld", CFDataGetLength(streamData));
                
                [wrapper setValue:(id)streamData forKey:@"streamData"];
                
                // 2. Store the data format too
                
                switch (format) {
                    case CGPDFDataFormatRaw:
                        streamType = [[NSString alloc] initWithString:@"raw"];
                        break;
                    case CGPDFDataFormatJPEGEncoded:
                        streamType = [[NSString alloc] initWithString:@"jpegEncoded"];
                        break;
                    case CGPDFDataFormatJPEG2000:
                        streamType = [[NSString alloc] initWithString:@"jpeg2000"];
                    default:
                        break;
                }
                //CFDictionaryAddValue(wrapper, "streamFormat", streamType);
                [wrapper setValue:streamType forKey:@"streamFormat"];
                
                // 3. Now get the stream dictionary and store it
                
                if((streamDictionary = CGPDFStreamGetDictionary(stream))) {
                    
                    dictionary = [self createUncachedDictionaryForPDFStreamDictionary:streamDictionary];
                    //CFDictionaryAddValue(wrapper, "streamDictionary", dictionary);
                    
                    [wrapper setValue:(id)dictionary forKey:@"streamDictionary"];
                    
                    if(dictionary)
                        CFRelease(dictionary);
                }
                
                // Cleanup
                
                if(streamData)
                    CFRelease(streamData);
                if(wrapper)
                    CFRelease(wrapper);
                [streamType release];
                
                return (NSDictionary *)wrapper;
            }
        }
            
            break;
        case kCGPDFObjectTypeString: {
            
            CGPDFStringRef pdfString = NULL;
            NSString *string = NULL;
            CFStringRef cfString = NULL;
            
            if(CGPDFObjectGetValue(obj, kCGPDFObjectTypeString, &pdfString)) {
                
                cfString = CGPDFStringCopyTextString(pdfString);
                string = [[NSString stringWithString:(NSString *)cfString]copy];
                
#if LOG_PARSER
                NSLog(@"Found string %@", string);
#endif
                
                [self cacheCocoaObject:string forPDFObject:obj];
                
                if(cfString)
                    CFRelease(cfString);
                
                [string release];
                
                return string;
            }
        }
            
            break;
        default:
            NSLog(@"Defauling");
            return nil;
            break;
    }
    NSLog(@"No match found");
    return nil;
}

-(void)drawObject:(NSData *)data 
        onContext:(CGContextRef)context 
       dictionary:(NSDictionary *)dictionary 
{
    
    return; // TODO: clean up before enable
    
    unsigned int command = 0;
    
    char scratchpad [128];
    char * scratchpadPtr = NULL;
    int scratchpadLen = 0;
    
    CGFloat parameters[4];
    CGFloat * parametersPtr = NULL;
    int parametersLen = 0;
    
    const char * bytes = [data bytes];
    const char * bytesPtr = NULL;
    
    size_t bytesLen = [data length];
    
    size_t index;
    
    scratchpadPtr = scratchpad;
    parametersPtr = parameters;
    bytesPtr = bytes;
    
    for (index = 0; index < bytesLen ; index++, bytesPtr++) {
        
        if(((*bytesPtr) == ' ') || ((*bytesPtr) == '\r') || ((*bytesPtr) == '\n')) {
            
            // End of input or command
            
            *scratchpadPtr = 0;
            scratchpadPtr++;
            
            if(scratchpadLen > 0) {
                
                if(command) {
                    
                    NSLog(@"Command %s", scratchpad);
                    int _idx;
                    for(_idx = 0; _idx < parametersLen; _idx++) {
                        NSLog(@"P%d : %f", _idx, parameters[_idx]);
                    }
                    
                    // Reset the parameters
                    
                    parametersPtr = parameters;
                    parametersLen = 0;
                    
                } else {
                    
                    float value = 0;
                    sscanf(scratchpad, "%f", &value);
                    
                    // NSLog(@"Parameter %f", value);
                    
                    *parametersPtr = value;
                    parametersPtr++;
                    parametersLen++;
                }
            }
            
            scratchpadLen = 0;
            scratchpadPtr = scratchpad;
            command = 0;
            
        } else {
            
            if(((*bytesPtr) > '/') && ((*bytesPtr) <':')) {
                
                // Number
                command|=0;
                
            } else if (((*bytesPtr) == '.')||(*bytes == '-')) {
                
                // Dot and minus
                command|=0;
                
            } else {
                
                // Other
                command|=1;
            }
            
            (*scratchpadPtr) = (*bytesPtr);
            scratchpadPtr++;
            scratchpadLen++;
        }
    }
}

@end
