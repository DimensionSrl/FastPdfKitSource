//
//  FPKEditBookmarkTableViewCell.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 23/09/14.
//
//

#import <UIKit/UIKit.h>
#import "FPKBookmark.h"

@protocol FPKBookmarkTableViewCellDelegate;

@interface FPKBookmarkTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextField * textField;

@property (nonatomic, weak) IBOutlet UILabel * titleLabel;

@property (nonatomic, weak) FPKBookmark * bookmark;

@property (nonatomic, weak) id<FPKBookmarkTableViewCellDelegate> delegate;

@end


@protocol FPKBookmarkTableViewCellDelegate

/**
 * This method is invoked when the user has done editing the bookmark.
 * @param cell The bookmark UITableViewCell.
 * @param text The text the user inserted for the bookmark title.
 * @param bookmark The FPKBookmark bookmark.
 */
-(void)bookmarkTableViewCell:(FPKBookmarkTableViewCell *)cell didEditText:(NSString *)text bookmark:(FPKBookmark *)bookmark;

@end
