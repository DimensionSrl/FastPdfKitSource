//
//  MFStreamScanner.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 10/26/10.
//  Copyright 2010 MobFarm S.r.l. All rights reserved.
//

#import "MFStreamScanner.h"
#import "MFSearchResult.h"
#import "MFTextItem.h"
#import "MFTextBox.h"
#import "MFFontData.h"
#import "MFTextState.h"
#import <string.h>
#import <stdio.h>
// #include "mffontencoding.h"
#import "MFPDFUtilities.h"
#import "Stuff.h"
#import "MFToUnicodeCMapScanner.h"
#import "MFToUnicodeCMapScannerMultibyte.h"
#import "MFCIDFontScanner.h"
#import "MFWidthCluster.h"
#import "resources.h"

@interface MFStreamScanner()

// CID file parsing functions.

void parseCidFontStream(CGPDFStreamRef cidStream, void * info);
void parseCIDFontFile(const char * filename, void * info);

// CMap parsing functions.

void parseToUnicodeCMapFileMultibyte (const char * filename, void * info);
void parseToUnicodeCMapStreamMultibyte(CGPDFStreamRef cMapStream, void * info);
void parseToUnicodeCMapStream(CGPDFStreamRef cMapStream, void * info);


// Sniff (parse) function for font.

void sniffType0Font(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info);
void sniffType1Font(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info);
void sniffType3Font ( CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info );
void sniffTrueTypeFont(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info);

@property (nonatomic,retain) NSMutableDictionary * fonts;

@end


@implementation MFStreamScanner
@synthesize state;
@synthesize fontCache, fonts, useCache;

typedef struct ScannerInfo {
	CGPDFContentStreamRef pageContentStream;
	CGPDFDictionaryRef resources;
    CGPDFDictionaryRef fonts;
	MFTextState * state;
    BOOL useCache;
} ScannerInfo;

#pragma mark Text showing operators

static inline void stringFromCGPDFString(CGPDFStringRef pdfString, const char **string) {
	
	CFStringRef cfString;
	NSString *nsString;
	
	cfString = CGPDFStringCopyTextString(pdfString);
	nsString = (NSString *)cfString;
	*string = [nsString cStringUsingEncoding:NSUTF8StringEncoding];
	
	CFRelease(cfString);
}

static void
op_Tj(CGPDFScannerRef s, void *info) {
	
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    
	CGPDFStringRef pdfString = NULL;
	
	const unsigned char * sequence = NULL;
	size_t length = 0;
	
	MFTextState *state = ((ScannerInfo *)info)->state;
    
	if(CGPDFScannerPopString(s, &pdfString)) {

        sequence = CGPDFStringGetBytePtr(pdfString);
        length = CGPDFStringGetLength(pdfString);
            
		// codeSequenceFromString(pdfString, &sequence, &length);
	}
    
	[state showCodes:sequence length:length];
	
	// MF_C_FREE(sequence);
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	const char *string = NULL;
	stringFromCGPDFString(pdfString, &string);
    
    char * tmp = calloc(length+1, sizeof(char));
    memcpy(tmp, string, length);
    fprintf(stdout, "%s", tmp);
    free(tmp);
    
	printf("Tj (%s)\n",tmp);
#endif
	
}

static void
op_BMC(CGPDFScannerRef s, void * info) {
    
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    fprintf(stdout, "BMC\n");
}

static void 
op_EMC(CGPDFScannerRef s, void * info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    fprintf(stdout, "EMC\n");
}

static void 
op_BDC(CGPDFScannerRef s, void * info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    const char * tag;
    const char * properties_name;
    CGPDFDictionaryRef properties_dictionary;
    CGPDFObjectRef obj;
    fprintf(stdout, "BDC\n");
    if(CGPDFScannerPopObject(s, &obj)) {
        
        fprintf(stdout, "Object found %s\n",objectGetType(obj));
    }
    if(CGPDFScannerPopName(s, &properties_name)) {
        fprintf(stdout, "\tproperties: %s\n",properties_name);
    } else if (CGPDFScannerPopDictionary(s, &properties_dictionary)) {
        fprintf(stdout, "\tproperties: dictionary\n");
    }
    
    if(CGPDFScannerPopName(s, &tag)) {
        fprintf(stdout, "\ttag : %s\n",tag);
    }
}

static void
op_MP(CGPDFScannerRef s, void * info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    const char * tag = NULL;
    CGPDFScannerPopName(s, &tag);
    fprintf(stdout, "MP %s\n",tag);
    
}

static void 
op_ReversedChars(CGPDFScannerRef s, void * info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    fprintf(stdout, "ReversedChars\n");
}


static void
op_TJ(CGPDFScannerRef s, void *info) {
    
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
    
    #if DEBUG & FPK_DEBUG_PDFCOMMANDS
    printf(@"TJ");
#endif
		
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	float adj = 0;
	
	CGPDFArrayRef array = NULL;
	
	if(CGPDFScannerPopArray(s, &array)) {
		
        size_t count = CGPDFArrayGetCount(array);
		
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
		printf(" [");	
#endif
		
		int i;
		for(i = 0; i < count; i++) {
			
			CGPDFObjectRef object = NULL;
			CGPDFObjectType type;
			
			CGPDFArrayGetObject(array, i, &object);
			
			type = CGPDFObjectGetType(object);
			
			if(type == kCGPDFObjectTypeString) {
				
				CGPDFStringRef pdfString = NULL;
				
				const unsigned char * sequence = NULL;
				size_t length = 0;
				
				if(CGPDFObjectGetValue(object, type, &pdfString)) {
					//codeSequenceFromString(pdfString, &sequence, &length);
                    sequence = CGPDFStringGetBytePtr(pdfString);
                    length = CGPDFStringGetLength(pdfString);
				}
				
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
                const char *string = NULL;
                stringFromCGPDFString(pdfString, &string);
                printf( "%s",string);
#endif

                
				[state showCodes:sequence length:length adjustment:adj];
				//[state showCodes:sequence length:length];
				
				//MF_C_FREE(sequence);
					
				
			} else if (type == kCGPDFObjectTypeReal) {
				
				CGPDFReal value;
				if(CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &value)) {
					
					adj = value;
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
					printf(" %.3f",adj);
#endif
					
					[state setAdjustment:adj];
				}
				
			} else if (type == kCGPDFObjectTypeInteger) {
				
                CGPDFInteger value;
				if(CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &value)) {
					
					adj = (float)value;
					
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
					printf(" %.3f",adj);
#endif 
					[state setAdjustment:adj];
				}
				
			}
		}
		
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
		printf(" ]");
#endif
		
		// Clean up the adjustment.
		[state setAdjustment:0];
	}
	
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}


static void
op_invertedcomma(CGPDFScannerRef s, void *info) {
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("'");
#endif
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	// Same as
	// T* 
	// string Tj
	unsigned char *sequence = NULL;
	int length = 0;
	
	CGPDFStringRef pdfString = NULL;
	if(CGPDFScannerPopString(s, &pdfString)) {
		
		codeSequenceFromString(pdfString, &sequence, &length);
	}
	
	[state operatorTStar];

	[state showCodes:sequence length:length];

MF_C_FREE(sequence);

#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	const char *string = NULL;
	stringFromCGPDFString(pdfString, &string);
	printf("(%s)",string);
	printf("\n");
#endif
	
}	   

static void
op_quotationmark(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	// Operands: aw ac string
	CGPDFReal aw, ac;
	unsigned char * sequence = NULL;
	int length = 0;
	
	CGPDFStringRef pdfString = NULL;
	if(CGPDFScannerPopString(s, &pdfString)) {
		
		codeSequenceFromString(pdfString, &sequence, &length);
	}
	
	CGPDFScannerPopNumber(s, &ac);
	CGPDFScannerPopNumber(s, &aw);
	
	// Same as
	// aw Tw
	// ac Tc
	// T*
	// string Tj
	
	[state setWordSpace:aw];
	[state setCharSpace:ac];
	
	//[state updateTextAndLineMatrixTx:0 andTy:[state leading]];
	[state operatorTStar];
	[state showCodes:sequence length:length];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	const char *string = NULL;
	stringFromCGPDFString(pdfString, &string);
	printf("\" %.3f %.3f %s\n",aw,ac,string);
#endif
	
}


#pragma mark -
#pragma mark Text positioning operators

static void
op_Td(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	CGPDFReal tx, ty;
	
	CGPDFScannerPopNumber(s, &ty);
	CGPDFScannerPopNumber(s, &tx);
	
	[state operatorTdWithValuesTx:tx andTy:ty];
	//[state updateTextAndLineMatrixTx:tx andTy:ty];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Td %.3f %.3f\n",tx,ty);
#endif
}

static void
op_TD(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	CGPDFReal tx, ty;
	
	CGPDFScannerPopNumber(s, &ty);
	CGPDFScannerPopNumber(s, &tx);
	
	//[state setLeading:-ty];
	[state operatorTDWithValuesTx:tx andTy:ty];
	
	//[state setLeading:-ty];
//	[state updateTextAndLineMatrixTx:tx andTy:ty];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("TD tx %.3f ty %.3f\n",tx,ty);
#endif
	
}

