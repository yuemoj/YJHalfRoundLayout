//
//  YJHalfRoundLayout.h
//  YJHalfRoundLayout
//
//  Created by Ace on 16/4/9.
//  Copyright © 2016年 Ace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YJHalfRoundLayout : UICollectionViewFlowLayout
/// 圆心
@property (nonatomic, assign) CGPoint center;
/// item半径
@property (nonatomic, assign) CGFloat itemRadius;
/// 大圆半径
@property (nonatomic, assign) CGFloat roundRadius;
/// 每个item对应的offsetY
@property (nonatomic, assign) CGFloat offsetYPerItem;

@end


#import <QuartzCore/CADisplayLink.h>

@interface UICollectionView (YJSelectItem)
@property (nonatomic, assign) CGFloat offsetY;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) CADisplayLink *displayLink;

- (void)yjSelectItemAtIndexPath:(nullable NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;

@end