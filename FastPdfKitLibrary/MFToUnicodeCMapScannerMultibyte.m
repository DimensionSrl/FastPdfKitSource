//
//  MFToUnicodeCMapScannerMultibyte.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFToUnicodeCMapScannerMultibyte.h"
#include <string.h>
#import "MFUnicodeCluster.h"
#import "unbuffer.h"
#include <stdio.h>

#define DELIMITERS "\015\012\014"
#define STATUS_IGNORE 0
#define STATUS_SPACERANGE 1
#define STATUS_BFCHAR 2
#define STATUS_BFRANGE 3

#define SUBSTATUS_CID1 0
#define SUBSTATUS_CID2 1
#define SUBSTATUS_VALUE 2
#define SUBSTATUS_ARRAY 3

#define CMD_SKIP 0
#define CMD_BFRANGE_BEGIN 1
#define CMD_BFRANGE_END 2
#define CMD_BFCHAR_BEGIN 3
#define CMD_BFCHAR_END 4
#define CMD_BFCHAR_CONTINUE 5

@implementation MFToUnicodeCMapScannerMultibyte

@synthesize unicodeRanges, stringbuffer;


int fpk_is_hex(char value) {
    
    static const unsigned char lookup [] = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,    // 0 ... 15
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,    // 16 ... 31
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,    // 32 ... 47
        1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,    // 48 ... 63 
        0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,    // 64 ... 79
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,    // 80 ... 95
        0,1,1,1,1,1,1                       // 96 ... 102
    };
    
    if(value > 102)
        return 0;
    
    return lookup[value]; 
}

int intFromHex (char value) {
    
    static const unsigned char lookup [] = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,        // 48... (0-15)
        0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0,  // 64... (16-31)
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,        // 80... (32-47)
        0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0                     // 96...102 (48-54)
    };
    
    return lookup[value];
};


static int cidWithCString(char * string, int length) {
    
    char * elem;
    int acc = 0;
    for(elem = string; elem < string+length; elem++) {
        acc=(acc*16)+intFromHex(*elem);
    }
    
    return acc;
}

static int unicodesequence(char * string, int length, unsigned int * utf16buffer, int utf16pos) {
    
    char * ptr = string;
    
    int count = length;
    int utf16count = 0;
    int utf16value = 0;
    int hex_count = 0;
    
    while(count--) {
        
        // If it is an hex symbol, parse it.
        
        if(fpk_is_hex(*ptr)) {
            
            hex_count++;
            
            // Increment
            utf16value = (utf16value << 4) | (intFromHex(*ptr));
            
            if(hex_count == 4) {
                
                // Write value to utf16 buffer.
                utf16buffer[utf16count] = utf16value;
                utf16count++;
                utf16value = 0;
                hex_count = 0;
            }
            
        } else { // It could be a space
            
            if(hex_count > 0) {
                
                // Write value to utf16 buffer.
                utf16buffer[utf16count] = utf16value;
                utf16count++;
                hex_count = 0;
                utf16value = 0;
            }
        }
        
        ptr++;
    }
    
    return utf16count;
}

int mergeSurrogatePairs(unsigned int high, unsigned int low) {
    
    return ((high-0xD800)<<10)|(low-0xDC00);
}

-(int)unicodeForString:(char *)start length:(int)length {

if(length < 1)
    
    return 0;

// OK, now we are sure there's at least 1 char. The value is UTF16BE encoded
// this mean they should be multiple of 4 hex values (and maybe spaces?)

int hex_count = 0;
unsigned int utf16_value = 0;
char * ptr = NULL;
int utf16_count = 0;
unsigned int * utf16_buffer = calloc((length)/4+1, sizeof(unsigned int));
int utf16_index = 0 ;
    
    int count = length;

ptr = start;
    
// Loop over the hex values and build up the int value array they represent.
while(count--) {
    
    // If it is an hex symbol, parse it.
    if(fpk_is_hex(*ptr)) {
        
        hex_count++;
        
        // Increment
        utf16_value = (utf16_value << 4) | (intFromHex(*ptr));
        
        
        if(hex_count == 4) {
            
            // Write value to utf16 buffer.
            utf16_buffer[utf16_count] = utf16_value;
            utf16_count++;
            utf16_value = 0;
            hex_count = 0;
        }
        
    } else { // It could be a space
        
        if(hex_count > 0) {
            
            // Write value to utf16 buffer.
            utf16_buffer[utf16_count] = utf16_value;
            utf16_count++;
            hex_count = 0;
            utf16_value = 0;
        }
    }
    
    ptr++;
}

// Now we have an utf16 buffer filled with utf16 values. We need to collapse
// it to full unicode representation by merging surrogate pairs.

utf16_index = 0;
while(utf16_index < utf16_count) {
    
    if(utf16_buffer[utf16_index] < 0xD800 || utf16_buffer[utf16_index] > 0xDFFF) {
        // Leave value intact.
        utf16_index++;
        
    } else {
        
        // fprintf(stdout, "Surrogate pair found!\n");
        
        // Merge the pair and collapse the buffer.
        unsigned int merge = mergeSurrogatePairs(utf16_buffer[utf16_index], utf16_buffer[utf16_index+1]);
        utf16_buffer[utf16_index] = merge;
        int tmp;
        for(tmp = utf16_index+1; tmp < utf16_count-1; tmp++) {
            utf16_buffer[tmp] = utf16_buffer[tmp+1];
        }
        utf16_count--;
        utf16_index++;
    }
}


if(utf16_buffer)
free(utf16_buffer);

return (self->unbuffer.length);

}