static void
op_Tm(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	CGPDFReal values [6];
	int i;
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	for(i = 0; i < 6; i++) {
		CGPDFScannerPopNumber(s, &values[i]);
	}
	
	[state operatorTmWithValuesA:values[5] B:values[4] C:values[3] D:values[2] E:values[1] andF:values[0]];
	//[state setTextAndLineMatrixA:values[5] B:values[4] C:values[3] D:values[2] E:values[1] andFinallyF:values[0]];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tm %.3f %.3f %.3f %.3f %.3f %.3f\n",values[5],values[4],values[3],values[2],values[1],values[0]);
#endif
	
	return;
}

static void
op_T_star(CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("T*\n");
#endif
	
	// Same effect as
	// 0 tl Td
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	//[state updateTextAndLineMatrixTx:0 andTy:[state leading]];	
	[state operatorTStar];
	
}

#pragma mark -
#pragma mark Text state operators

static void
op_BT (CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
    printf("BT\n");
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state beginBlock];
	
}

static void
op_ET (CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("ET\n");
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state endBlock];
}

// Character spacing.
static void
op_Tc(CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tc");
#endif
	
	CGPDFReal characterSpacing = 0;
	
	if(!CGPDFScannerPopNumber(s, &characterSpacing))
		return;
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %.3f",characterSpacing);
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state setCharSpace:characterSpacing];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
	
}

// Word spacing.
static void
op_Tw(CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tw");
#endif
	
	CGPDFReal wordSpacing = 0;
	
	if(!CGPDFScannerPopNumber(s, &wordSpacing))
		return;
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %.3f", wordSpacing);
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state setWordSpace:wordSpacing];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}

// Horizontal scaling.
static void
op_Tz(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tz\n");
#endif
	
	CGPDFReal horizontalScaling;
	
	if(!CGPDFScannerPopNumber(s, &horizontalScaling))
		return;
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %.3f",horizontalScaling);
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state setScale:horizontalScaling];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}

static void
op_TL(CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("TL\n");
#endif
	
	CGPDFReal leading = 0;
	CGPDFScannerPopNumber(s, &leading);

#if DEBUG & FPK_DEBUG_PDFCOMMANDS				
	printf(" %.3f",leading);
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state setLeading:leading];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}

static void
op_Tf(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tf");
#endif
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	const char *fontname = NULL;
	CGPDFReal fontsize = 0;
	
	CGPDFScannerPopNumber(s, &fontsize);
	CGPDFScannerPopName(s, &fontname);
    
    // NSLog(@"Requesting font %s",fontname);
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %s %.3f ",fontname,fontsize);
#endif
	
	[state setFont:(char *)fontname andSize:fontsize];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}

static void
op_q(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state pushGraphicState];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("q PUSH_GRAPHIC_STATE\n");
#endif
}

static void
op_Q(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state popGraphicState];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Q POP_GRAPHIC_STATE\n");
#endif
}

static void
op_markedcontent(CGPDFScannerRef s, void * info) {
    NSLog(@"Marked content");
}

static void
op_cm(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
    
	CGPDFReal a,b,c,d,e,f;
	CGPDFScannerPopNumber(s, &f);
	CGPDFScannerPopNumber(s, &e);
	CGPDFScannerPopNumber(s, &d);
	CGPDFScannerPopNumber(s, &c);
	CGPDFScannerPopNumber(s, &b);
	CGPDFScannerPopNumber(s, &a);
	
	MFTextState *state = ((ScannerInfo *)info)->state;
	[state setCTMwithValuesA:a B:b C:c D:d E:e andFinallyF:f];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("cm %.3f %.3f %.3f %.3f %.3f %.3f\n",a,b,c,d,e,f);
#endif
}

static void
op_Tr(CGPDFScannerRef s, void *info) {
    
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Tr\n");
#endif
	
	// Render mode.
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	long int render;
	
	if(!CGPDFScannerPopInteger(s, &render)) {
		return;
	}
	
	[state setRender:render];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %ld",render);
	printf("\n");
#endif
	
}

static void
op_Ts(CGPDFScannerRef s, void *info) {
	
#if FPK_NO_COMMAND_OPS
    return;
#endif
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("Ts\n");
#endif
	
	CGPDFReal rise = 0;
	CGPDFScannerPopNumber(s, &rise);
	
	// Rise
	MFTextState *state = ((ScannerInfo *)info)->state;
	
	[state setRise:rise];
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf(" %.3f",rise);
#endif
	
#if DEBUG & FPK_DEBUG_PDFCOMMANDS
	printf("\n");
#endif
}


#pragma mark -
#pragma mark Font sniffer 

MFFontEncoder * fontEncoderForEncoding(CGPDFObjectRef encodingObj) {
	
	MFFontEncoder * encoder = NULL;
	
    if(!encodingObj) {

#if DEBUG & FPK_DEBUG_ENCODING 
        fprintf(stdout, "Defaulting to Standard Encoding (received NULL as encoding object)");
#endif
        
        encoder = malloc(sizeof(MFFontEncoder));
        initFontEncoderWithEncoding(encoder, MFFontEncodingStandard);
        
        
    } else {
		
		const char * encoding = NULL;
		const char * base_encoding = NULL;
		size_t differences_count = 0;
		
#if DEBUG & FPK_DEBUG_ENCODING
		int differences_applied = 0;
#endif
		
		CGPDFObjectType type = CGPDFObjectGetType(encodingObj);
		if(type == kCGPDFObjectTypeName) {
			
			CGPDFObjectGetValue(encodingObj, type, &encoding);
			
			// Initialize the encoder depending on the name of the encoding.
			
			if (strcmp(encoding,"MacRomanEncoding")==0) {
				
#if DEBUG & FPK_DEBUG_ENCODING
                fprintf(stdout,"Named MacRoman encoder\n");
#endif
                
				encoder = malloc(sizeof(MFFontEncoder));
				initFontEncoderWithEncoding(encoder, MFFontEncodingMacRoman);
				
			} else if (strcmp(encoding,"WinAnsiEncoding")==0) {

                
#if DEBUG & FPK_DEBUG_ENCODING
                fprintf(stdout,"Named WinAnsi encoder\n");
#endif
				
				encoder = malloc(sizeof(MFFontEncoder));
				initFontEncoderWithEncoding(encoder, MFFontEncodingWinAnsi);
				
			} else if (strcmp(encoding,"MacExpertEncoding")==0) {
				
                
#if DEBUG & FPK_DEBUG_ENCODING
                fprintf(stdout,"Named MacExpert encoder\n");
#endif

				encoder = malloc(sizeof(MFFontEncoder));
				initFontEncoderWithEncoding(encoder, MFFontEncodingMacExpert);
				
			} else {
				
				// Default to standard.
                
#if DEBUG & FPK_DEBUG_ENCODING
                fprintf(stdout,"Named Standerd encoder\n");
#endif

				encoder = malloc(sizeof(MFFontEncoder));
				initFontEncoderWithEncoding(encoder, MFFontEncodingStandard);	
			}
			
			
		} else if (type == kCGPDFObjectTypeDictionary) {
			
			encoding = "Dictionary";
			
			CGPDFDictionaryRef encodingDictionary = NULL;
			if(CGPDFObjectGetValue(encodingObj, type, &encodingDictionary)) {
				
				CGPDFArrayRef differences;
				
				if(CGPDFDictionaryGetName(encodingDictionary, "BaseEncoding", &base_encoding)) {
					
					//fprintf(stdout,"Base encoding: %s\n",base_encoding);
					
					if (strcmp(base_encoding,"MacRomanEncoding")==0) {
						
                        
#if DEBUG & FPK_DEBUG_ENCODING
                        fprintf(stdout,"Difference MacRoman encoder\n");
#endif
                        
						encoder = malloc(sizeof(MFFontEncoder));
						initFontEncoderWithEncoding(encoder, MFFontEncodingMacRoman);
						
					} else if (strcmp(base_encoding,"WinAnsiEncoding")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
                        fprintf(stdout,"Difference WinAnsi encoder\n");
#endif
						encoder = malloc(sizeof(MFFontEncoder));
						initFontEncoderWithEncoding(encoder, MFFontEncodingWinAnsi);
						
					} else if (strcmp(base_encoding,"MacExpertEncoding")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
                        fprintf(stdout,"Difference MacExpert encoder\n");
#endif
						encoder = malloc(sizeof(MFFontEncoder));
						initFontEncoderWithEncoding(encoder, MFFontEncodingMacRoman);
						
					} else { // Standard encoding.
#if DEBUG & FPK_DEBUG_ENCODING
                        fprintf(stdout,"Difference Standard encoder\n");
#endif
						encoder = malloc(sizeof(MFFontEncoder));
						initFontEncoder(encoder);
					}
					
				} else {
					
					//fprintf(stdout,"Base encoding not found, defaulting to Standard\n");
#if DEBUG & FPK_DEBUG_ENCODING
                    fprintf(stdout,"Unknow encoder\n");
#endif
					encoder = malloc(sizeof(MFFontEncoder));
					initFontEncoder(encoder);	
				}
				
				if(CGPDFDictionaryGetArray(encodingDictionary, "Differences", &differences)) {
					
					differences_count = CGPDFArrayGetCount(differences);
					size_t index;
					
					unsigned char code;
					BOOL validCode = NO;
					
					for(index = 0; index < differences_count; index++) {
						
						CGPDFObjectRef differencesEntry;
						CGPDFObjectType entryType;
					
						if(CGPDFArrayGetObject(differences, index, &differencesEntry)) {
						
							entryType = CGPDFObjectGetType(differencesEntry);
							
							if(entryType == kCGPDFObjectTypeName) {
								
								char * name = NULL;
								
								// Skip to the next entry if the last code was not valid.
								if(validCode) {
								
									if(CGPDFObjectGetValue(differencesEntry, kCGPDFObjectTypeName, &name)) {
                                        
                                        // fprintf(stdout,"name valid %s\n",name);
                                        
										fontEncoderSetUnicodeForCode(encoder, name, code);
#if DEBUG & FPK_DEBUG_ENCODING
										differences_applied++;
#endif
									}
									
									code++;
								}
								
							} else if (entryType == kCGPDFObjectTypeInteger) {
								
								unsigned long int tmpCode;
								
								if(CGPDFObjectGetValue(differencesEntry, kCGPDFObjectTypeInteger, &tmpCode)) {
									code = tmpCode;
									validCode = YES;
								} else {
									validCode = NO;
								}
								
							} else {
								
#if DEBUG & FPK_DEBUG_ENCODING
								NSLog(@"Strange value found in the difference array");
#endif
								
								// Found something strange, unset the flag untile a valid code is found.
								validCode = NO;
								
							}
						}
					}
				}
			}
		}
		
#if DEBUG & FPK_DEBUG_ENCODING
		fprintf(stdout, "Encoding type: %s\n",encoding);
		fprintf(stdout, "Base encoding: %s\n",base_encoding);
		fprintf(stdout, "Differences applied: %d\n", differences_applied);
#endif
	}
	
	return encoder;
}

