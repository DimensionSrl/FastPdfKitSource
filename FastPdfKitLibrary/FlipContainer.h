//
//  FlipContainer.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 19/11/15.
//
//

#import <Foundation/Foundation.h>

@interface FlipContainer : NSObject

@property (nonatomic, strong) NSMutableArray * ui;
@property (nonatomic, strong) NSMutableArray * pdf;

-(NSUInteger) count;

@end