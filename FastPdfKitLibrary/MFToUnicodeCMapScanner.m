//
//  MFToUnicodeCMapScanner.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 1/28/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFToUnicodeCMapScanner.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

//#define DELIMITERS "\015\040\012\014"
#define STATUS_IGNORE 0
#define STATUS_SPACERANGE 1
//#define STATUS_BFCHAR 2
//#define STATUS_BFRANGE 3

#define DELIMITERS "\r\n"
#define STATUS_SKIP 0
#define STATUS_BFCHAR  1
#define STATUS_BFRANGE 2

#define CMD_SKIP 0
#define CMD_BFRANGE_BEGIN 1
#define CMD_BFRANGE_END 2
#define CMD_BFCHAR_BEGIN 3
#define CMD_BFCHAR_END 4
#define CMD_BFCHAR_CONTINUE 5

@interface MFToUnicodeCMapScanner()

int command_line(char * line, int * count);
BOOL read_bfchar(char * line, int len, MFFontEncoder * encoder);
BOOL read_bfrange(char * line, int len, MFFontEncoder * encoder, unsigned short * last_codepoint);
char * read_value(char * string, int len, unsigned short * buffer);
BOOL keep_reading_bfrange(char * line, int len, MFFontEncoder * encoder, unsigned short *last_codepoint);

@end

@implementation MFToUnicodeCMapScanner

@synthesize cmapStream;
@synthesize encoder;

const unsigned short value_map [128] = {
    0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
    0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
    0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0x9,0x0,0x0,
    0x0,0x0,0x0,0x0,0x0,0xA,0xB,0xC,0xD,0xE,0xF,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
    0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xA,0xB,0xC,
    0xD,0xE,0xF,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
    0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};

void setUnicodeForCode(MFFontEncoder * anEncoder, int unicode, int code) {
	
#if DEBUG & FPK_DEBUG_ENCODING
	int old = anEncoder->unicodes[code];
#endif
	
    if(code < (anEncoder->unicodes_len)) {
        
        unsigned short uni = unicode;
        anEncoder->unicodes[code] = uni;
        
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"Setting 0x%.04x for code %d in place of 0x%.04x\n",uni,code,old);
#endif

    } else {
#if DEBUG & FPK_DEBUG_ENCODING
        fprintf(stdout,"Code %d for unicode %u out of range %d\n",code,unicode,(anEncoder->unicodes_len));
#endif
    }
}

-(void)scan {
    
    if(cmapStream == NULL)
        return;
    
    CFDataRef data = CGPDFStreamCopyData(cmapStream, CGPDFDataFormatRaw);
	
	int dataLength = CFDataGetLength(data);
	
	char * buffer = calloc(dataLength+1,sizeof(char));
    

    
	CFDataGetBytes(data, CFRangeMake(0, dataLength), (unsigned char *)buffer);

    char * line_token = NULL;
    char * ctx = NULL;
    
	int count;
	int command;
	int counter;
	unsigned short last_code;
    
	//read_cmap(&cmap_data);	// Read the file in memory.
	
    //fprintf(stdout, "%s\n",buffer);
    
	line_token = strtok_r(buffer, DELIMITERS, &ctx);
	
	while(line_token!=NULL) {
		
		//fprintf(stdout,"%s\n",line_token);	
		//line_copy = malloc((strlen(line_token)+1) * sizeof(char));
		//strcpy(line_copy,line_token);
		
		command = command_line(line_token,&count);
		
		if(command == CMD_BFRANGE_BEGIN) {
            
			counter = 0;
            
			while(counter < count) { // Need to read <count> bfrange entries
                
				line_token = strtok_r(NULL, DELIMITERS, &ctx); // Next line

				if(read_bfrange(line_token,strlen(line_token),encoder,&last_code)) {
                    
                        counter++; // bfrange entry done
                } else {
                    
                    line_token = strtok_r(NULL,DELIMITERS,&ctx); // Next line
                    
                    // keep_reading_bfrange will return YES once a ']' character is found, meaning
                    // the array has been completely read from the map
                    
                    while(!keep_reading_bfrange(line_token, strlen(line_token), encoder, &last_code))
                          line_token = strtok_r(NULL,DELIMITERS,&ctx); // Keep reading the next line until done
                    counter++; // bfrange entry done
                }
			}
            
            
		} else if (command == CMD_BFCHAR_BEGIN) {
            
			counter = 0;

			while(counter < count) {
                
				line_token = strtok_r(NULL, DELIMITERS, &ctx); // Next line

				read_bfchar(line_token,strlen(line_token),encoder);
				counter++;
			}
		} 
		
		line_token = strtok_r(NULL, DELIMITERS, &ctx); // Next line
	}
    
    // Cleanup.
    
	if(buffer)
		free(buffer),buffer = NULL;
	if(data)
		CFRelease(data),data = NULL;
}


