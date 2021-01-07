//
//  FlipContainer.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/11/15.
//
//

#import "FlipContainer.h"

@implementation FlipContainer

-(NSMutableArray *)ui {
    if(!_ui) {
        _ui = [NSMutableArray new];
    }
    return _ui;
}

-(NSMutableArray *)pdf {
    if(!_pdf) {
        _pdf = [NSMutableArray new];
    }
    return _pdf;
}

-(NSUInteger) count {
    return _pdf.count + _ui.count;
}

@end