int mergeUnicodeBufferInPlace(unsigned int * buffer, int bufferLength) {
    
    int utf16_r_pos = 0;
    int utf16_w_pos = 0;
    
    while(utf16_r_pos < bufferLength) {
        
        if(buffer[utf16_r_pos] < 0xD800 || buffer[utf16_r_pos] > 0xDFFF) {
            // Leave value intact.
            utf16_r_pos++;
            utf16_w_pos++;
            
        } else {
            
            // fprintf(stdout, "Surrogate pair found!\n");
            
            // Merge the pair and collapse the buffer.
            unsigned int merge = mergeSurrogatePairs(buffer[utf16_r_pos], buffer[utf16_r_pos+1]);
            
            buffer[utf16_w_pos] = merge;
            
            utf16_w_pos++;
            utf16_r_pos+=2;
        }
    }
    
    return utf16_w_pos;
}

-(int)unicodeForString:(char *)string {
    
    char * start;
    char * end;
    int length;
    
    start = strchr(string, '<');
    end = strchr(string,'>');
    length = end-start;
    
    if(length < 1)
        return 0;
    
    // OK, now we are sure there's at least 1 char. The value is UTF16BE encoded
    // this mean they should be multiple of 4 hex values (and maybe spaces?)
    
    int hex_count = 0;
    unsigned int utf16_value = 0;
    char * ptr = NULL;
    int utf16_count = 0;
    unsigned int * utf16_buffer = calloc((length)/4+1, sizeof(unsigned int));
    int utf16_index = 0 ;
    
    
    ptr = start;
    // Loop over the hex values and build up the int value array they represent.
    while(ptr!=end) {
    
        
        
        // If it is an hex symbol, parse it.
        if(fpk_is_hex(*ptr)) {
            
            hex_count++;
            
            // Increment
            utf16_value = (utf16_value << 4) | (intFromHex(*ptr));
            
            
            if(hex_count == 4) {
                
                // Write value to utf16 buffer.
                utf16_buffer[utf16_count] = utf16_value;
                utf16_count++;
                utf16_value = 0;
                hex_count = 0;
            }
            
        } else { // It could be a space
            
            if(hex_count > 0) {
                
                // Write value to utf16 buffer.
                utf16_buffer[utf16_count] = utf16_value;
                utf16_count++;
                hex_count = 0;
                utf16_value = 0;
            }
        }
        
        ptr++;
    }
    
    // Now we have an utf16 buffer filled with utf16 values. We need to collapse
    // it to full unicode representation by merging surrogate pairs.
    
    utf16_index = 0;
    while(utf16_index < utf16_count) {
        
        if(utf16_buffer[utf16_index] < 0xD800 || utf16_buffer[utf16_index] > 0xDFFF) {
            // Leave value intact.
            utf16_index++;
            
        } else {
            
            // fprintf(stdout, "Surrogate pair found!\n");
            
            // Merge the pair and collapse the buffer.
            unsigned int merge = mergeSurrogatePairs(utf16_buffer[utf16_index], utf16_buffer[utf16_index+1]);
            utf16_buffer[utf16_index] = merge;
            int tmp;
            for(tmp = utf16_index+1; tmp < utf16_count-1; tmp++) {
                utf16_buffer[tmp] = utf16_buffer[tmp+1];
            }
            utf16_count--;
            utf16_index++;
        }
    }
    
    
    unbuffer_init_with_codepoints(&unbuffer, utf16_buffer, utf16_count);
    
    unbuffer_decompose(&unbuffer);
    
    unbuffer_compose(&unbuffer,unbuffer_compose_mode_canonical);
    
    if(utf16_buffer)
        free(utf16_buffer);
    
    return (self->unbuffer.length);
}