void parseToUnicodeCMapFileMultibyte (const char * filename, void * info) {
    
    MFUnicodeCluster * unicodeRanges = (MFUnicodeCluster *)info;
    
    NSString * filePath = [[NSBundle mainBundle]pathForResource:[NSString stringWithUTF8String:filename] ofType:@"cidf"];
    NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
    
    //NSURL * fileUrl = [[NSBundle mainBundle]URLForResource:[NSString stringWithUTF8String:filename] withExtension:@"cidf"]; // Does not work on < 4.0
    
    NSData * data = nil;
    int data_length = 0;
    char * stringbuffer = NULL;
    
    MFToUnicodeCMapScannerMultibyte * cmapScanner = nil;
    
    
    if(unicodeRanges == nil || fileUrl == nil)
        return;
    
    data = [[NSData alloc]initWithContentsOfURL:fileUrl];
    data_length = [data length];
    
    stringbuffer = calloc(data_length+1, sizeof(char));
    
    CFDataGetBytes((CFDataRef)data, CFRangeMake(0, data_length), (unsigned char *)stringbuffer);
    
    cmapScanner = [[MFToUnicodeCMapScannerMultibyte alloc]init];
    cmapScanner.unicodeRanges = unicodeRanges;
    cmapScanner.stringbuffer = stringbuffer;
    
    [cmapScanner scan];
    
    
    // Cleanup.
    
    [cmapScanner release];
    
    if(stringbuffer)
        free(stringbuffer);
    
    [data release];
}

void parseToUnicodeCMapStreamMultibyte(CGPDFStreamRef cMapStream, void * info) {
        
    MFUnicodeCluster * unicodeRanges = (MFUnicodeCluster *)info;    /* Unicode ranges */
    CGPDFDictionaryRef cMapDictionary = NULL;                       /* Stream dictionary */
	
    const char * cMapName = NULL;                                   /* Name of this cmap */
    const char * useCMapName = NULL;                                /* Name of the parent cmap */
    CGPDFStreamRef useCMapStream = NULL;                            /* Stream of the parent cmap */
    CGPDFObjectRef useCMapObj = NULL;                               /* Obj of the parent cmap */
    
    CFDataRef data = NULL;                                          /* Stream's data */
	int dataLength = 0;                                             /* Data length */
	char * buffer = NULL;                                           /* String buffer */
    
    MFToUnicodeCMapScannerMultibyte * cMapScanner = nil;            /* Scanner */
    
    if(unicodeRanges == NULL || cMapStream == NULL)
        return;
    
    cMapDictionary = CGPDFStreamGetDictionary(cMapStream);
	
#if DEBUG & FPK_DEBUG_ENCODING
	printf("Begin parsing of ToUnicode CMap stream.\n");
#endif
	
	if(cMapDictionary) {
        
        if(CGPDFDictionaryGetName(cMapDictionary, "CMapName", &cMapName)) {
#if DEBUG & FPK_DEBUG_ENCODING
            printf("CMapName: %s\n",cMapName);
#endif            
        }

		if(CGPDFDictionaryGetObject(cMapDictionary, "UseCMap", &useCMapObj)) {
            
			CGPDFObjectType type = CGPDFObjectGetType(useCMapObj);
			if(type == kCGPDFObjectTypeStream) {
				
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: stream\n");
#endif
                if(CGPDFObjectGetValue(useCMapObj, type, &useCMapStream)) {
                 
                    // Recursive call.
                    parseToUnicodeCMapStreamMultibyte(useCMapStream, unicodeRanges);
                    
                }
				
			} else if (type == kCGPDFObjectTypeName) {
				
				if(CGPDFObjectGetValue(useCMapObj, type, &useCMapName)) {
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: %s\n",useCMapName);
#endif
                    
                    parseToUnicodeCMapFileMultibyte(useCMapName, unicodeRanges);
                    
                }
			} else {
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: unknow value\n");
#endif
			}
		} else {
#if DEBUG & FPK_DEBUG_ENCODING
			printf("UseCMap: none (no need to parse a parent CMap)\n");
#endif
		}
		
	} else {
#if DEBUG & FPK_DEBUG_ENCODING
		printf("CMap dictionary not found\n");
#endif
	}
    
    data = CGPDFStreamCopyData(cMapStream, CGPDFDataFormatRaw);
	dataLength = CFDataGetLength(data);
	
	buffer = calloc(dataLength+1,sizeof(char));
	
	CFDataGetBytes(data, CFRangeMake(0, dataLength), (unsigned char *)buffer);
    
	cMapScanner = [[MFToUnicodeCMapScannerMultibyte alloc]init];
    cMapScanner.stringbuffer = buffer;
	cMapScanner.unicodeRanges = unicodeRanges;
	
    
    [cMapScanner scan];
    
    // Cleanup.
    
    if(buffer)
        free(buffer),buffer=NULL;
    if(data)
        CFRelease(data);
    
    [cMapScanner release];
    
#if DEBUG & FPK_DEBUG_ENCODING
	printf("Ended parsing of ToUnicode CMap stream.\n");
#endif
    
}

void parseCidFontStream(CGPDFStreamRef cidStream, void * info) {
    
    MFFontDataType0 * fontData = (MFFontDataType0 *)info;
    
    CGPDFDictionaryRef cMapDictionary = CGPDFStreamGetDictionary(cidStream);
	
	long int number;
	CGPDFDictionaryGetInteger(cMapDictionary, "Length", &number);
	
#if DEBUG & FPK_DEBUG_ENCODING
	printf("CIDFont CMap begin\n");
#endif
	
	if(cMapDictionary!=NULL) {
        
		const char * cMapName = NULL;
		const char * useCMapName = NULL;
		
		CGPDFStreamRef useCMapStream = NULL;
		CGPDFObjectRef useCMapObj = NULL;
		
		if(CGPDFDictionaryGetObject(cMapDictionary, "UseCMap", &useCMapObj)) {
            
			CGPDFObjectType type = CGPDFObjectGetType(useCMapObj);
			if(type == kCGPDFObjectTypeStream) {
				
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: stream\n");
#endif
                if(CGPDFObjectGetValue(useCMapObj, type, &useCMapStream)) {
                    
                    // Recursive call.
                    
                    parseCidFontStream(useCMapStream, fontData);
                    
                }
				
			} else if (type == kCGPDFObjectTypeName) {
				
				if(CGPDFObjectGetValue(useCMapObj, type, &useCMapName)) {
#if DEBUG & FPK_DEBUG_ENCODING
                    printf("UseCMap: %s\n",useCMapName);
#endif
                    
                    parseCIDFontFile(useCMapName, fontData);
                    
                }
			} else {
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: unknow value\n");
#endif
			}
		} else {
#if DEBUG & FPK_DEBUG_ENCODING
			printf("UseCMap: none\n");
#endif
		}
		
		CGPDFDictionaryGetName(cMapDictionary, "CMapName", &cMapName);
#if DEBUG & FPK_DEBUG_ENCODING
		printf("CMapName: %s\n",cMapName);
#endif
		
		
	} else {
#if DEBUG & FPK_DEBUG_ENCODING
		printf("CMap dictionary not found\n");
#endif
	}
	
    
    CFDataRef data = CGPDFStreamCopyData(cidStream, CGPDFDataFormatRaw);
	
	int dataLength = CFDataGetLength(data);
	
	char * buffer = calloc(dataLength+1,sizeof(char));
	
	CFDataGetBytes(data, CFRangeMake(0, dataLength), (unsigned char *)buffer);
    
	MFCIDFontScanner *cfScanner = [[MFCIDFontScanner alloc]init];
    cfScanner.stringbuffer = buffer;
	cfScanner.cidRanges = fontData.cidRanges;
	cfScanner.notdefCids = fontData.undefinedCids;
    
    [cfScanner scan];
    
    if(cfScanner.writingMode == 1) {
        fontData.writingMode = 1;
    }
    
    // Cleanup.
    
    if(buffer)
        free(buffer),buffer=NULL;
    if(data)
        CFRelease(data);
    
    [cfScanner release];
    
#if DEBUG & FPK_DEBUG_ENCODING
	printf("CIDFont CMap end\n");
#endif
}

