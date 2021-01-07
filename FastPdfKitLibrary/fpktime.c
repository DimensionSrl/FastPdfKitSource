//
//  fpkclock.c
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 04/12/14.
//
//

#include "fpktime.h"

void fpktime_stopwatch_init(fpktime_stopwatch * info) {
    info -> start = 0;
    info -> end = 0;
    info -> elapsed = 0;
    mach_timebase_info(&(info->timeBaseInfo));
}

void fpktime_stopwatch_start(fpktime_stopwatch * info) {
    info->start = mach_absolute_time();
}

void fpktime_stopwatch_stop(fpktime_stopwatch * info) {
    info->end = mach_absolute_time();
}

uint64_t fpktime_stopwatch_elapsedtime_nano(fpktime_stopwatch * info) {
    return (info->end - info->start) * info->timeBaseInfo.numer / info->timeBaseInfo.denom;
}