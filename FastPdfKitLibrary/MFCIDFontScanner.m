//
//  MFCIDFontScanner.m
//  FastPDFKitTest
//
//  Created by Nicolò Tosi on 2/8/11.
//  Copyright 2011 com.mobfarm. All rights reserved.
//

#import "MFCIDFontScanner.h"
#include "string.h"
#import "MFCIDCluster.h"

#define DELIMITERS "\015\040\012\014"
#define STATUS_IGNORE 0
#define STATUS_SPACERANGE 1
#define STATUS_CIDCHAR 2
#define STATUS_CIDRANGE 3
#define STATUS_WMODE 4

#define DEF_CIDS 0
#define NOTDEF_CIDS 1

#define KEY_CODESPACE_BEGIN "begincodespacerange"
#define KEY_CODESPACE_END "endcodespacerange"
#define KEY_CHAR_BEGIN "begincidchar"
#define KEY_CHAR_END "endcidchar"
#define KEY_RANGE_BEGIN "begincidrange"
#define KEY_RANGE_END "endcidrange"
#define KEY_ND_CHAR_BEGIN "beginnotdefchar"
#define KEY_ND_CHAR_END "endnotdefchar"
#define KEY_ND_RANGE_BEGIN "beginnotdefrange"
#define KEY_ND_RANGE_END "endnotdefrange"

@interface MFCIDFontScanner ()

@property (nonatomic, readwrite) NSUInteger writingMode;

@end

@implementation MFCIDFontScanner

@synthesize stringbuffer, cidRanges, notdefCids;
@synthesize writingMode;

