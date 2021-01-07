//
//  FPKThumbnailView.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 21/11/14.
//
//

#import "FPKThumbnailView.h"

@interface FPKThumbnailView() <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong, readwrite) UICollectionView * collectionView;
@end

@implementation FPKThumbnailView

#pragma mark - UICollectionView

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = [self identifierForIndexPath:indexPath];
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    
    
    return cell;
}

-(NSString *)identifierForIndexPath:(NSIndexPath *)indexPath {
    return FPKThumbnailViewCellIdentifier;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.document numberOfPages];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark - UIVIew

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        UICollectionView * collectionView = [[UICollectionView alloc]initWithFrame:frame];
        collectionView.delegate = self;
        self.collectionView = collectionView;
        [self addSubview:collectionView];
    }
    return self;
}

@end
