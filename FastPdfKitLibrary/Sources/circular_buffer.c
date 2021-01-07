//
//  circular_buffer.c
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 9/26/12.
//
//

#include <stdio.h>
#include "circular_buffer.h"
#include <stdlib.h>

void cb_init(CircularBuffer * buffer, int size) {
    
	buffer->size = size+1;
	buffer->buffer = calloc(buffer->size, sizeof(int));
	buffer->head = 0;
	buffer->tail = 0;
	buffer->current = 0;
	buffer->count = 0;
}

void cb_destroy(CircularBuffer * buffer) {
	buffer->head = 0;
	buffer->tail = 0;
	buffer->current = 0;
	free(buffer->buffer);
	buffer->count = 0;
}

void cb_addPage(CircularBuffer * buffer, int page) {
    
	if(buffer->count == 0) {
		
		buffer->buffer[buffer->head] = page;
		buffer->current = buffer->head;
		buffer->head = buffer->head + 1 + buffer->size % buffer->size;
		buffer->count = ((buffer->current - buffer->tail + buffer->size) % buffer->size) + 1;
		
	} else {
		
		int new_pos = (buffer->current + 1) % buffer->size;
		buffer->head = new_pos;
		buffer->buffer[buffer->head] = page;
		buffer->current = buffer->head;
		buffer->head = (buffer->head + 1 + buffer->size) % buffer->size;
		
		if(buffer->tail == buffer->head)
			buffer->tail = (buffer->tail +1 + buffer->size) % buffer->size;
		buffer->count = ((buffer->current - buffer->tail + buffer->size) % buffer->size) + 1;
	}
}

int cb_pageCount(CircularBuffer * buffer) {
    return ((buffer->head - buffer->tail) + buffer->size ) % buffer->size;
}

int cb_currentPage(CircularBuffer * buffer) {
    
    if(buffer->tail == buffer->head)
        return 0;
    
    return buffer->buffer[buffer->current];
}

int cb_nextPage(CircularBuffer * buffer) {
	
	// If the current is up to the head we don't have a next page
	
	int new_current = (buffer->current + 1 + buffer->size) % buffer->size;
	
	if(new_current == buffer->head)
		return 0;
	
	// Get the page
	int page = buffer->buffer[new_current];
	
	// Update the current
	buffer->current = new_current;
	
	return page;
}

int cb_prevPage(CircularBuffer * buffer) {
    
	// If the current is up to the tail
	if(buffer->current == buffer->tail)
		return 0;
    
	// Move down the current pointer
	int current = (buffer->current - 1 + buffer->size) % buffer->size;
	
	// Get the page
	int page = buffer->buffer[current];
	
	// Update the current
	buffer->current = current;
	
	return page;
}

int cb_nextCount(CircularBuffer * buffer) {
    
    return (((buffer->head - buffer->current) + buffer->size) % buffer->size) - 1;
}

int cb_prevCount(CircularBuffer * buffer) {
    
    return ((buffer->current - buffer->tail) + buffer->size) % buffer->size;
}
