/*
 *  MFFontEncoding.c
 *  FastPDFKitTest
 *
 *  Created by Nicolò Tosi on 12/29/10.
 *  Copyright 2010 com.mobfarm. All rights reserved.
 *
 */

#include "MFFontEncoding.h"
#include "mf_agl.h"
#include "mf_def_encodings.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "unbuffer.h"

#define APPEND_0 0
#define MFFE_UNICODE_SIZE 4
#define MFFE_NOTDEF_CODEPOINT 0x25AF
int lookupCode(char * name);

void initFontEncoder(MFFontEncoder * encoder) {
	
	// Setup with the Standard encoding as default.
	
	int unicodes_length_bytes = mf_standard_encoding_len * (MFFE_UNICODE_SIZE);
	unsigned int * tmp = calloc(unicodes_length_bytes, sizeof(unsigned char));
	memcpy(tmp,mf_standard_encoding,unicodes_length_bytes);
	encoder->unicodes = tmp;
	encoder->unicodes_len = mf_standard_encoding_len;
    
    encoder->notfound = 0x25AF;
}

void initFontEncoderWithEncoding(MFFontEncoder * encoder, MFFontEncoding encoding) {
	
	// Setupt according to the encoding passed as parameter.
	
	const unsigned int * unicodes_ptr = NULL;
	int unicodes_length_bytes = 0;
	int unicodes_length = 0;
	
    // Get the appropriate array of unicodes to copy.
    switch(encoding) {
		case MFFontEncodingStandard :
			unicodes_ptr = mf_standard_encoding;
			unicodes_length = mf_standard_encoding_len;
			unicodes_length_bytes = mf_standard_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingMacRoman :
			unicodes_ptr = mf_macroman_encoding;
			unicodes_length = mf_macroman_encoding_len;
			unicodes_length_bytes = mf_macroman_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingWinAnsi :
			unicodes_ptr = mf_winansi_encoding;
			unicodes_length = mf_winansi_encoding_len;
			unicodes_length_bytes = mf_winansi_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingPdfDoc :
			unicodes_ptr = mf_pdfdoc_encoding;
			unicodes_length = mf_pdfdoc_encoding_len;
			unicodes_length_bytes = mf_pdfdoc_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingMacExpert :
			unicodes_ptr = mf_macexpert_encoding;
			unicodes_length = mf_macexpert_encoding_len;
			unicodes_length_bytes = mf_macexpert_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingSymbol :
			unicodes_ptr = mf_symbols_encoding;
			unicodes_length = mf_symbols_encoding_len;
			unicodes_length_bytes = mf_symbols_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		case MFFontEncodingZapfDingbats :
			unicodes_ptr = mf_zapfdingbats_encoding;
			unicodes_length = mf_zapfdingbats_encoding_len;
			unicodes_length_bytes = mf_zapfdingbats_encoding_len * (MFFE_UNICODE_SIZE);
			break;
		default :
			unicodes_ptr = mf_standard_encoding;
			unicodes_length = mf_standard_encoding_len;
			unicodes_length_bytes = mf_standard_encoding_len * (MFFE_UNICODE_SIZE);
			break;
	}
	
	encoder->unicodes = calloc(unicodes_length_bytes, sizeof(unsigned char));
	encoder->unicodes_len = unicodes_length;
	encoder->base_encoding = encoding;
	memcpy(encoder->unicodes,unicodes_ptr,unicodes_length_bytes);
    encoder->notfound = 0x25AF;
}

void deleteFontEncoder(MFFontEncoder * encoder) {
    
    if(encoder->unicodes)
		free(encoder->unicodes), encoder->unicodes = NULL;
}

unsigned int * fontEncoderUnicodeForCode(MFFontEncoder * encoder, unsigned char code, int * length) {

    unsigned int * unicode = NULL;
    
	if((code >= 0) && (code < encoder->unicodes_len)) {
		unicode = &(encoder->unicodes[code]);
        *length = 1;
        return unicode;
	}
	
    *length = 0;
	return NULL;
}

