#include "unbuffer_range.h"
#include <stdio.h>

void unbuffer_range_init(unbuffer_range * range, unsigned int first, unsigned int last) {
	range->first = first;
	range->last = last;
};

int unbuffer_range_compare(unbuffer_range * r0, unbuffer_range * r1) {
	
	return ((r0->first) - (r1->first));
};

int unbuffer_range_containsdata(unbuffer_range * range, unbuffer_data * data) {
	
	if(data->codepoint > range->last)
		return 1;
	
	if(data->codepoint < range->first)
		return -1;
		
	return 0;
};

int unbuffer_range_lookupdata(unbuffer_range * ranges, unbuffer_data * data, int min, int max) {
	
	// Binary search.
	
	if(min > max) 
		return -1;
	
	int mid = min + (max - min)/2;
	
	int difference = unbuffer_range_containsdata(&ranges[mid],data);
	
	if(difference == 0) { // Inside range difference, we have found it!
		
		return mid;
		
	} else if (difference > 0)  { // Data codepoint is greater.
		
		return unbuffer_range_lookupdata(ranges, data, (mid + 1), max);
		
	} else { // Data codepoint is smaller.
		
		return unbuffer_range_lookupdata(ranges, data, min, (mid - 1));
	}
};

void unbuffer_range_print(unbuffer_range * range) {
	fprintf(stdout,"%X..%X\n",range->first,range->last);
}

