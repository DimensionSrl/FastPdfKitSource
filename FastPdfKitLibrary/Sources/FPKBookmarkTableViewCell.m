//
//  FPKEditBookmarkTableViewCell.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 23/09/14.
//
//

#import "FPKBookmarkTableViewCell.h"

@interface FPKBookmarkTableViewCell()<UITextFieldDelegate>
@end

@implementation FPKBookmarkTableViewCell

-(void)setBookmark:(FPKBookmark *)bookmark {
    if(_bookmark!=bookmark) {
        _bookmark = bookmark;
        self.textField.text = bookmark.title;
        self.titleLabel.text = bookmark.title;
    }
}

#pragma mark - UITextFieldDelegate

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self.delegate bookmarkTableViewCell:self
                             didEditText:textField.text
                                bookmark:self.bookmark];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self.delegate bookmarkTableViewCell:self
                             didEditText:textField.text
                                bookmark:self.bookmark];
    return NO;
}

#pragma mark - UITableViewCell

-(void)didTransitionToState:(UITableViewCellStateMask)state {
    
    if(state == UITableViewCellStateEditingMask) {
        
        [self.contentView bringSubviewToFront:self.textField];
        
    } else if (state == UITableViewCellStateDefaultMask) {
        
        [self.contentView bringSubviewToFront:self.titleLabel];
    }
}

-(void)willTransitionToState:(UITableViewCellStateMask)state {
    
    self.textField.text = self.bookmark.title;
    self.titleLabel.text = self.bookmark.title;
    
    if(state == UITableViewCellStateEditingMask) {
        
        [UIView animateWithDuration:0.25f animations:^{
            _textField.alpha = 1.0;
            _titleLabel.alpha = 0.0;
        }completion:^(BOOL completed){
            _textField.enabled = YES;
        }];
        
    } else if (state == UITableViewCellStateDefaultMask) {
        
        [UIView animateWithDuration:0.25f animations:^{
            _textField.alpha = 0.0;
            _titleLabel.alpha = 1.0;
        }completion:^(BOOL completed){
            _textField.enabled = NO;
        }];
    }
}

@end
