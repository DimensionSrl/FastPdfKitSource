//
//  FPKSearchMatchItem.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 21/04/15.
//
//

#import <UIKit/UIKit.h>
#import "MFTextItem.h"

@interface FPKSearchMatchItem : NSObject <MFOverlayDrawable>

/**
 * The base MFTextItem.
 */
@property (nonatomic, strong) MFTextItem * textItem;

/**
 * The highlight view.
 */
@property (nonatomic,readonly,weak) UIView * highlightView;

@property (nonatomic,readonly) CGRect boundingBox;

@property (nonatomic,strong) UIColor * highlightColor;

/**
 * Red color with 0.25 opacity.
 */
+(UIColor *)highlightRedColor;

/**
 * Yellow color with 0.25 opacity.
 */
+(UIColor *)highlightYellowColor;

/**
 * Blue color with 0.25 opacity.
 */
+(UIColor *)highlightBlueColor;

+(FPKSearchMatchItem *)searchMatchItemWithTextItem:(MFTextItem *)item;
+(NSArray *)searchMatchItemsWithTextItems:(NSArray *)items;

@end