-(void)scan {
    
    if(stringbuffer == NULL)
        return;
    
    char * buffer = stringbuffer;
    char * line = NULL;
    char * ctx = NULL;
    
    char * tempPtr;
    
    int status = STATUS_IGNORE;
	int step = 0;
    
    char * start;
    char * end;
    int length;
    
    int cid0, cid1;
    
    unsigned int utf16buffer [128] = {0};
    int utf16bufferLen = 0;
    
    MFUnicodeRangeMulti * multiRange = nil;
    
    // printf("%s\n", buffer);
    
	for(line = strtok_r(buffer, DELIMITERS, &ctx); line; line = strtok_r(NULL, DELIMITERS, &ctx)) {
        
        if(line[0]=='%')
            continue;
        
        if(status == STATUS_IGNORE) {
            
            if((tempPtr = strstr(line, "beginbf"))) {
                
                if(strstr(tempPtr, "beginbfchar")) {
                    
                    status = STATUS_BFCHAR;
                    
                } else if (strstr(tempPtr, "beginbfrange")) {
                    
                    status = STATUS_BFRANGE;
                }
            }
            
        } else {
            
            
            if((tempPtr = strstr(line, "endbf"))) {
                
                status = STATUS_IGNORE;
                
            } else {
                
                tempPtr = line;
                
                if(status == STATUS_BFCHAR) {
                    
                    if(step == 0) {
                        
                        start = strchr(tempPtr, '<');
                        end = strchr(tempPtr, '>');
                        length = end - start;
                        
                        cid0 = cidWithCString(start, length);
                        
                        step = 1;
                        tempPtr = end +1;
                    } 
                    
                    if (step == 1) {
                        
                        start = strchr(tempPtr, '<');
                        end = strchr(tempPtr, '>');
                        length = end - start;
                        
                        utf16bufferLen = unicodesequence(start, length, utf16buffer, 0);
                        
                        mergeUnicodeBufferInPlace(utf16buffer, utf16bufferLen);
                        
                        unbuffer_init_with_codepoints(&unbuffer, utf16buffer, utf16bufferLen);
                        unbuffer_decompose(&unbuffer);
                        unbuffer_compose(&unbuffer,unbuffer_compose_mode_canonical);
                        
                        // Create single
                        
                        MFUnicodeRangeSingle * range = [[MFUnicodeRangeSingle alloc]initWithCid:cid0 andUnicode:self->unbuffer.buffer length:self->unbuffer.length];
                        [unicodeRanges addRange:range];
                        [range release];
                        
                        

                        // Reset
                        
                        step = 0;
                        tempPtr = end +1;
                    }
                    
                } else if (status == STATUS_BFRANGE) {
                    
                    
                    if(step == 0) {
                        
                        // First cid
                        
                        start = strchr(tempPtr, '<');
                        end = strchr(tempPtr, '>');
                        length = end - start;
                        
                        cid0 = cidWithCString(start, length);
                        
                        step = 1;
                        tempPtr = (end + 1);
                    }
                    
                    if(step == 1) {
                        
                        // Last cid
                        
                        start = strchr(tempPtr, '<');
                        end = strchr(tempPtr, '>');
                        length = end - start;
                        
                        cid1 = cidWithCString(start, length);
                        
                        step = 2;
                        tempPtr = (end +1);
                    }
                    
                    if(step == 2) {
                        
                        // Check if array or sequential
                        
                        if(strchr(tempPtr, '[')) {
                            
                            // Array found, allocate a multirange and proceed to individual sequence step
                            
                            multiRange = [[MFUnicodeRangeMulti alloc]initWithFirstCid:cid0 andLastCid:cid1];

                            step = 3;
                        
                        } else {
                            
                            // Intial sequence value found
                            
                            start = strchr(tempPtr, '<');
                            end = strchr(tempPtr, '>');
                            length = end - start;
                            
                            utf16bufferLen = unicodesequence(start, length, utf16buffer, 0);

                            mergeUnicodeBufferInPlace(utf16buffer, utf16bufferLen);
                            
                            unbuffer_init_with_codepoints(&unbuffer, utf16buffer, utf16bufferLen);
                            unbuffer_decompose(&unbuffer);
                            unbuffer_compose(&unbuffer,unbuffer_compose_mode_canonical);
                            
                            // Create sequential
                            
                            MFUnicodeRangeSequential * range = [[MFUnicodeRangeSequential alloc]initWithFirstCid:cid0 lastCid:cid1 andFirstUnicode:self->unbuffer.buffer length:self->unbuffer.length];
                            [unicodeRanges addRange:range];
                            [range release];
                                                                                // Reset
                            
                            step = 0;
                        }
                    }
                    
                    while (step == 3) {
                        
                        // Individual sequence in a range
                        
                        start = strchr(tempPtr, '<');
                        end = strchr(tempPtr, '>');
                        length = end - start;
                        
                        utf16bufferLen = unicodesequence(start, length, utf16buffer, 0);
                        
                        mergeUnicodeBufferInPlace(utf16buffer, utf16bufferLen);
                        
                        unbuffer_init_with_codepoints(&unbuffer, utf16buffer, utf16bufferLen);
                        unbuffer_decompose(&unbuffer);
                        unbuffer_compose(&unbuffer,unbuffer_compose_mode_canonical);
                        
                        [multiRange addUnicode:self->unbuffer.buffer length:self->unbuffer.length];
                        
                        tempPtr = end+1;
                        
                        /* Now let's check if the array is being closed or there's another
                         hex value before the end of the array */
                        
                        int pos = 0;
                        pos = strcspn(tempPtr, "<]");
                        if(tempPtr[pos] == ']')
                        {
                            step = 4;
                        }
                    }
                    
                    if(step == 4) {
                        
                        [unicodeRanges addRange:multiRange];
                        [multiRange release], multiRange = nil;
                                                
                        step = 0;
                    }
                }
            }
        }
        
    } // End of for
}