void parseCIDFontFile(const char * filename, void * info) {
    
    MFFontDataType0 * fontData = (MFFontDataType0 *)info;
    
    // NSData * data = nil;
    char * data_string = NULL;
    
    if(strcmp(filename, "Identity-H") == 0 ) {
        
//        data = [[NSData alloc]initWithBytes:fpk_cidf_identity_h length:fpk_cidf_identity_h_len];
//        data_length = fpk_cidf_identity_h_len;
        
        data_string = calloc(fpk_cidf_identity_h_len+1, sizeof(unsigned char));
        memcpy(data_string, fpk_cidf_identity_h, fpk_cidf_identity_h_len);
        
    }
    else if (strcmp(filename, "Identity-V") == 0) {
        
//        data = [[NSData alloc]initWithBytes:fpk_cidf_identity_v length:fpk_cidf_identity_v_len];
//        data_length = fpk_cidf_identity_v_len;
        
        data_string = calloc(fpk_cidf_identity_v_len+1, sizeof(unsigned char));
        memcpy(data_string, fpk_cidf_identity_v, fpk_cidf_identity_v_len);
        
        fontData.writingMode = 1;
        
    }
    else {
        
            NSLog(@"Loading external CID file %s", filename);
 
            // NSURL * fileUrl = [[NSBundle mainBundle]URLForResource:[NSString stringWithUTF8String:filename] withExtension:@"cidf"]; // Does not work on < 4.0
            
            NSString * filePath = [[NSBundle mainBundle]pathForResource:[NSString stringWithUTF8String:filename] ofType:nil];
        
            if(filePath) {
            NSURL * fileUrl = [NSURL fileURLWithPath:filePath];

            NSData * data = [[NSData alloc]initWithContentsOfURL:fileUrl];
            int data_length = [data length];
    
            data_string = calloc(data_length+1, sizeof(char));
    
            CFDataGetBytes((CFDataRef)data, CFRangeMake(0, data_length), (unsigned char *)data_string);
            [data release];
        }
}
    
    MFCIDFontScanner * cidFontScanner = [[MFCIDFontScanner alloc]init];
    cidFontScanner.cidRanges = fontData.cidRanges;
    cidFontScanner.notdefCids = fontData.undefinedCids;
    cidFontScanner.stringbuffer = data_string;
    
    [cidFontScanner scan];
    
    if(cidFontScanner.writingMode == 1) {
        fontData.writingMode = 1;
    }
    
    // Cleanup.
    
    [cidFontScanner release];
    
    if(data_string)
        free(data_string);
    
//    [data release];
}

void parseToUnicodeCMapStream(CGPDFStreamRef cMapStream, void * info) {
	
	//ScannerInfo *scannerInfo = (ScannerInfo *)info;
	MFFontEncoder * encoder = (MFFontEncoder *)info;
	
	CGPDFDictionaryRef cMapDictionary = CGPDFStreamGetDictionary(cMapStream);
	
	long int number;
	CGPDFDictionaryGetInteger(cMapDictionary, "Length", &number);
    
    const char * cMapName = NULL;
    const char * useCMapName = NULL;
    
    CGPDFObjectRef useCMapObj = NULL;
	
    MFToUnicodeCMapScanner *cMapScanner = nil;
    
#if DEBUG & FPK_DEBUG_ENCODING
	printf("ToUnicode CMap begin\n");
#endif
	
		
	if(cMapDictionary!=NULL) {
	
		
		if(CGPDFDictionaryGetObject(cMapDictionary, "UseCMap", &useCMapObj)) {
		
			CGPDFObjectType type = CGPDFObjectGetType(useCMapObj);
			if(type == kCGPDFObjectTypeStream) {
				
#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: stream\n");
#endif
				
			} else if (type == kCGPDFObjectTypeName) {
				
				CGPDFObjectGetValue(useCMapObj, type, &useCMapName);
				#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: %s\n",useCMapName);
				#endif
			} else {
			#if DEBUG & FPK_DEBUG_ENCODING
				printf("UseCMap: unknow value\n");
				#endif
			}
		} else {
		#if DEBUG & FPK_DEBUG_ENCODING
			printf("UseCMap: none\n");
			#endif
		}
		
		CGPDFDictionaryGetName(cMapDictionary, "CMapName", &cMapName);
#if DEBUG & FPK_DEBUG_ENCODING & FPK_DEBUG_ENCODING
		printf("CMapName: %s\n",cMapName);
#endif
		
		
	} else {
#if DEBUG & FPK_DEBUG_ENCODING
		printf("CMap dictionary not found\n");
#endif
	}
	
	
	cMapScanner = [[MFToUnicodeCMapScanner alloc]init];
	cMapScanner.cmapStream = cMapStream;
	cMapScanner.encoder = encoder;
	[cMapScanner scan];
    
    // Cleanup.
    
    [cMapScanner release];
    
#if DEBUG & FPK_DEBUG_ENCODING
	printf("ToUnicode CMap end\n");
#endif
    
}

void readFontMatrix(CGPDFArrayRef matrixArray, float * matrix) {

	float value = 0.0f;
	CGPDFObjectRef object = NULL;
	CGPDFObjectType type;
	int count;
    
    count = CGPDFArrayGetCount(matrixArray);
	
	if(count > 6)
		count = 6;
	
	int i;
	for(i = 0; i < count; i++) {
		
		CGPDFArrayGetObject(matrixArray, i, &object);
		type = CGPDFObjectGetType(object);
		
		if(type == kCGPDFObjectTypeReal) {
			
			CGPDFObjectGetValue(object, type, &value);
			
			
		} else if (type == kCGPDFObjectTypeInteger) {
			
			long int tmp;
			CGPDFObjectGetValue(object, type, &tmp);
			value = (float)tmp;
			
		} else {
			value = 0.0f;
		}
		
		*(matrix+i) = value;
	}
}

size_t readWidthsArray256 (CGPDFArrayRef widthsArray, CGFloat * widths) {
	
	size_t count = CGPDFArrayGetCount(widthsArray);
	
	if(count>256)
		count = 256;
	
	size_t i;
	for(i = 0; i < count; i++) {
		CGPDFReal v;
		CGPDFArrayGetNumber(widthsArray, i, &v);
		widths[i] = v;
	}
	return count;
}

void parseCIDFontWidthArray(CGPDFArrayRef widthArray, void * info) {
    
    MFWidthCluster * widthRanges = (MFWidthCluster *)info;
    
    size_t count = CGPDFArrayGetCount(widthArray);
    size_t index = 0;
    
    CGPDFObjectRef obj = NULL;
    CGPDFObjectType type;
    
    unsigned int step = 0;
    
    unsigned int cid_first = 0;
    unsigned int cid_last = 0;
    long int width = 0;
    
    MFWidthRangeMulti * multiRange = nil;
    MFWidthRangeSingle * singleRange = nil;
    
    // We can have either 
    //  c [w1 w2 ... wn]
    // or 
    // c1 c2 w
    // as elements inside the array.
    
    while(index < count) {
        
        CGPDFArrayGetObject(widthArray, index, &obj);
        type = CGPDFObjectGetType(obj);
        
        if(type == kCGPDFObjectTypeInteger) {
            
            if(step == 0) {
                
                CGPDFObjectGetValue(obj, type, &cid_first);
                step++;
               
                
            } else if (step == 1) {
                
                CGPDFObjectGetValue(obj, type, &cid_last);
                step++;
                
            } else if (step == 2) {
                
                CGPDFObjectGetValue(obj, type, &width);
                
                singleRange = [[MFWidthRangeSingle alloc]initWithFirstCid:cid_first lastCid:cid_last andWidth:(float)width];
                [widthRanges addRange:singleRange];
                [singleRange release],singleRange = nil;
                
                step = 0;
            }
            
            
        } else if (type == kCGPDFObjectTypeArray) {
            
            // Loop over the width sub array.
            CGPDFArrayRef subArray = NULL;
            size_t subarray_count = 0;
            size_t subarray_index = 0;
            
            CGPDFObjectGetValue(obj, type, &subArray);
            
            subarray_count = CGPDFArrayGetCount(subArray);
            
            multiRange = [[MFWidthRangeMulti alloc]initWithFirstCid:cid_first andCount:subarray_count];
            
            subarray_index = 0;
            while(subarray_index < subarray_count) {
                
                if(CGPDFArrayGetInteger(subArray, subarray_index, &width)) {
                    [multiRange addWidth:(float)width];
                   
                } else {
                    
                    // Skip it.
                    [multiRange addWidth:0.0];
                }
                
                subarray_index++;
            }
            
            [widthRanges addRange:multiRange];
            [multiRange release],multiRange = nil;
            
            step = 0;
        }
        
        index++;
    }
}

