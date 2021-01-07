#include "unbuffer.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "unbuffer_data.h"
#include "unbuffer_range.h"

const int unbuffer_def_size = 5;

void unbuffer_init(unbuffer * buffer);
void unbuffer_grow(unbuffer * buffer);

void unbuffer_expand_at_position(unbuffer * buffer, int position, int exp_size);
void unbuffer_collapse_at_position(unbuffer * buffer, int position, int cps_size);

void unbuffer_replace(unbuffer * buffer, int position, unsigned int * cps_out, int cps_out_len, unsigned int * cps_in, int cps_in_len);

void unbuffer_init(unbuffer * buffer) {

	// Free the old buffer if already initialized.
	if(buffer->buffer)
		free(buffer->buffer);
	
	// Allocate a new buffer.
	unsigned int * tmp_buffer = malloc(unbuffer_def_size * sizeof(unsigned int));
	memset(tmp_buffer,0,unbuffer_def_size * sizeof(unsigned int));
	
	// Set buffer and size.
	buffer->buffer = tmp_buffer;
	buffer->size = unbuffer_def_size;
	buffer->length = 0;
};

void unbuffer_init_with_codepoint(unbuffer * buffer, unsigned int cpt) {

	unbuffer_init(buffer);
	
	buffer->buffer[0] = cpt;
	buffer->length = 1;
};

void unbuffer_init_with_codepoints(unbuffer * buffer, unsigned int * cpts, int len) {
	
	unbuffer_init(buffer);
	
	while(buffer->size < len) {
		unbuffer_grow(buffer);
	}
	
	memcpy(buffer->buffer,cpts,len * sizeof(unsigned int));
	buffer->length = len;
};

void unbuffer_destroy(unbuffer * buffer) {
	if(buffer) {
        if(buffer->buffer) {
			free(buffer->buffer), buffer->buffer = NULL;
        }
		buffer->size = 0;
		buffer->length = 0;
	}
};

void unbuffer_grow(unbuffer * buffer) {

	// Calcolate new size and allocate a temp buffer.
	int new_size = (buffer->size) * 2;
	unsigned int * tmp_buffer = malloc(new_size * sizeof(unsigned int));
	memset(tmp_buffer, 0, new_size * sizeof(unsigned int));
	
	// Copy the content of the old buffer to the new one.
	memcpy(tmp_buffer, buffer->buffer, buffer->length * sizeof(unsigned int));
	
	// Free the old buffer.
	free(buffer->buffer);
	
	// Set new buffer and size.	
	buffer->buffer = tmp_buffer;
	buffer->size = new_size;
};

void unbuffer_clear(unbuffer * buffer) {

	// Just clear the buffer.
	memset(buffer->buffer,0,buffer->size);
	buffer->length = 0;
};

void unbuffer_print(unbuffer * buffer) {
	fprintf(stdout,"size : %d  length : %d content : ",buffer->size, buffer->length);
	int index;
	for (index = 0; index < buffer->length; index++) {
		fprintf(stdout,"[%X]",buffer->buffer[index]);
	}
	fprintf(stdout,"\n");
};

void unbuffer_replace(unbuffer * buffer, int position, unsigned int * cps_out, int cps_out_len, unsigned int * cps_in, int cps_in_len) {

	int diff = cps_in_len - cps_out_len;
	int index;
	
	if(diff > 0) {
		
		unbuffer_expand_at_position(buffer,position,diff);
	
	} else if (diff < 0) {

		unbuffer_collapse_at_position(buffer,position,(-diff));
	} 
	
	for(index = 0; index < cps_in_len; index++) {
		buffer->buffer[position+index] = cps_in[index];
	}
};

void unbuffer_expand_at_position(unbuffer * buffer, int position, int exp_size) {
	
	// Example with exp_size 2
	// ...[pos][x][x]...
	// ...[pos][1][2][x][x]...
	
	// Be sure that there's enough space in the buffer.
	while((buffer->length + exp_size) > buffer->size) {
		unbuffer_grow(buffer);
	}
	
	// Starting from the last codepoint in the buffer, move it exp_size pos down the buffer.
	int backward_position = buffer->length - 1;
	while(backward_position >= position) {
		buffer->buffer[backward_position + exp_size] = buffer->buffer[backward_position];
		buffer->buffer[backward_position] = 0;
		backward_position--;
	}
	
	buffer->length += exp_size;
};

void unbuffer_collapse_at_position(unbuffer * buffer, int position, int cps_size) {
	
	// Example with cps_size 2
	// ...[y][pos][x][z][z]...
	// ...[y][z][z]...
	
	int pos = position + cps_size; // Starting position for the shift.
	while(pos < buffer->length) {
		buffer->buffer[pos-cps_size] = buffer->buffer[pos];
		pos++;
	}
	buffer->length-=cps_size;
};	

void unbuffer_compose(unbuffer * buffer, unbuffer_compose_mode mode) {
    
    int pos;
	int data_offset;
	unsigned int codepoint;
	
	if(buffer->length < 2) {
        // There's already a single codepoint in the buffer. No need to
        // compose.
		return;
    }
    
	pos = 0;
	while((buffer->length - pos) > 1) { // Keep going until fully composed.
        
        int length = 2;
    
        data_offset = unbuffer_data_lookupdecomposition((buffer->buffer+pos), length);
        
		if(mode && (data_offset < 0)) {
            
            int margin = buffer->length - pos;
            for(length = 2; (data_offset < 0) && (length <= margin); length++) {
                data_offset = unbuffer_data_lookupcompatibility(buffer->buffer+pos, length);
            }
        }
        
        if(data_offset >= 0) {  // If a composition has been found, compose.
			
			codepoint = unbuffer_data_codepoint(data_offset);
            unbuffer_replace(buffer, pos, NULL, 2, &codepoint, 1);
			
		} else { // Else move to the next position.
			pos++;
		}
	}	
};