void fontEncoderSetUnicodeForCode(MFFontEncoder * encoder, char * unicode_name, unsigned char code) {
	
	unsigned int unicode_value = MFFE_NOTDEF_CODEPOINT; // .notdef
	unbuffer unbuffer = {0,0,0};
    
	// int min_index = 0;
	// int max_index = mf_agl_names_len-1;
	
    char * full_stop_occurrence = NULL;
    char * token = NULL;
    char * underscore_occurrence = NULL;
    char * ctx = NULL;
    unsigned int codepoints [20] = {0};
    int codepoint_index = 0;
    int name_index;
    
    // Trunkate at full stop.
    full_stop_occurrence = strchr(unicode_name, 0x002E);
    if(full_stop_occurrence)
        *full_stop_occurrence = 0;
    
    // Branch on occurrence of a composite name.
    underscore_occurrence = strchr(unicode_name, '_');
    // fprintf(stdout,"unicode_name %s of length %d\n",unicode_name,strlen(unicode_name));
    // int count = 0;
    if(underscore_occurrence) {
        
        // Composite name, tokenize and normalize the name to a single unicode value.
        
        token = strtok_r(unicode_name, "\x005f",&ctx);    
        while(token!=NULL) {
            
            // fprintf(stdout,"token length %s %d (%d)\n", token, strlen(token), count++);
            
            name_index = lookupCode(token);
            if(name_index >= 0) {
                codepoints[codepoint_index] = mf_agl_unicodes[name_index];
                codepoint_index++;
            }
            
            token = strtok_r(NULL, "\x005f", &ctx);
        }
        
        unbuffer_init_with_codepoints(&unbuffer, codepoints, codepoint_index);
        unbuffer_decompose(&unbuffer);
        unbuffer_compose(&unbuffer,unbuffer_compose_mode_canonical);
        
        if(unbuffer.length == 1) {
            
            unicode_value = unbuffer.buffer[0];
            
        } else {
            
            // Keep default.
            
            printf("Failed at calculating unicode for glyph name %s\n",unicode_name);
            
        }
        
        unbuffer_destroy(&unbuffer); // Pair unbuffer_init_with_codepoints
        
    } else {
        
        // Single name, use it directly.
        
        name_index = lookupCode(unicode_name);
        if(name_index >= 0) {
            unicode_value = mf_agl_unicodes[name_index];
        }
    }
    
    
#if DEBUG & FPK_DEBUG_ENCODING
    printf("Value 0x%X (%u) set for name %s from code %d\n",unicode_value,unicode_value,unicode_name,code);
#endif

    encoder->unicodes[code] = unicode_value;
    
    
    /*
     token = strtok(unicode_name, "_");    
     while(token!=NULL) {
     
     name_index = lookupCode(unicode_name, (char **)mf_agl_names, min_index, max_index);
     if(name_index >= 0) {
     codepoints[codepoint_index] = mf_agl_unicodes[name_index];
     codepoint_index++;
     } else {
     // Skip...
     }
     }
     
     if(index == 1) {
     
     encoder->unicodes[code] = codepoints[0];
     
     } else if (index > 1) {
     
     // Compose/decompose.
     
     unbuffer_init_with_codepoints(&unbuffer, codepoints, index);
     unbuffer_decompose(&unbuffer);
     unbuffer_compose(&unbuffer);
     
     encoder->unicodes[unbuffer.buffer[0]];
     
     } else { // <= 1
     
     encoder->unicodes[code] = 0x25Af;
     
     }
     
     #if DEBUG
     printf("Value 0x%X (%u) set for name %s from code %d\n",unicode_value,unicode_value,unicode_name,code);
     #endif
     
     index = lookupCode(unicode_name, (char **)mf_agl_names, min_index, max_index);
     
     if(index >= 0) {
     
     unicode_value = mf_agl_unicodes[index];
     encoder->unicodes[code] = unicode_value;
     
     #if DEBUG
     printf("Value 0x%X (%u) set for name %s from code %d\n",unicode_value,unicode_value,unicode_name,code);
     #endif
     
     } else {
     
     // If no match in found, clean up the name according to the agl rules. First, drop the char after the first occurrence of
     // the char 0x002E (full stop). Then it is necessary to split the string          
     //        parsed_name = calloc(strlen(unicode_name)+1, sizeof(char));
     //        strcpy(parsed_name, unicode_name);
     //        if((full_stop_ptr = strchr(parsed_name, 0x002E))) {
     //            *full_stop_ptr = 0;
     //        }
     
     index = lookupCode(unicode_name, (char **)mf_agl_fallback_names, 0, mf_agl_fallback_names_len -1);
     
     //        free(parsed_name);
     
     if(index >= 0) {
     
     unicode_value = mf_agl_fallback_unicodes[index];
     encoder->unicodes[code] = unicode_value;
     
     #if DEBUG
     printf("Fallback value 0x%X (%u) set for name %s from code %d\n",unicode_value,unicode_value,unicode_name,code);
     #endif
     
     } else {
     
     #if DEBUG
     printf("Value not found for name, defaulting to space (0x0020) %s\n",unicode_name);
     #endif
     
     encoder->unicodes[code] = 0x0020;
     }
     
     }
     */
}