BOOL keep_reading_bfrange(char * line, int len, MFFontEncoder * encoder, unsigned short *last_codepoint) {
    
    char * start, * end;
	unsigned short unicode;
	unsigned short values [128] = {0};
	char * array_end;
  
    start = line;
    
    array_end = strchr(line, ']');
    
    while((start = strchr(start,'<'))) {
        
        memset(values,0,128*sizeof(unsigned short)); // Clean
        
        end = strchr(start,'>');
        start = read_value(start, (end-start+1), values);
        unicode = values[0];
        setUnicodeForCode(encoder, unicode, (*last_codepoint)++);
    }
    
    if(array_end)    
        return YES;
    
    return NO;
}

BOOL read_bfrange(char * line,
                  int len,
                  MFFontEncoder * encoder,
                  unsigned short * last_codepoint)
{
	
	char * array_start;
	int array_count;
	int count;
	char * start, * end;
	unsigned short first_code, last_code, code;
	unsigned short unicode;
	unsigned short values [128] = {0};
	
    if((array_start = strchr(line,'[')))
    { // <><>[<><>...<>]
        
		start = strchr(line,'<'); // <*><>[<>
		end = strchr(start,'>');
		start = read_value(start,(end-start+1),values);
		first_code = values[0];
		
		memset(values,0,128*sizeof(unsigned short));
		
		end = strchr(start,'>');
		start = read_value(start,(end-start+1),values);
		last_code = values[0];
		
		array_count = last_code - first_code + 1;
		start = strchr(array_start,'<');
		code = first_code;
        *last_codepoint = code;
        count = 0;
        
		while(start)
        {
            memset(values, 0, 128 * sizeof(unsigned short)); // Reset the scratchpad.
            
            end = strchr(start,'>');
            start = read_value(start,(end-start+1),values);
            unicode = values[0];
            
            setUnicodeForCode(encoder, unicode, (*last_codepoint));
            (*last_codepoint)++;
            count++;
            start = strchr(start, '<');
		}
        
        if(array_count == count)
        {
            return YES; // If we have completed the array (we could also check the occurrence of ']' char.
        }
        else {
            return NO; // If there are still some value to parse in the next lines.
        }
	}
    else
    { // <><><>
        
		start = strchr(line,'<');
		end = strchr(line,'>');
		start = read_value(start,(end-start+1),values);
		first_code = values[0];
		
		memset(values,0,128*sizeof(unsigned short));
		
		end = strchr(start,'>');
		start = read_value(start,(end-start+1),values);
		last_code = values[0];
		
		memset(values,0,128*sizeof(unsigned short));
		
		end = strchr(start,'>');
		start = read_value(start,(end-start+1),values);
		unicode = values[0];
		
        //fprintf(stdout,"\tfound <%u><%u><%u>\n",first_code,last_code,unicode);
        
        // Setting up the unicodes for each code.
        code = first_code;
        
        while(code <= last_code)
        {
            setUnicodeForCode(encoder, unicode, code);
            code++;
            unicode++;
        }
        
        return YES;
	}
    
    return YES;
}

BOOL read_bfchar(char * line, int len, MFFontEncoder * encoder) {
	
	unsigned short values [128] = {0}; // Up to 512 bytes.
	unsigned short code, unicode;
	char * start, * end;
	
    // fprintf(stdout,"2U scanner %s\n",line);
    
	// Look up the code entry.
	start = strchr(line,'<');
	end = strchr(line,'>');
	
	start = read_value(start,(end-start+1),values);
	
	code = values[0];	// Get the code.
	
	// Look up the unicode entry.
	
	memset(values,0,128 * sizeof(unsigned short)); // Reset the buffer.
	
	end = strchr(start,'>');
	read_value(start,(end-start+1),values);
	
	unicode = values[0];	// Get the unicode.
	
	//fprintf(stdout,"\tfound <%u> <%u>\n",code,unicode);
    
    setUnicodeForCode(encoder, unicode, code);
    
    return YES;
}

int command_line(char * line, int * c) {
    
	int count = 0;
	char command [128];
	
	if(sscanf(line,"%d %s",&count,command) == 2) {
		
		*c = count;
        
		if(strcmp(command,"beginbfrange")==0) {
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"beginbfrange %d\n",count);
#endif
            
			return CMD_BFRANGE_BEGIN;
			
		} else if (strcmp(command,"beginbfchar")==0) {
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"beginbfchar %d\n",count);
#endif
            
			return CMD_BFCHAR_BEGIN;
		}
		
	} else if(sscanf(line,"%s",command)==1) {
        
        if(strcmp(command,"endbfrange") == 0) {
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"endbfrange\n");
#endif
            
            return CMD_BFRANGE_END;
            
        } else if (strcmp(command,"endbfchar")==0) {
            
#if DEBUG & FPK_DEBUG_ENCODING
            fprintf(stdout,"endbfchar\n");
#endif
            
            return CMD_BFCHAR_END;	
        }
	}
	
	return CMD_SKIP;
}