void parseCIDFontDictionary(CGPDFDictionaryRef dictionary, void * info) {
    
    CGPDFDictionaryRef fontDescriptorDictionary = NULL;     /* (Required) Font Descriptor dictionary */
    MFFontDataType0 * fontData = (MFFontDataType0 *)info;   /* MFFontData structure for Type 0 font */
    
    long int dw = 0;                                        /* (Optional) Default width */
    CGPDFArrayRef dwArray = NULL;                           /* (Optional) Widths array */
    
    __unused CGPDFArrayRef dw2Array = NULL;                          /* (Optional) Default displacement array for vertical writing */
    __unused CGPDFArrayRef w2Array = NULL;                          /* (Optional) Default width array for vertical writing */
    
    CGPDFReal ascent = 0.0;
    CGPDFReal descent = 0.0;
    CGPDFReal missingWidth = 0.0;
    const char * fontName;

    if(CGPDFDictionaryGetDictionary(dictionary, "FontDescriptor", &fontDescriptorDictionary)) {
        
        if(CGPDFDictionaryGetName(fontDescriptorDictionary, "FontName", &fontName))
        {
            // NSLog(@"FD font name : (%s)",fontName);
        }
        
        if(CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Ascent", &ascent))
        {
            fontData.ascent = ascent;
        }
        
        if(CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Descent", &descent))
        {
            fontData.descent = descent;
        }
        
        if(CGPDFDictionaryGetNumber(fontDescriptorDictionary, "MissingWidth", &missingWidth)) {
            
            fontData.missingWidth = missingWidth;
        }
        
    }
    
    if(CGPDFDictionaryGetInteger(dictionary, "DW", &dw)) {
        
        fontData.defaultWidth  = (float)dw;
    }
    
    if(CGPDFDictionaryGetArray(dictionary, "W", &dwArray)) {
        
        parseCIDFontWidthArray(dwArray, fontData.widthRanges);
    }
    
//    if(CGPDFDictionaryGetObject(dictionary, "DW2", &obj)) {
//       // NSLog(@"DW2 found");
//    }
//    
//    if(CGPDFDictionaryGetObject(dictionary, "W2", &obj)) {
//        // NSLog(@"W2 found");
//    }
}

void sniffType0Font(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info) {
	
    MFFontDataType0 * fontData = [[MFFontDataType0 alloc]init];
    // NSMutableDictionary * fonts = (NSMutableDictionary *)info;
    
	const char *type, *subtype, *basefont;              // (Required) Type, subyte and base font for the font.
	
	CGPDFObjectRef encodingObj = NULL;					// (Required) Name or stream with the CMap to map byte sequences to CID.
    CGPDFStreamRef encodingStream = NULL;
    const char * encodingName = NULL;
    
	CGPDFArrayRef descendantFontsArray = NULL;                 // (Required) Single element array with the CIDFont dictionary.
	CGPDFDictionaryRef descendantFontsDictionary = NULL;
	
	CGPDFStreamRef toUnicodeStream = NULL;                    // (Optional) Stream with a CMap to convert CID to Unicode values.
	
	CGPDFDictionaryGetName(fontDictionary, "Type", &type);
	CGPDFDictionaryGetName(fontDictionary, "Subtype", &subtype);
	CGPDFDictionaryGetName(fontDictionary, "BaseFont", &basefont);
    
#if DEBUG & FPK_DEBUG_ENCODING
    fprintf(stdout,"Sniffing font %s\n",key);
	fprintf(stdout,"Type: %s\nSubtype: %s\nBaseFont: %s\n",type, subtype, basefont);
#endif
    
	if(CGPDFDictionaryGetObject(fontDictionary, "Encoding", &encodingObj)) {
		
        // Character codes to CID. It is either a name of the Cmap or a stream.
        
		CGPDFObjectType encodingObjectType = CGPDFObjectGetType(encodingObj);
		
		if(encodingObjectType == kCGPDFObjectTypeName) {
			
			if(CGPDFObjectGetValue(encodingObj, encodingObjectType, &encodingName)) {
				
#if DEBUG & FPK_DEBUG_ENCODING
				fprintf(stdout,"Will load encoding by name (%s)\n",encodingName);
#endif
                
                parseCIDFontFile(encodingName, fontData);
                
			}
            
		} else if (encodingObjectType == kCGPDFObjectTypeStream) {
			
			
			if(CGPDFObjectGetValue(encodingObj, encodingObjectType, &encodingStream)) {
				
#if DEBUG & FPK_DEBUG_ENCODING
				fprintf(stdout,"Will parse encoding CMap stream\n");
#endif
                parseCidFontStream(encodingStream, fontData);
			}
		}
	}
	
    /*
     Here we try to recover a CMap to get the unicode conversion of the font.
     */
	if(CGPDFDictionaryGetArray(fontDictionary, "DescendantFonts", &descendantFontsArray)) {
        
		if(CGPDFArrayGetDictionary(descendantFontsArray, 0, &descendantFontsDictionary)) {
		
            parseCIDFontDictionary(descendantFontsDictionary, fontData);
            
            CGPDFDictionaryRef cidSystemInfoDictionary = NULL;
            
            if(CGPDFDictionaryGetDictionary(descendantFontsDictionary, "CIDSystemInfo", &cidSystemInfoDictionary)) {
                
                // This contains the metric of the font.
                
                // char * registry = NULL;
                // char * ordering = NULL;
                // long int supplement = 0;

                CGPDFStringRef asciiString = NULL;
                CFStringRef registryString = NULL;
                CFStringRef orderingString = NULL; 

                NSString * mappingResourceFile = nil;
                NSString * mappingResourceFilePath = nil;
                NSURL * mappingResourceFileURL = nil;
                
                if(CGPDFDictionaryGetString(cidSystemInfoDictionary, "Registry", &asciiString)) {
                    registryString = CGPDFStringCopyTextString(asciiString);
                }
                
                if(CGPDFDictionaryGetString(cidSystemInfoDictionary, "Ordering", &asciiString)) {
                    orderingString = CGPDFStringCopyTextString(asciiString);
                }
                
                // CGPDFDictionaryGetInteger(cidSystemInfoDictionary, "Supplement", &supplement);
                
                
                mappingResourceFile = [[NSString alloc]initWithFormat:@"%@-%@-UCS2", (NSString *)registryString, (NSString *)orderingString];

                mappingResourceFilePath = [[NSBundle mainBundle]pathForResource:mappingResourceFile ofType:nil];
                
                if(mappingResourceFilePath) {
                    
                    mappingResourceFileURL = [NSURL fileURLWithPath:mappingResourceFilePath];
                    
                    NSData * data = nil;
                    NSUInteger data_length = 0;
                    char * data_string = NULL;
                    
                    data = [[NSData alloc]initWithContentsOfURL:mappingResourceFileURL];
                    data_length = [data length];
                    
                    data_string = calloc(data_length+1, sizeof(char));
                    
                    CFDataGetBytes((CFDataRef)data, CFRangeMake(0, data_length), (unsigned char *)data_string);

                    MFToUnicodeCMapScannerMultibyte * cMapScanner = [[MFToUnicodeCMapScannerMultibyte alloc]init];
                    cMapScanner.stringbuffer = data_string;
                    cMapScanner.unicodeRanges = fontData.unicodeRanges;
                    
                    [cMapScanner scan];

                    [cMapScanner release];
                    
                    if(data_string)
                        free(data_string);
                    [data release];
                }
                
                if(orderingString)
                    CFRelease(orderingString);
                if(registryString)
                    CFRelease(registryString);
                
                [mappingResourceFile release];
            }
            
            /*
             
             // Of no use to this date
             
             CGPDFObjectRef cidToGIDMapObject = NULL;
            if(CGPDFDictionaryGetObject(descendantFontsDictionary, "CIDToGIDMap", &cidToGIDMapObject)) 
             {
                NSLog(@"Type 2 CIDFont");
                
                CGPDFObjectType type = CGPDFObjectGetType(cidToGIDMapObject);
                
                if(type == kCGPDFObjectTypeStream) 
             {
                    NSLog(@"Stream");
                    CGPDFStreamRef cidStream = NULL;
                    if(CGPDFObjectGetValue(cidToGIDMapObject, kCGPDFObjectTypeStream, &cidStream)) 
             {
                        CFDataRef data = CGPDFStreamCopyData(cidStream, CGPDFDataFormatRaw);
                        NSLog(@"%@",[(NSData *)data description]);
                        if(data)
                            CFRelease(data);
             }
                    
             }
             else if (type == kCGPDFObjectTypeName)
             {
                    const char * name = NULL;
                    CGPDFObjectGetValue(cidToGIDMapObject, kCGPDFObjectTypeName, &name);
                    NSLog(@"Name %s",name);
                }
            }
             */
		}
	}
    
	
    CGPDFObjectRef unicodeStreamObject = NULL;
	if(CGPDFDictionaryGetObject(fontDictionary, "ToUnicode", &unicodeStreamObject)) {
	
#if DEBUG & FPK_DEBUG_ENCODING
		fprintf(stdout,"Will parse ToUnicode CMap stream (multibyte)\n");
#endif
        
        if(CGPDFObjectGetValue(unicodeStreamObject, kCGPDFObjectTypeStream, &toUnicodeStream)) {
           parseToUnicodeCMapStreamMultibyte(toUnicodeStream, fontData.unicodeRanges);		
        }
        
	} else {
        
#if DEBUG & FPK_DEBUG_ENCODING
		fprintf(stdout,"Missing ToUnicode CMap stream\n");
#endif
            
    }
    
    fontData.valid = YES;
    
    *info = fontData;
    // NSLog(@"%@",fontData);
    
//	[fonts setValue:fontData forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
//	[fontData release];
}

void parseFPKFMFile(const char * font_name, MFFontData * fontData) {
    
    FILE * file = NULL;
    
    NSString * fileName = nil;
    NSString * path = nil;
    const char * file_path = NULL;
    char line [30] = {0};
    int step = 0;
    
    float ascent = 0.0;
    float descent = 0.0;
    int index;
    int count;
    int first_cid = 0;
    int last_cid = 0;
    int done = 0;
    int cid;
    float width;
    unsigned int unicode;
    char * comment = NULL;
    CGFloat widths[255] = {0};
    
    MFFontEncoder * encoder = NULL;
    
    // Lookup the file in the application bundle.
    fileName = [[NSString alloc]initWithCString:font_name encoding:NSUTF8StringEncoding];
    path = [[NSBundle mainBundle]pathForResource:fileName ofType:@"fpkfm"];
    [fileName release];
    
    if(!path)
        return;
    
    file_path = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Open the file at path.
    file = fopen(file_path,"r");
    if(!file)
        return;
    
    done = 0;
    index = 0;
    
    while(fgets(line, 30, file) && (!done)) {
        
        comment = strchr(line, '#');
        if(comment)
            *comment = 0;
        
        if(!(strlen(line)>0))
           continue;
        
        switch (step) {
            case 0:
                sscanf(line, "%f",&ascent);
                step++;
                break;
            case 1:
                sscanf(line, "%f",&descent);
                step++;
                break;
            case 2:
                sscanf(line, "%d",&first_cid);
                step++;
                break;
            case 3:
                sscanf(line, "%d",&last_cid);
                step++;
                break;
            case 4:
                sscanf(line, "%d",&count);
                step++;
                break;
            case 5:
                sscanf(line, "%d;%f;%u;", &cid, &width, &unicode);
                widths[index] = width;
                index++;
                if(index == count) {
                    step++;
                    done = 1;
                }
                break;
            default:
                done = 1;
                break;
        }
    }
    
    // Metrics.
    fontData.ascent = ascent;
    fontData.descent = descent;
    fontData.firstChar = first_cid;
    fontData.lastChar = last_cid;
    [fontData setWidths:widths length:count];
    
    // Encoding.
    encoder = calloc(1, sizeof(MFFontEncoder));
    initFontEncoderWithEncoding(encoder,MFFontEncodingStandard);
    fontData.encoder = encoder;
}

void sniffType1Font(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info) {
	
	MFFontData * fontData = nil;
	// NSMutableDictionary * fonts = (NSMutableDictionary *)info;
	
	const char *type, *subtype, *basefont, *name;		// (Required) Type, subyte and base font for the font.
    type = subtype = basefont = name = NULL;
    
	long int firstchar = 0, lastchar = 0;		// (Required but 14s) First and last character code.
	
	CGPDFArrayRef widthsArray = NULL;			// (Required but 14s) Array with the widths of each glyph.
	CGFloat widths [256];
	int widths_len = 256;
	
	CGPDFDictionaryRef fontDescriptorDictionary;	// (Required but 14s) Extra font metrics.
	CGPDFReal missingwidth = 0, ascent=0, descent=0;
	
	CGPDFObjectRef encodingObj = NULL;			// (Optional) Name or dictionary.
	MFFontEncoder * encoder = NULL;
	
	CGPDFStreamRef toUnicodeStream = NULL;		// (Optional) A stream with the ToUnicode CMap.
	
    fontData = [[MFFontDataType1 alloc]init];
    
	CGPDFDictionaryGetName(fontDictionary, "Type", &type);
	CGPDFDictionaryGetName(fontDictionary, "Subtype", &subtype);
	CGPDFDictionaryGetName(fontDictionary, "BaseFont", &basefont);
	CGPDFDictionaryGetName(fontDictionary, "Name", &name);
    
#if DEBUG & FPK_DEBUG_ENCODING
    fprintf(stdout,"Sniffing font %s\n",key);
    fprintf(stdout,"Type: %s\n",type);
    fprintf(stdout,"Subtype: %s\n",subtype);
    fprintf(stdout,"BaseFont: %s\n",basefont);
    fprintf(stdout,"Name: %s\n",name);
#endif
    
    // First and last cids.
	if(CGPDFDictionaryGetInteger(fontDictionary, "FirstChar", &firstchar)) {
        fontData.firstChar = firstchar;
    }
    
	if(CGPDFDictionaryGetInteger(fontDictionary, "LastChar", &lastchar)) {
        fontData.lastChar = lastchar;
    }
	
    // Widths array.
	if(CGPDFDictionaryGetArray(fontDictionary, "Widths", &widthsArray)) {
		
		widths_len = readWidthsArray256(widthsArray, widths);
        [fontData setWidths:widths length:widths_len];
	}
	
    // Font descriptor.
	if(CGPDFDictionaryGetDictionary(fontDictionary, "FontDescriptor", &fontDescriptorDictionary)) {
		
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "MissingWidth", &missingwidth);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Ascent", &ascent);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Descent", &descent);

        fontData.missingWidth = missingwidth;
        fontData.ascent = ascent;
        fontData.descent = descent;
      
#if DEBUG & FPK_DEBUG_ENCODING
        
        CGPDFStreamRef fontFile, fontFile2, fontFile3;
        char * fontName = NULL;
        CGPDFStringRef charSet = NULL;
        
        if(CGPDFDictionaryGetName(fontDescriptorDictionary, "FontName", &fontName)) {
            fprintf(stdout,"WARNING: Font name is %s\n",fontName);
        }
        
        if(CGPDFDictionaryGetStream(fontDescriptorDictionary, "FontFile", &fontFile)) {      
            
            fprintf(stdout, "WARNING: Font file found\n");
            
        
            CFDataRef fontFileData = NULL;
            fontFileData = CGPDFStreamCopyData(fontFile, CGPDFDataFormatRaw);
            if(fontFileData) {
                
                NSData * data = (NSData *)fontFileData;
                NSString * dataString = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];

                NSLog(@"Content of font file is %@",dataString);

                CFRelease(fontFileData);
                [dataString release];
            }
            
        } else {
            
            fprintf(stdout, "WARNING: Font file not found\n");
        }
        if(CGPDFDictionaryGetStream(fontDescriptorDictionary, "FontFile2", &fontFile2)) {      
            
            fprintf(stdout, "WARNING: Font file 2 found, but not used\n");
        } else {
            fprintf(stdout, "WARNING: Font file 2 not found\n");
        }
        if(CGPDFDictionaryGetStream(fontDescriptorDictionary, "FontFile3", &fontFile3)) {      
            
            fprintf(stdout, "WARNING: Font file 3 found, but not used\n");
            /*
            CFDataRef fontFileData = NULL;
            fontFileData = CGPDFStreamCopyData(fontFile3, CGPDFDataFormatRaw);
            if(fontFileData) {
                
                unsigned char * bytes = CFDataGetBytePtr(fontFileData);
                long int length = CFDataGetLength(fontFileData);
                
                NSData * data = [[NSData alloc]initWithBytes:bytes length:length];
                
                NSString * path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/dump.dat"];
                if(![data writeToFile:path atomically:NO]) {
                    NSLog(@"Failed writing data at %@",path);
                } else {
                    NSLog(@"Successfully written at %@",path);
                }
                [data release];
                
                CFRelease(fontFileData);
            }
            */
        } else {
            fprintf(stdout, "WARNING: Font file 3 not found\n");
        }
        if(CGPDFDictionaryGetString(fontDescriptorDictionary, "CharSet", &charSet)) {
            fprintf(stdout, "WARNING: ChartSet found\n");
        } else {
            fprintf(stdout, "WARNING: CharSet not found\n");
        }
#endif
        
        
	}
	
    // At least one of the required parameters is missing, probably we are
    // dealing with one of the 14 standard font, pre 1.5 pdf specification.
    
    if(!(firstchar && lastchar && widthsArray && fontDescriptorDictionary)) {
        
        // Try to load one of the 14 standard font.
        // NSLog(@"Uncompleted font %s. Will try to load .fpkfm file.",basefont);
        
        parseFPKFMFile(basefont, fontData);
    } 
    
    
    // Parse of the ToUnicode encoding and/or overwrite of the standard
    // 14 font encoding if the encoder is already initiazlied.
    
	if(CGPDFDictionaryGetStream(fontDictionary, "ToUnicode", &toUnicodeStream)) {
     
        
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"ToUnicode CMap found\n");
#endif
		encoder = malloc(sizeof(MFFontEncoder));
		
		initFontEncoder(encoder);
		
		parseToUnicodeCMapStream(toUnicodeStream, encoder);
        
        if(encoder) {
            if(fontData.encoder) {
                deleteFontEncoder(fontData.encoder);
                free(fontData.encoder);
            }
            fontData.encoder = encoder;
        }
        
	} else {
        
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"ToUnicode CMap not found, looking for the Encoding dictionary\n");  
#endif
        
        if(CGPDFDictionaryGetObject(fontDictionary, "Encoding", &encodingObj)) {
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"Encoding dictionary found\n");  
#endif
            
            encoder = fontEncoderForEncoding(encodingObj);
            
            if(encoder) {
                if(fontData.encoder) {
                    deleteFontEncoder(fontData.encoder);
                    free(fontData.encoder);
                }
                fontData.encoder = encoder;
            }
            
        } else {
            
            // Fallback if no enconder has been initialized, either with a 
            // default 14 font or throught Unicode/Dictionary entry in the
            // font dictionary.
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"Encoding dictionary NOT found, cannot generate a valid encoding\n");  
            
