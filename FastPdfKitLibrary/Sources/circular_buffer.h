//
//  circular_buffer.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 9/26/12.
//
//

#ifndef FastPdfKitLibrary_circular_buffer_h
#define FastPdfKitLibrary_circular_buffer_h

typedef struct CircularBuffer {
	
	int * buffer;
	int head, tail, current;
	int size;
	int count;
	
} CircularBuffer;

void cb_init(CircularBuffer * buffer, int size);
void cb_destroy(CircularBuffer * buffer);

void cb_addPage(CircularBuffer * buffer, int page);
int cb_nextPage(CircularBuffer * buffer);
int cb_prevPage(CircularBuffer * buffer);
int cb_currentPage(CircularBuffer * buffer);
int cb_nextCount(CircularBuffer * buffer);
int cb_prevCount(CircularBuffer * buffer);
int cb_currentPage(CircularBuffer * buffer);

int cb_nextCount(CircularBuffer * buffer);
int cb_prevCount(CircularBuffer * buffer);
int cb_pageCount(CircularBuffer * buffer);

#endif