char * read_value(char * string, int len, unsigned short * values) {
    
    //unsigned short values [128] = {0}; // Up to 512 bytes.
    
    int acc;	
    int count = 0;
    
    while(len--) {
        if((acc = *string)!=32) { // Read the value.
            if(!(acc == 60 || acc == 62)) {
                //fprintf(stdout,"Value %d for %d of batch %d count %d\n",value_map[acc],count%4,count/4,count);
                values[count/4] = (values[count/4] << 4) + value_map[acc];
                count++;
            }
        } else { // Skip to the beginning of the next batch if not already there.
            if(count>0 && (count%4))
                count=(count/4)+4;
        }
        string++;
    }
    //fprintf(stdout,"Values %d %d %d %d\n",values[0],values[1],values[2],values[3]);
    return string;
}

-(void)dealloc {

	encoder = NULL;
	cmapStream = NULL;
	[super dealloc];
}

/*
 -(void)scan2 { // OLD.
 
 if(cmapStream==NULL)
 return;
 
 CFDataRef data = CGPDFStreamCopyData(cmapStream, CGPDFDataFormatRaw);
 
 int dataLength = CFDataGetLength(data);
 
 char * buffer = calloc(dataLength+1,sizeof(char));
 
 CFDataGetBytes(data, CFRangeMake(0, dataLength), (unsigned char *)buffer);
 
 int status = STATUS_IGNORE;
 int step;							// Step of the parsing.
 int bfchar_code, bfchar_unicode;	// bfchar code and unicode.
 int bfrange_code_begin, bfrange_code_end;	// bfrange first and last code.
 int bfrange_unicode, bfrange_parsing_array;	// bfrange current unicode.
 int bfrange_array_count;
 int csrange_code_begin, csrange_code_end;
 char * ctx = NULL;
 char * data_tkn = strtok_r(buffer, DELIMITERS, &ctx);
 
 #if DEBUG
 printf("Tokenizing...\n");
 #endif
 
 while(data_tkn!=NULL) {
 
 // int len = strlen(data_tkn);
 #if DEBUG
 fprintf(stdout,"\t(%s)\n",data_tkn);
 #endif
 
 if(strcmp(data_tkn,"begincodespacerange")==0) {
 
 #if DEBUG
 fprintf(stdout,"begincodespacerange\n");
 #endif
 status = STATUS_SPACERANGE;
 step = 0;
 
 } else if (strcmp(data_tkn,"endcodespacerange")==0) {
 #if DEBUG
 fprintf(stdout,"endcodespacerange\n");
 #endif
 status = STATUS_IGNORE;
 
 } else if (strcmp(data_tkn,"beginbfchar")==0) {
 #if DEBUG
 fprintf(stdout,"beginbfchar\n");
 #endif
 status = STATUS_BFCHAR;
 step = 0;
 
 } else if (strcmp(data_tkn,"endbfchar")==0) {
 #if DEBUG
 fprintf(stdout,"endbfchar\n");
 #endif
 status = STATUS_IGNORE;
 
 } else if (strcmp(data_tkn,"beginbfrange")==0) {
 #if DEBUG
 fprintf(stdout,"beginbfrange\n");
 #endif
 status = STATUS_BFRANGE;
 bfrange_parsing_array = 0;
 step = 0;
 
 } else if (strcmp(data_tkn,"endbfrange")==0) {
 #if DEBUG
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
 
 #if DEBUG
 fprintf(stdout,"CSRange is %x to %x\n",csrange_code_begin,csrange_code_end);
 #endif
 }
 
 } else if (status == STATUS_BFCHAR) {
 
 if(step == 0) {	// Code.
 
 sscanf(data_tkn,"<%X>",&bfchar_code);
 step++;
 
 } else if (step == 1) { // Unicode.
 
 sscanf(data_tkn,"<%X>",&bfchar_unicode);
 
 // We have them both, can update the value in the mapping.
 setUnicodeForCode(encoder,bfchar_unicode,bfchar_code);
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
 
 sscanf(data_tkn,"<%X>",&bfrange_unicode);
 
 setUnicodeForCode(encoder,bfrange_code_begin+bfrange_array_count,bfrange_unicode);
 
 bfrange_array_count++;
 
 } else {
 
 // End of the array.
 
 sscanf(data_tkn,"<%X>]",&bfrange_unicode);
 
 setUnicodeForCode(encoder,bfrange_code_begin+bfrange_array_count,bfrange_unicode);
 
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
 
 sscanf(data_tkn,"[<%X>",&bfrange_unicode);
 
 setUnicodeForCode(encoder,bfrange_code_begin+bfrange_array_count,bfrange_unicode);
 
 bfrange_array_count++;
 
 } else {
 
 // Single unicode.
 sscanf(data_tkn,"<%X>",&bfrange_unicode);
 
 // Update every code from _begin to _end.
 // Unicodes value start _unicode.
 int tmp_code = bfrange_code_begin;
 int tmp_unicode = bfrange_unicode;
 
 while(tmp_code <= bfrange_code_end) {
 setUnicodeForCode(encoder,tmp_unicode,tmp_code);
 tmp_unicode++;
 tmp_code++;
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
 
 
 // Cleanup.
 
 if(buffer)
 free(buffer),buffer = NULL;
 if(data)
 CFRelease(data),data = NULL;
 }
 */


@end