#endif
            if(!fontData.encoder) {
                encoder = fontEncoderForEncoding(NULL);    
                fontData.encoder = encoder;
            }
        }
    }
	
//	fontData.ascent = ascent;
//	fontData.descent = descent;
//	[fontData setWidths:widths length:widths_len];
//	fontData.missingWidth = missingwidth;
//	fontData.firstChar = firstchar;
//	fontData.lastChar = lastchar;
	
	if(fontData.encoder) {
		fontData.valid = YES;
	} else {
		fontData.valid = NO;
        
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"Unable to generate a valid encoding\n");
#endif
	}
	
	*info = fontData;
    
//    [fonts setValue:fontData forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
//	[fontData release];
    
}


void sniffTrueTypeFont(CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info) {
	
	MFFontData * fontData = nil;
	//NSMutableDictionary * fonts = (NSMutableDictionary *)info;
	
	const char *type, *subtype, *basefont;		// (Required) Type, subyte and base font for the font.
	
	long int firstchar = 0, lastchar = 0;		// (Required but 14s) First and last character code.
	
	CGPDFArrayRef widthsArray;					// (Required but 14s) Array with the widths of each glyph.
	CGFloat widths [256];
	int widths_len = 256;
	
	CGPDFDictionaryRef fontDescriptorDictionary;	// (Required but 14s) Extra font metrics.
	CGPDFReal missingwidth = 0, ascent=0, descent=0;
	
	CGPDFObjectRef encodingObj = NULL;					// (Optional) Name or dictionary.
	MFFontEncoder * encoder = NULL;
	
	CGPDFStreamRef toUnicodeStream = NULL;			// (Optional) A stream with the ToUnicode CMap.
	
	CGPDFDictionaryGetName(fontDictionary, "Type", &type);
	CGPDFDictionaryGetName(fontDictionary, "Subtype", &subtype);
	CGPDFDictionaryGetName(fontDictionary, "BaseFont", &basefont);
	
	CGPDFDictionaryGetInteger(fontDictionary, "FirstChar", &firstchar);
	CGPDFDictionaryGetInteger(fontDictionary, "LastChar", &lastchar);

#if DEBUG & FPK_DEBUG_ENCODING
    fprintf(stdout,"Sniffing font %s\n",key);
    fprintf(stdout,"Type: %s\n",type);
    fprintf(stdout,"Subtype: %s\n",subtype);
    fprintf(stdout,"BaseFont: %s\n",basefont);
#endif

	if(CGPDFDictionaryGetArray(fontDictionary, "Widths", &widthsArray)) {
		
		widths_len = readWidthsArray256(widthsArray, widths);
	}
	
	if(CGPDFDictionaryGetDictionary(fontDictionary, "FontDescriptor", &fontDescriptorDictionary)) {
		
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "MissingWidth", &missingwidth);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Ascent", &ascent);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Descent", &descent);
	}
    
    
    if(CGPDFDictionaryGetObject(fontDictionary, "Encoding", &encodingObj)) {

#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"TrueType - Encoding dictionary found\n");  
#endif
        
		encoder = fontEncoderForEncoding(encodingObj);
	}
	if((encoder==NULL)&&(CGPDFDictionaryGetStream(fontDictionary, "ToUnicode", &toUnicodeStream))) {
		
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"TrueType - Fall back to CMap Stream\n");  
#endif
        
		encoder = malloc(sizeof(MFFontEncoder));
		
		initFontEncoder(encoder);
		
		parseToUnicodeCMapStream(toUnicodeStream, encoder);
	}
	
	fontData = [[MFFontDataTrueType alloc]init];
	
	fontData.ascent = ascent;
	fontData.descent = descent;
	[fontData setWidths:widths length:widths_len];
	fontData.missingWidth = missingwidth;
	fontData.firstChar = firstchar;
	fontData.lastChar = lastchar;
	
	if(encoder) {
		fontData.encoder = encoder;
		fontData.valid = YES;
	} else {
        
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"WARNING - Unabled to generate a valid encoder\n");
#endif
        
		fontData.valid = NO;	
	}
	
	*info = fontData;
    
