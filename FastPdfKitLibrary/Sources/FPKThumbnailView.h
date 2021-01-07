//
//  FPKThumbnailView.h
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 21/11/14.
//
//

#import <UIKit/UIKit.h>
#import "MFDocumentManager.h"

static NSString * const FPKThumbnailViewCellIdentifier = @"FPKThumbnailViewCell";

@interface FPKThumbnailView : UIView
@property (nonatomic, readonly) UICollectionView * collectionView;
@property (nonatomic, strong) MFDocumentManager * document;
@end


@protocol FPKThumbnailVIew <NSObject>

@property (nonatomic, readwrite) NSUInteger pageNumber;
@property (nonatomic, readwrite) BOOL loading;

@end