int _lookupCode(char * name, char ** names, int min, int max) {

	// Binary search.
	
	if(min > max) 
		return -1;
	
	int mid = min + (max - min)/2;
	
	char * lookedup = names[mid];
	
    // fprintf(stdout,"length name %d\n",strlen(name));
    // fprintf(stdout,"lookedup name %d\n",strlen(lookedup));
    
	int difference = strcmp(name,lookedup);
	
	if(difference == 0) { // No difference, we have found it!
		
		return mid;
		
	} else if (difference > 0)  { // Name is greater.
		
		return _lookupCode(name,names,mid+1,max);
		
	} else { // Name si smaller.
		
		return _lookupCode(name,names,min,mid-1);
		
	}
}

int lookupCode(char * name) {
    return _lookupCode(name, (char **)mf_agl_names, 0, mf_agl_names_len-1);
}

int unicodeToUTF8BufferSpaceRequired(unsigned int character) {
    if (character <= 0x007F)
        return 1;
    if (character <= 0x07FF)
        return 2;
    if(character <= 0xffff)
        return 3;
    return 4;
}

unsigned char * UTF8StringFromUTF32buffer(unsigned int * utf32buffer, int utf32buffer_len, int * length) {
    
    unsigned char * utf8buffer = NULL;
    int utf8buffer_size, utf8buffer_len;
    int utf8chunk_len;
    
    // First, allocate a unsigned char buffer of the same numer of elements as
    // the utf32 buffer plus an end of string, since most if not all characters 
    // will be ASCII
    
    utf8buffer = calloc(utf32buffer_len, sizeof(unsigned char));
    utf8buffer_size = utf32buffer_len;
    utf8buffer_len = 0;
    
    int index;
    for(index = 0; index < utf32buffer_len; index++) {
        
        // Loop over each utf32buffer element, calculate the space they will
        // need as utf8 and grow the utf8 buffer if necessary. Write the uf32
        // element in the uf8buffer
        
        utf8chunk_len = unicodeToUTF8BufferSpaceRequired(utf32buffer[index]); // utf8 length
        
        while (utf8buffer_len + utf8chunk_len >= utf8buffer_size) { // Grow if necessary
            
            int new_size = utf8buffer_size + utf32buffer_len;
            unsigned char * tmp = realloc(utf8buffer, new_size);
            
            if(!tmp) { // If realloc fail, try calloc
                
                tmp = calloc(new_size, sizeof(unsigned char));
                memcpy(tmp, utf8buffer, utf8buffer_len);
                free(utf8buffer);
            }
            
            utf8buffer = tmp;
            utf8buffer_size = new_size;
        }
        
        // Update the utf8buffer length
        
        utf8buffer_len+=writeUnicodeToUTF8Buffer(utf32buffer+index, utf8buffer+utf8buffer_len);
    }
    
#if APPEND_0
    *length = (utf8buffer_len + 1); // UTF8 size is always at least 1 larger than its len, so we can safely add an end of string
#else
    *length = (utf8buffer_len); // UTF8 size is always at least 1 larger than its len, so we can safely add an end of string
#endif
    
    
    
    return utf8buffer;
}

int writeUnicodeToUTF8Buffer(unsigned int * unicode, unsigned char * buffer) {
	
	unsigned char * ptr;
    unsigned int character = *unicode;
	//unsigned short no_char = htons(character);
	if(character <= 0x007F) {
		
        // Left untouched.
        
        *buffer = character;
		return 1;
        
	} else if (character <= 0x07FF) {
        
		ptr = buffer;
		
		(*ptr) = 0xC0 | (character >> 6);
		ptr++;
		(*ptr) = 0x80 | (character & 0x3F);
		
		return 2;
        
	} else if (character <= 0xffff) {
		
		ptr = buffer;
        
		(*ptr) = 0xE0 | (character >> 12);
		ptr++;
		(*ptr) = 0x80 | ((character >> 6) & 0x3F);
		ptr++;
		(*ptr) = 0x80 | (character & 0x3F);
		
		return 3;
	} else {
        
        ptr = buffer;
        
        (*ptr) = 0xF0 | (character >> 18);
        ptr++;
        (*ptr) = 0x80 | ((character >> 12) & 0x3F);
		ptr++;
		(*ptr) = 0x80 | ((character >> 6) & 0x3F);
		ptr++;
		(*ptr) = 0x80 | (character & 0x3F);

		return 4;
	}
}