//	[fonts setValue:fontData forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
//	[fontData release];
}

void sniffType3Font ( CGPDFDictionaryRef fontDictionary, const char * key, MFFontData ** info ) {
	
	MFFontDataType3 * fontData = nil;
	//NSMutableDictionary * fonts = (NSMutableDictionary *)info;
	
	const char *type, *subtype, *basefont;		// (Required) Type, subyte and base font for the font.
	
	long int firstchar = 0, lastchar = 0;		// (Required) First and last character code.
	
	CGPDFArrayRef matrixArray;					// (Required) Array with the values of the matrix.
	float matrix [6] = {0};	// Font matrix.
	
	CGPDFObjectRef encodingObj;					// (Required) Name or dictionary.
	MFFontEncoder * encoder = NULL;
	
	CGPDFArrayRef widthsArray;					// (Required) Array with the widths of each glyph.
	CGFloat widths [256];
	int widths_len = 256;
	
	CGPDFDictionaryRef fontDescriptorDictionary;	// (Required for Tagged PDF documents) Extra font metrics.
	CGPDFReal missingwidth = 0, ascent=0, descent=0;
	
	CGPDFStreamRef toUnicodeStream;				// (Optional) A stream with the ToUnicode CMap.
	
	// Processing.
	
	CGPDFDictionaryGetName(fontDictionary, "Type", &type);
	CGPDFDictionaryGetName(fontDictionary, "Subtype", &subtype);
	CGPDFDictionaryGetName(fontDictionary, "BaseFont", &basefont);
	CGPDFDictionaryGetInteger(fontDictionary, "FirstChar", &firstchar);
	CGPDFDictionaryGetInteger(fontDictionary, "LastChar", &lastchar);
	
#if DEBUG & FPK_DEBUG_ENCODING
    fprintf(stdout,"Sniffing font %s\n",key);
    fprintf(stdout,"Type: %s\n",type);
    fprintf(stdout,"Subtype: %s\n",subtype);
    fprintf(stdout,"BaseFont: %s\n",basefont);
#endif

	if(CGPDFDictionaryGetArray(fontDictionary, "FontMatrix", &matrixArray)) {
		readFontMatrix(matrixArray, matrix);
	}
	
	if(CGPDFDictionaryGetArray(fontDictionary, "Widths", &widthsArray)) {
	
		widths_len = readWidthsArray256(widthsArray, widths);
	}
	
	if(CGPDFDictionaryGetDictionary(fontDictionary, "FontDescriptor", &fontDescriptorDictionary)) {
		
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "MissingWidth", &missingwidth);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Ascent", &ascent);
		CGPDFDictionaryGetNumber(fontDescriptorDictionary, "Descent", &descent);
	}
	
	if(CGPDFDictionaryGetObject(fontDictionary, "Encoding", &encodingObj)) {
		
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"Type3 - Found encoding entry\n");
#endif
        
		encoder = fontEncoderForEncoding(encodingObj);
	}
	if((!encoder)&&(CGPDFDictionaryGetStream(fontDictionary, "ToUnicode", &toUnicodeStream))) {
		
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"Type3 - Fall back to ToUnicode CMap Stream\n");
#endif
		encoder = malloc(sizeof(MFFontEncoder));
		
		initFontEncoder(encoder);
		
		parseToUnicodeCMapStream(toUnicodeStream, encoder);
	}
	
	fontData = [[MFFontDataType3 alloc]init];
    
	fontData.ascent = ascent;
	fontData.descent = descent;
	[fontData setWidths:widths length:widths_len];
	fontData.missingWidth = missingwidth;
	fontData.firstChar = firstchar;
	fontData.lastChar = lastchar;
	fontData.matrix = CGAffineTransformMake(matrix[0],matrix[1],matrix[2],matrix[3],matrix[4],matrix[5]);
	
	if(encoder) {
		fontData.encoder = encoder;
		fontData.valid = YES;
	} else {
		fontData.valid = NO;	
	}
	
//	[fonts setValue:fontData forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
//	[fontData release];
    
    *info = fontData;
}