-(void)scan_old {
    
	if(stringbuffer == NULL || unicodeRanges == nil)
		return;
    
	char * buffer = stringbuffer;
	char * data_tkn = NULL;
    char * ctx = NULL;
	int status = STATUS_IGNORE;
	int step = 0;							// Step of the parsing.
	int bfchar_code; 
    
    __unused unsigned int * unicode;	// bfchar code and unicode.
    int unicode_len;
    
	int bfrange_code_begin, bfrange_code_end;	// bfrange first and last code.
	
    int bfrange_parsing_array;	// bfrange current unicode.
	int bfrange_array_count;
	int csrange_code_begin, csrange_code_end;
    
    MFUnicodeRangeSingle * singleRange = nil;
	MFUnicodeRangeMulti * multiRange = nil;
    MFUnicodeRangeSequential * sequentialRange = nil;
    
#if DEBUG & FPK_DEBUG_ENCODING
	printf("Tokenizing...\n");
    printf("%s\n",buffer);
#endif
    
	data_tkn = strtok_r(buffer,DELIMITERS, &ctx);
    
	while(data_tkn!=NULL) {
		
		// int len = strlen(data_tkn);
		
		if(strcmp(data_tkn,"begincodespacerange")==0) {
			
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"begincodespacerange\n");
#endif
			status = STATUS_SPACERANGE;
			step = 0;
			
		} else if (strcmp(data_tkn,"endcodespacerange")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"endcodespacerange\n");
#endif
			status = STATUS_IGNORE;
			
		} else if (strcmp(data_tkn,"beginbfchar")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"beginbfchar\n");
#endif
            
			status = STATUS_BFCHAR;
			step = 0;
			
		} else if (strcmp(data_tkn,"endbfchar")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"endbfchar\n");
#endif
			status = STATUS_IGNORE;
			
		} else if (strcmp(data_tkn,"beginbfrange")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"beginbfrange\n");
