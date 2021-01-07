//
//  FPKOverlayCaches.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 02/09/15.
//
//

#import <Foundation/Foundation.h>

@interface FPKOverlayCaches : NSObject

@property (nonatomic, strong) NSMutableDictionary * caches;

/**
 * Clear all the caches.
 */
-(void)removeAllObjects;

/**
 * Add a cache with the given name.
 * @param cache The cache.
 * @param name The name.
 */
-(void)setCache:(id)cache name:(NSString *)name;

/**
 * Return a cache with the given name.
 * @param name The name,
 * @return The cache for the given name, if found.
 */
-(id)cacheForName:(NSString *)name;

@end