void fontDictionarySnifferFunction (
									const char *key,
									CGPDFObjectRef object,
									void *info
									) {
	
#if DEBUG & FPK_DEBUG_ENCODING
	fprintf(stdout,"--- Begin of font dictionary %s ---\n",key);	
#endif
    
    NSString * fontIdentifier = nil;            // Font identifier in the stream (usually like F0, T1_0, etc).
    NSMutableDictionary * fonts = nil;          // Fonts for the current resource.
    NSMutableDictionary * fontCache = nil;      // Font cache, from the doc manager.
    NSString * fontName = nil;
    
    const char * subtypeName = NULL;                // Subtype of the font (Type1, TrueType, etc).
    CGPDFDictionaryRef fontDictionary = NULL;   // Font dictionary.
    const char * baseFontName = NULL;
    MFFontData * fontData = nil;
    
    // Check if the font is already in the cache.
    
    fonts = ((MFStreamScanner *)info).fonts;
    fontCache = ((MFStreamScanner *)info).fontCache;
    
    fontIdentifier = [[NSString alloc]initWithCString:key encoding:NSUTF8StringEncoding];
    
    if(CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &fontDictionary)) {
        
        if(CGPDFDictionaryGetName(fontDictionary, "BaseFont", &baseFontName)) {

        }
        
        if(CGPDFDictionaryGetName(fontDictionary, "Subtype", &subtypeName)) {
            
        }
        
        if(baseFontName && subtypeName) { // Key, base font and subtype (most cases, except type 3)
           
            fontName = [[NSString alloc]initWithFormat:@"font_%s_%s_%s",key,subtypeName,baseFontName];
            
        } else if (baseFontName) { // Key and base font (should never happen, since subtype is always present)
            
            fontName = [[NSString alloc]initWithFormat:@"font_%s_%s",key,baseFontName];
            
        } else if (subtypeName) { // Key and subtype (should work for type 3)
            
            fontName = [[NSString alloc]initWithFormat:@"font_%s_%s",key,subtypeName];
            
        } else { // Key only (should never happens)
            
            fontName = [[NSString alloc]initWithFormat:@"font_%s",key];
        }
        
        if((((MFStreamScanner *)info).useCache) && (fontData = [fontCache valueForKey:fontName])) { // Set the first argument to YES to re-enable the font cache.
            
            // fprintf(stdout, "Cache hit with font name %s for font id (key) %s\n",baseFontName,key);
            // NSLog(@"Font cache hit");
            
            [fonts setObject:fontData forKey:fontIdentifier];
            
        } else {
            
            if(subtypeName) {
                
                if(strcmp(subtypeName, "Type1") == 0) {
                    
                    sniffType1Font(fontDictionary, key, (void *)&fontData);
                    
                } else if (strcmp(subtypeName, "TrueType") == 0) {
                    
                    sniffTrueTypeFont(fontDictionary, key, (void *)&fontData);
                    
                } else if(strcmp (subtypeName, "Type3") == 0) {
                    
                    sniffType3Font(fontDictionary, key, (void *)&fontData);
                    
                } else if (strcmp(subtypeName,"Type0") == 0) {
                    
                    sniffType0Font(fontDictionary, key, (void *)&fontData);
                }
            }
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"Font dictionary type: %s\n",subtypeName);
            fprintf(stdout,"--- End of font dictionary ---\n");	
#endif
            
            // Fallback to invalid Type 0.
            if(!fontData) {
#if DEBUG
                printf("UNSUPPORTED FONT (will use an empty Type 0 as fallback)\n");
#endif
                MFFontDataType0 *fontData = nil;
                
                fontData = [[MFFontDataType0 alloc]init];
                fontData.valid = NO;
                
                [fonts setValue:fontData forKey:fontIdentifier];
                [fontData release];
            } else {
                
                [fontCache setValue:fontData forKey:fontName];
                [fonts setValue:fontData forKey:fontIdentifier];
                [fontData release];
            }
        }
    }
    
    // Cleanup.
    [fontName release];
    [fontIdentifier release];
    
	return;
}

-(void)scan {
	
	ScannerInfo info;
    
	info.state = state;
    info.useCache = useCache;
    
	// Build up the font database.
	CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
    
	CGPDFDictionaryRef resources = NULL;
	CGPDFDictionaryGetDictionary(pageDictionary, "Resources", &resources);
	
	CGPDFDictionaryRef font = NULL;
    
	if(CGPDFDictionaryGetDictionary(resources, "Font", &font)) {
        
        CGPDFDictionaryApplyFunction(font, fontDictionarySnifferFunction, (void *)(self));
        info.fonts = font; // Why does it needs the font dictionary?
	}
    
	// [state setFonts:fontCache];
    
    // There have been occasione where the document has already ben tore down and the returned page
    // was NULL. Under these circumstances, the CGPDFContentStreamCreateWithPage method will crash.
    if(page) {
        
        CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
        
//        CFArrayRef streams = CGPDFContentStreamGetStreams(contentStream);
//        int count = CFArrayGetCount(streams);
//        int i = 0;
//        for (i = 0; i < count; i++) {
//            CGPDFStreamRef substream = CFArrayGetValueAtIndex(streams, i);
//            CGPDFStreamGetDictionary(substream);
//            
//            
//        }
//        
        
        
        info.pageContentStream = contentStream;
        info.resources = resources;
        
        CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, &info);
        
        CGPDFScannerScan(scanner);
        
        CGPDFScannerRelease(scanner);
        CGPDFContentStreamRelease(contentStream);
    }
}

+(CGPDFOperatorTableRef)operatorTable {
    
    static CGPDFOperatorTableRef table = NULL;
    
    if(!table) {
        table = CGPDFOperatorTableCreate();
		
		CGPDFOperatorTableSetCallback(table, "BT", &op_BT);
		CGPDFOperatorTableSetCallback(table, "ET", &op_ET);
        // Text showing.
		CGPDFOperatorTableSetCallback(table, "Tj", &op_Tj);
		CGPDFOperatorTableSetCallback(table, "'", &op_invertedcomma);
		CGPDFOperatorTableSetCallback(table, "\"", &op_quotationmark);
		CGPDFOperatorTableSetCallback(table, "TJ", &op_TJ);
		
		// Text positioning.
		CGPDFOperatorTableSetCallback(table, "Td", &op_Td);
		CGPDFOperatorTableSetCallback(table, "TD", &op_TD);
		CGPDFOperatorTableSetCallback(table, "Tm", &op_Tm);
		CGPDFOperatorTableSetCallback(table, "T*", &op_T_star);
		
		// Text state.
		CGPDFOperatorTableSetCallback(table, "Tc", &op_Tc);
		CGPDFOperatorTableSetCallback(table, "Tw", &op_Tw);
		CGPDFOperatorTableSetCallback(table, "Tz", &op_Tz);
		CGPDFOperatorTableSetCallback(table, "TL", &op_TL);
		CGPDFOperatorTableSetCallback(table, "Tf", &op_Tf);
		CGPDFOperatorTableSetCallback(table, "Tr", &op_Tr);
		CGPDFOperatorTableSetCallback(table, "Ts", &op_Ts);
		
		// Graphic state.
		CGPDFOperatorTableSetCallback(table, "cm", &op_cm);
		CGPDFOperatorTableSetCallback(table, "q", &op_q);
		CGPDFOperatorTableSetCallback(table, "Q", &op_Q);
        
        // Extra
//        CGPDFOperatorTableSetCallback(table, "BMC", &op_markedcontent);
//        CGPDFOperatorTableSetCallback(table, "BDC", &op_markedcontent);
//        CGPDFOperatorTableSetCallback(table, "EMC", &op_markedcontent);
//        CGPDFOperatorTableSetCallback(table, "MP", &op_markedcontent);
//        CGPDFOperatorTableSetCallback(table, "DP", &op_markedcontent);
    }
    
    return table;
}


-(id)initWithTextState:(MFTextState *)aState andPage:(CGPDFPageRef)aPage {
	
	if((self = [super init])) {
		
        NSMutableDictionary * aDictionary = [[NSMutableDictionary alloc]init]; 
        self.fonts = aDictionary;
        [aDictionary release];
        
		page = aPage;
		
		self.state = aState;
		[state setFonts:fonts];
		
		operatorTable = CGPDFOperatorTableRetain([MFStreamScanner operatorTable]);
		
//		CGPDFOperatorTableSetCallback(operatorTable, "BT", &op_BT);
//		CGPDFOperatorTableSetCallback(operatorTable, "ET", &op_ET);
//				// Text showing.
//		CGPDFOperatorTableSetCallback(operatorTable, "Tj", &op_Tj);
//		CGPDFOperatorTableSetCallback(operatorTable, "'", &op_invertedcomma);
//		CGPDFOperatorTableSetCallback(operatorTable, "\"", &op_quotationmark);
//		CGPDFOperatorTableSetCallback(operatorTable, "TJ", &op_TJ);
//		
//		// Text positioning.
//		CGPDFOperatorTableSetCallback(operatorTable, "Td", &op_Td);
//		CGPDFOperatorTableSetCallback(operatorTable, "TD", &op_TD);
//		CGPDFOperatorTableSetCallback(operatorTable, "Tm", &op_Tm);
//		CGPDFOperatorTableSetCallback(operatorTable, "T*", &op_T_star);
//		
//		// Text state.
//		CGPDFOperatorTableSetCallback(operatorTable, "Tc", &op_Tc);
//		CGPDFOperatorTableSetCallback(operatorTable, "Tw", &op_Tw);
//		CGPDFOperatorTableSetCallback(operatorTable, "Tz", &op_Tz);
//		CGPDFOperatorTableSetCallback(operatorTable, "TL", &op_TL);
//		CGPDFOperatorTableSetCallback(operatorTable, "Tf", &op_Tf);
//		CGPDFOperatorTableSetCallback(operatorTable, "Tr", &op_Tr);
//		CGPDFOperatorTableSetCallback(operatorTable, "Ts", &op_Ts);
//		
//		// Graphic state.
//		CGPDFOperatorTableSetCallback(operatorTable, "cm", &op_cm);
//		CGPDFOperatorTableSetCallback(operatorTable, "q", &op_q);
//		CGPDFOperatorTableSetCallback(operatorTable, "Q", &op_Q);
        
        // Marked content.
        //CGPDFOperatorTableSetCallback(operatorTable, "BMC", &op_BMC);
		//CGPDFOperatorTableSetCallback(operatorTable, "EMC", &op_EMC);
		//CGPDFOperatorTableSetCallback(operatorTable, "ReversedChars", &op_ReversedChars);
        //CGPDFOperatorTableSetCallback(operatorTable, "BDC", &op_BDC);
        //CGPDFOperatorTableSetCallback(operatorTable, "MP", &op_MP);
	}
	
	return self;
}



-(void)dealloc {
	
	[state release],state = nil;
	
    fontCache = nil;
    [fonts release],fonts = nil;
    
	CGPDFOperatorTableRelease(operatorTable);
	
	[super dealloc];
	
}


@end