void old_unbuffer_compose(unbuffer * buffer) {

	int pos;
	int data_offset;
	unsigned int codepoint;
	
	if(buffer->length < 2)
		return;

	pos = 0;
	while((buffer->length - pos) > 1) {
	
      	data_offset = unbuffer_data_lookupdecomposition(buffer->buffer+pos, 2);
		
		if(data_offset >= 0) {
			
			codepoint = unbuffer_data_codepoint(data_offset);
			unbuffer_replace(buffer, pos, NULL, 2, &codepoint, 1);
			
		} else {
			pos++;
		}
	}	
};

void unbuffer_sort(unbuffer * buffer) {
    
    

}

static inline int unbuffer_tolowcase(unsigned int u0) {
	
    if(u0 > 64 && u0 < 91)
        u0+=32;
    
    return u0;
}



int unbuffer_compare(unbuffer * term, unbuffer * text, int mode, int ignorecase) {
    
    switch (mode) {
            
        case unbuffer_compare_mode_smart:

            // First check if the term is a simple char. If it is, compare it
            // against only the first element of the text item. If it is not,
            // compare both buffer across their length. If the length is 
            // different so will the buffer.
            
            if(!term->length > 0)
                return -1;
            
            if(term->length == 1 && text->length > 1) { // Simple char.
        
                if(ignorecase) {
                    
                    unsigned int tmp0 = unbuffer_tolowcase(term->buffer[0]);
                    unsigned int tmp1 = unbuffer_tolowcase(text->buffer[0]);
                    
                    return tmp0 - tmp1;
                    
                } else {
                        return (term->buffer[0] - text->buffer[0]);
                }
                
                
            } else { // Complex char.
                
                int diff;
                
                if(term->length == text->length) { // Same length.
                    
                    if(ignorecase) {
                        
                        unsigned int tmp0 = unbuffer_tolowcase(term->buffer[0]);
                        unsigned int tmp1 = unbuffer_tolowcase(text->buffer[0]);
                        diff = tmp0 - tmp1;
                        
                    } else {
                        diff = term->buffer[0] - text->buffer[0];
                    }
                    
                    if(diff)
                        return diff;
                    
                    int index;
                    for(index = 1; index < term->length; index++) {
                        
                        diff = term->buffer[index] - text->buffer[index];
                        if(diff)
                            return diff;
                    }
                    
                    return 0;
                    
                } else { // Different length.
                    
                    return -1;
                }
                
            }
            
            break;
            
        case unbuffer_compare_mode_hard:
            
            // Compare both buffer across their length. Buffer should already
            // be composed.
            
            if(!term->length > 0)
                return -1;
            
            if(term->length != text->length)
                return -1;
            
            int index;
            int diff;
            
            if(ignorecase) {
                
                unsigned int tmp0 = unbuffer_tolowcase(term->buffer[0]);
                unsigned int tmp1 = unbuffer_tolowcase(text->buffer[0]);
                diff = tmp0 - tmp1;
                
            } else {
                diff = term->buffer[0] - text->buffer[0];
            }
            
            
            if(diff)
                return diff;
            
            for(index = 1; index < term->length; index++) {
                
                diff = term->buffer[index] - text->buffer[index];
                if(diff)
                    return diff;
            }
            
            return 0;
            
            break;
            
        case unbuffer_compare_mode_soft:
            
            
            // Compare only the first item of both buffer. Buffer should be
            // already both decomposed.
            
            if(!((term->length > 0) || (text->length > 0)))
                return -1;
            
            if(ignorecase) {
                
                unsigned int tmp0 = unbuffer_tolowcase(term->buffer[0]);
                unsigned int tmp1 = unbuffer_tolowcase(text->buffer[0]);
                
                diff = tmp0 - tmp1;
                
            } else {
                diff = (term->buffer[0] - text->buffer[0]);
            }
            
            return diff;

            
        default:
            return -1;
            break;
    }
    
}

void unbuffer_decompose(unbuffer * buffer) {
	
	int pos = 0;
	
	unsigned int * decomposition = NULL;
	int decomposition_len = 0;
	
	int data_offset;
	unsigned int old_codepoint, codepoint;
	old_codepoint = 0;
	
	// Iterate over the buffer until fully decomposed.
	
	while(pos < buffer->length) {
	
		// Get the current codepoint and lookup it if necessary to
		// update the data.
		codepoint = buffer->buffer[pos];
		
        if(old_codepoint!=codepoint) {
		
			old_codepoint = codepoint;
			
			data_offset = unbuffer_data_lookupcodepoint(codepoint);
            
            if(unbuffer_data_iscanonical(data_offset)) {
                
                decomposition_len = unbuffer_data_decompositionlen(data_offset);
                decomposition = unbuffer_data_decomposition(data_offset);
                
            } else { // Here compatibility decomposition
                
                decomposition_len = 0; // No decomposition
            }
			
		}
		
		// Get the class. Local variable codepoint will change.
		if(decomposition_len != 0) {
		
			unbuffer_replace(buffer,pos,NULL,1,decomposition,decomposition_len);
			continue;
			
		} else {
			pos++;
		}
	} // End of while loop.
};