#endif
			status = STATUS_BFRANGE;
			bfrange_parsing_array = 0;
			step = 0;
			
		} else if (strcmp(data_tkn,"endbfrange")==0) {
#if DEBUG & FPK_DEBUG_ENCODING
			fprintf(stdout,"endbfrange\n");
#endif
			status = STATUS_IGNORE;
			
		} else {
			
			if(status!=STATUS_IGNORE) {
				
				if(status == STATUS_SPACERANGE) {
					
					if(step == 0) {
						
						sscanf(data_tkn,"<%X>",&csrange_code_begin);
						step++;
						
					} else if(step == 1) {
                        
                        sscanf(data_tkn,"<%X>",&csrange_code_end);
						
#if DEBUG & FPK_DEBUG_ENCODING
						fprintf(stdout,"CSRange is %x to %x\n",csrange_code_begin,csrange_code_end);
#endif
					}
					
				} else if (status == STATUS_BFCHAR) {
					
					if(step == 0) {	// Code.
						
                        // Create a new range here. Multiple bfchar declarations can fall inside
                        // a single bfchar command.
                       ;
                        
						sscanf(data_tkn,"<%X>",&bfchar_code);
						step++;
						
					} else if (step == 1) { // Unicode.
						
						//sscanf(data_tkn,"<%X>",&bfchar_unicode);
						if((unicode_len = [self unicodeForString:data_tkn])) {
                            
                            singleRange = [[MFUnicodeRangeSingle alloc]initWithCid:bfchar_code andUnicode:self->unbuffer.buffer length:self->unbuffer.length];
                            
                            // We have them both, can add the current range to the cluster.
                            
                            [unicodeRanges addRange:singleRange];
                            
                            [singleRange release],singleRange = nil;
                    
                        }
						
                        
						step = 0;
					}
					
				} else if (status == STATUS_BFRANGE) {
                    
					if(step == 0) {	// First code.
						
                        sscanf(data_tkn,"<%X>",&bfrange_code_begin);
						step++;
						
					} else if (step == 1) { // Last code.
						
						sscanf(data_tkn,"<%X>",&bfrange_code_end);
						step++;
						
					} else if (step > 1) {
						
						// The string at this point is either a single
						// unicode value, or the start and end of an array.
						
						if(bfrange_parsing_array) {
							
							// Either an element of the array or the end of it.
							
							if(data_tkn[0]=='<') {
								
								// Element.
								
								//sscanf(data_tkn,"<%X>",&bfrange_unicode);
                                if((unicode_len = [self unicodeForString:data_tkn])) {
                                    
                                    [multiRange addUnicode:self->unbuffer.buffer length:self->unbuffer.length];    
                                }
								
								bfrange_array_count++;
								
							} else {
								
								// End of the array.
								
								//sscanf(data_tkn,"<%X>]",&bfrange_unicode);
                                if((unicode_len = [self unicodeForString:data_tkn])) {
                                    
                                    [multiRange addUnicode:self->unbuffer.buffer length:self->unbuffer.length];    
                                }
								
                                [unicodeRanges addRange:multiRange];
                                [multiRange release],multiRange = nil;
                                
								bfrange_parsing_array = 0;
								step = 0;
							}
							
						} else {
							
							// Either a single unicode or the begin
							// of an array.
							
							if(data_tkn[0]=='[') {
								
								// Begin of the array.
								
								bfrange_parsing_array = 1;
								bfrange_array_count = 0;
							
                                multiRange = [[MFUnicodeRangeMulti alloc]initWithFirstCid:bfrange_code_begin andLastCid:bfrange_code_end];
								
								//sscanf(data_tkn,"[<%X>",&bfrange_unicode);
                                if((unicode_len = [self unicodeForString:data_tkn])) {
                                    
                                    [multiRange addUnicode:self->unbuffer.buffer length:self->unbuffer.length];    
                                }
                                
								bfrange_array_count++;
								
							} else {
								
								// Single unicode.
								//sscanf(data_tkn,"<%X>",&bfrange_unicode);
								if((unicode_len = [self unicodeForString:data_tkn])) {
                                
                                    sequentialRange = [[MFUnicodeRangeSequential alloc]initWithFirstCid:bfrange_code_begin lastCid:bfrange_code_end andFirstUnicode:self->unbuffer.buffer length:self->unbuffer.length];
                                    
                                    //fprintf(stdout, "%x %x -> %X (%d)\n",bfrange_code_begin,bfrange_code_end,self->unbuffer.buffer[0],self->unbuffer.length);
                                    
                                    [unicodeRanges addRange:sequentialRange];
                                    [sequentialRange release],sequentialRange = nil;
                                    
                                }
                                
								
								step = 0;
							}
						}
					}
				}
			}
		}
		
		data_tkn = strtok_r(NULL, DELIMITERS, &ctx);
	}
    
}

-(void)dealloc {
    
    unbuffer_destroy(&unbuffer);
    
	unicodeRanges = nil;
	stringbuffer = NULL;
	[super dealloc];
}



@end
