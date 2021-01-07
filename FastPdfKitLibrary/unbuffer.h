#ifndef _UNBUFFER_H_
#define _UNBUFFER_H_

extern const int unbuffer_def_size;

enum unbuffer_compose_mode {
    unbuffer_compose_mode_canonical = 0,
    unbuffer_compose_mode_compatibility = 1
};
typedef unsigned int unbuffer_compose_mode;

enum unbuffer_compare_mode {
    unbuffer_compare_mode_smart = 0,
    unbuffer_compare_mode_hard = 1,
    unbuffer_compare_mode_soft = 2
};
typedef unsigned int unbuffer_compare_mode;

typedef struct unbuffer {

	unsigned int * buffer;
	int size;
	int length;
	
} unbuffer;

void unbuffer_init_with_codepoint(unbuffer * buffer, unsigned int cpt);
void unbuffer_init_with_codepoints(unbuffer * buffer, unsigned int * cpts, int len);
void unbuffer_destroy(unbuffer * buffer);

void unbuffer_clear(unbuffer * buffer);

void unbuffer_print(unbuffer * buffer);

// Composition and decomposition.

void unbuffer_decompose(unbuffer * buffer);
void unbuffer_compose(unbuffer * buffer, unbuffer_compose_mode mode);
int unbuffer_compare(unbuffer * term, unbuffer * text, int mode, int ignorecase);

#endif