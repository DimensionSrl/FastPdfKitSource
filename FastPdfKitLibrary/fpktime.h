//
//  fpkclock.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#ifndef __FastPdfKitLibrary__fpkclock__
#define __FastPdfKitLibrary__fpkclock__

#include <stdio.h>
#import <mach/mach_time.h>

typedef struct fpktime_stopwatch {
    uint64_t start;
    uint64_t end;
    uint64_t elapsed;
    mach_timebase_info_data_t timeBaseInfo;
} fpktime_stopwatch;

void fpktime_stopwatch_init(fpktime_stopwatch * info);
void fpktime_stopwatch_start(fpktime_stopwatch * info);
void fpktime_stopwatch_stop(fpktime_stopwatch * info);
uint64_t fpktime_stopwatch_elapsedtime_nano(fpktime_stopwatch * info);

#endif /* defined(__FastPdfKitLibrary__fpkclock__) */
