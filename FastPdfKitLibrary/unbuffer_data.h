#ifndef _UNBUFFER_DATA_H_
#define _UNBUFFER_DATA_H_

// Erika Flynn

extern unsigned int unbuffer_unicode_data [];
extern int unbuffer_unicode_data_len;
extern unsigned short unbuffer_codepoint_offsets [];
extern int unbuffer_codepoint_offsets_len;
extern unsigned short unbuffer_decomposition_offsets [];
extern int unbuffer_decomposition_offsets_len;
extern unsigned short unbuffer_compatibility_offsets [];
extern int unbuffer_compatibility_offsets_len;

typedef struct unbuffer_data {
	unsigned int codepoint;
	unsigned char decomposition_len;
	unsigned int * decomposition;
	unsigned char class;
	unsigned char canonical;
} unbuffer_data;

// Init from array.
void unbuffer_data_init(unbuffer_data * data, unsigned int * src);

// Init with parameters.
void unbuffer_data_init_p(unbuffer_data * data,		// Struct to be initialized
	unsigned int codepoint, 					// Unicode value
	unsigned char class, 					// Class
	unsigned char canonical, 				// Canonical or not
	unsigned char decomposition_len, 		// Decomposition values count (0 = NONE)
	unsigned int * decomposition); 	// Decomposition values array

void unbuffer_data_destroy(unbuffer_data * data); 

int unbuffer_data_write(unbuffer_data * data, unsigned int * dst);
		
int unbuffer_data_size(unbuffer_data * data);

void unbuffer_data_print(unbuffer_data * data);

// Sorting and search.

int unbuffer_data_compare(unbuffer_data * d0, unbuffer_data * d1);	

void unbuffer_data_sort(int * positions, int positions_len, unsigned int * data);

int unbuffer_data_lookupdecomposition(unsigned int * deco, int deco_len);
int unbuffer_data_lookupcodepoint(unsigned int codepoint);
int unbuffer_data_lookupcompatibility(unsigned int * deco, int deco_len);

//int unbuffer_data_lookupdata(unbuffer_data * decomposition, int * positions, unsigned int * data, int min, int max);


unsigned int unbuffer_data_codepoint(int offset);
int unbuffer_data_iscanonical(int offset);
int unbuffer_data_class(int offset);
int unbuffer_data_decompositionlen(int offset);
unsigned int * unbuffer_data_decomposition(int offset);

#endif