-(void)scan {
    
	if(stringbuffer==NULL||cidRanges==nil)
		return;
	
    char * buffer = stringbuffer;
    char * data_tkn = NULL;
    
	int status = STATUS_IGNORE;
    int notdef = 0;
	int step;                                   // Step of the parsing.
	int cidchar_seq, cidchar_cid;               // cidchar sequence and cid.
	int cidrange_seq_begin, cidrange_seq_end;	// cidange first and last sequence.
	int cidrange_cid; 
    int cidrange_parsing_array = 0;             // cidrange current cid and parsing flag.
	int cidrange_array_count;                   // cidrange array counter.
	int csrange_code_begin, csrange_code_end;   // Boh? Not necessary.
    int length = 0;
    
#if 0 & DEBUG
    fprintf(stdout,"Tokenizing\n");
    fprintf(stdout,"%s\n",buffer);
#endif
    
    char * ctx = NULL;
	data_tkn = strtok_r(buffer,DELIMITERS,&ctx);
    
    MFCIDRangeSingle * singleRange = nil;
	MFCIDRangeSequential *sequentialRange = nil;
    MFCIDRangeMulti *multiRange = nil;

	while(data_tkn!=NULL) {
        
        // fprintf(stdout, "%s\n",data_tkn);
		
		// int len = strlen(data_tkn);
		
		if(strcmp(data_tkn,KEY_CODESPACE_BEGIN)==0) {
			
#if 0 & DEBUG
			fprintf(stdout,"begincodespacerange\n");
#endif
			status = STATUS_SPACERANGE;
			step = 0;
			
		}
        else if (strcmp(data_tkn,KEY_CODESPACE_END)==0) {
#if 0 & DEBUG
			fprintf(stdout,"endcodespacerange\n");
#endif
			status = STATUS_IGNORE;
			
		}
        else if (strcmp(data_tkn,KEY_CHAR_BEGIN)==0) {
#if 0 & DEBUG
			fprintf(stdout,"begincidchar\n");
#endif
            
			status = STATUS_CIDCHAR;
            notdef = DEF_CIDS;
			step = 0;
			
		}
        else if (strcmp(data_tkn,KEY_CHAR_END)==0) {
#if 0 & DEBUG
			fprintf(stdout,"endcidchar\n");
#endif
			status = STATUS_IGNORE;
			
		}
        else if (strcmp(data_tkn,KEY_RANGE_BEGIN)==0) {
#if 0 & DEBUG
			fprintf(stdout,"begincidrange\n");
#endif
			status = STATUS_CIDRANGE;
            notdef = DEF_CIDS;
			cidrange_parsing_array = 0;
			step = 0;
			
		}
        else if (strcmp(data_tkn,KEY_RANGE_END)==0) {
#if 0 & DEBUG
			fprintf(stdout,"endcidrange\n");
#endif
			status = STATUS_IGNORE;
			
		}
        else if(strcmp(data_tkn,KEY_ND_CHAR_BEGIN)==0) {
            
#if 0 & DEBUG
			fprintf(stdout,"beginnotdefchar\n");
#endif
            status = STATUS_CIDCHAR;
            notdef = NOTDEF_CIDS;
            step = 0;
                
        }
        else if (strcmp(data_tkn,KEY_ND_CHAR_END)==0) {
            
#if 0 & DEBUG
			fprintf(stdout,"endnotdefchar\n");
#endif
            status = STATUS_IGNORE;
            
        }
        else if (strcmp(data_tkn,KEY_ND_RANGE_BEGIN)==0) {
            
#if 0 & DEBUG
			fprintf(stdout,"beginnotdefrange\n");
#endif
            status = STATUS_CIDRANGE;
            notdef = NOTDEF_CIDS;
            step = 0;
            
        }
        else if (strcmp(data_tkn,KEY_ND_RANGE_END)==0) {
            
#if 0 & DEBUG
			fprintf(stdout,"endnotdefrange\n");
#endif
            
            status = STATUS_IGNORE;
            step = 0;
            
        }
        else if (strcmp(data_tkn,"/WMode")==0) {
            status = STATUS_WMODE;
        }
        
        else {
        
        if(status!=STATUS_IGNORE) {
				
				if(status == STATUS_SPACERANGE) {
					
					if(step == 0) {
						
						sscanf(data_tkn,"<%X>",&csrange_code_begin);
						step++;
						
					} else if(step == 1) {
						sscanf(data_tkn,"<%X>",&csrange_code_end);
						
#if 0 & DEBUG
						fprintf(stdout,"CSRange is %x to %x\n",csrange_code_begin,csrange_code_end);
#endif
					}
					
				}
                else if (status == STATUS_CIDCHAR) {
					
					if(step == 0) {	// Sequence.
						
                        length = strlen(data_tkn)/2 - 1;
                        sscanf(data_tkn,"<%X>",&cidchar_seq);
						step++;
						
					} else if (step == 1) { // CID.
						
						sscanf(data_tkn,"%d",&cidchar_cid);
						
                        singleRange = [[MFCIDRangeSingle alloc]initWithSequence:cidchar_seq andCid:cidchar_cid];
                        singleRange.length = length;
                        
                        if(notdef) {
                            [notdefCids addRange:singleRange];
                        } else {
                            [cidRanges addRange:singleRange];
                        }
                        
                        [singleRange release],singleRange = nil;
                        
                        step = 0;
					}
					
				}
                else if (status == STATUS_CIDRANGE) {
					
					if(step == 0) {	// First code.
                        
                        length = strlen(data_tkn)/2 - 1;
						sscanf(data_tkn,"<%X>",&cidrange_seq_begin);
						step++;
						
					} else if (step == 1) { // Last code.
						
						sscanf(data_tkn,"<%X>",&cidrange_seq_end);
						step++;
						
					} else if (step > 1) {
						
						// The string at this point is either a single
						// cid value, or the start and end of an array.
						
						if(cidrange_parsing_array) {
							
							// Either an element of the array or the end of it.
							
							if(data_tkn[0]=='<') {
								
								// Element.
								
								sscanf(data_tkn,"%d",&cidrange_cid);
								
                                [multiRange addCid:cidrange_cid];
                                
								cidrange_array_count++;
								
							} else {
								
								// End of the array.
								
								sscanf(data_tkn,"%d]",&cidrange_cid);
								
								
                                [multiRange addCid:cidrange_cid];
                                
                                if(notdef) {
                                    [notdefCids addRange:multiRange];
                                } else {
                                    [cidRanges addRange:multiRange];
                                }
                                
                                [multiRange release],multiRange = nil;
                                
								cidrange_parsing_array = 0;
								step = 0;
							}
							
						} else {
							
							// Either a single cid or the begin
							// of an array.
							
							if(data_tkn[0]=='[') {
								
								// Begin of the array.
								
								cidrange_parsing_array = 1;
								cidrange_array_count = 0;
								
								sscanf(data_tkn,"[%d",&cidrange_cid);
								
                                multiRange = [[MFCIDRangeMulti alloc]initWithFirstSequence:cidrange_seq_begin];
                                multiRange.length = length;
                                
								cidrange_array_count++;
								
							} else {
								
								// Single cid.
								sscanf(data_tkn,"%d",&cidrange_cid);
								
								sequentialRange = [[MFCIDRangeSequential alloc]initWithFirstSequence:cidrange_seq_begin lastSequence:cidrange_seq_end andCid:cidrange_cid];
                                sequentialRange.length = length;
                                
                                if(notdef) {
                                    [notdefCids addRange:sequentialRange];
                                } else {
                                    [cidRanges addRange:sequentialRange];
                                }
                                
                                [sequentialRange release],sequentialRange = nil;
                                
								step = 0;
							}
						}
					}
				} // if STATUS_CIDRANGE
                else if(status == STATUS_WMODE) {
                    
                    int mode = 0;
                    
                    sscanf(data_tkn, "%d",&mode);
                    
                    self.writingMode = mode;
                    
                    status = STATUS_IGNORE;
                }
			}
		} 
		
		data_tkn = strtok_r(NULL,DELIMITERS,&ctx);
    }   // End of while loop.
}

-(void)dealloc {
    
    notdefCids = nil;
	cidRanges = nil;
	stringbuffer = NULL;
	
    [super dealloc];
}


@end
