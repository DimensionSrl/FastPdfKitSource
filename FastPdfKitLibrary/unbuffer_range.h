#ifndef _UNBUFFER_RANGE_H_
#define _UNBUFFER_RANGE_H_

#include "unbuffer_data.h"

typedef struct unbuffer_range {
	unsigned int first;
	unsigned int last;
} unbuffer_range;

void unbuffer_range_init(unbuffer_range * range, unsigned int first, unsigned int last);

int unbuffer_range_compare(unbuffer_range * r0, unbuffer_range * r1);

int unbuffer_range_containsdata(unbuffer_range * range, unbuffer_data * data);

/**
	Will return -1 if the codepoint in the data is not contained in one of the ranges.
*/
int unbuffer_range_lookupdata(unbuffer_range * ranges, unbuffer_data * data, int min, int max);

/**
	Print the range to screen (stdout).
*/
void unbuffer_range_print(unbuffer_range * range);

#endif