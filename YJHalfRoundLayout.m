//
//  YJHalfRoundLayout.m
//  YJHalfRoundLayout
//
//  Created by Ace on 16/4/9.
//  Copyright © 2016年 Ace. All rights reserved.
//

#import "YJHalfRoundLayout.h"
#import "objc/runtime.h"

#define COLLECTIONVIEW_WIDTH self.collectionView.frame.size.width
#define COLLECTIONVIEW_HEIGHT self.collectionView.frame.size.height
#define COLLECTIONVIEW_X self.collectionView.frame.origin.x
#define COLLECTIONVIEW_Y self.collectionView.frame.origin.y

@interface YJHalfRoundLayout ()
/// item 从大圆圆心出发的两条外切线间的角度
@property (nonatomic, assign) CGFloat anglePerItem;
/// item间隔角度
@property (nonatomic, assign) CGFloat angleBetweenItem;
/// item 与x轴的偏移角度
@property (nonatomic, assign) CGFloat angleDriftX;
/// collectionview一次最多显示的item数
@property (nonatomic, assign) NSInteger itemCountPerPage;

@end

@implementation YJHalfRoundLayout

/// 设置layout的相关属性
- (void)prepareLayout {
    [super prepareLayout];
    
    [self setDefault];
}

/// 重写布局函数
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSMutableArray *layoutArray = [NSMutableArray array];
    for (int i = 0; i <= itemCount - 1; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        CGFloat currentAngle = [objc_getAssociatedObject(attributes, @"currentAngle") floatValue];
        // 判断当前的angle(相对于x坐标轴)范围, 超出显示范围的不作布局
        if (currentAngle >= self.angleDriftX - self.anglePerItem && currentAngle <= 2 * M_PI + self.anglePerItem - self.angleDriftX) {
            [layoutArray addObject:attributes];
        }
    }
    return layoutArray;
}

/// 设置每个attribute的属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = self.itemSize;
    // offset偏移量对应的旋转角度
    CGFloat angleForOffsetY = self.itemCountPerPage * (self.anglePerItem + self.angleBetweenItem) / (COLLECTIONVIEW_HEIGHT - self.sectionInset.top - self.sectionInset.bottom) * self.collectionView.contentOffset.y;
    // 通过改变偏移量重设位置
//    NSLog(@"---------- contentoffsetY: %f",self.collectionView.contentOffset.y);
    // 圆心角
    CGFloat currentAngle = (self.anglePerItem + self.angleBetweenItem) * indexPath.item + self.angleDriftX - angleForOffsetY;
    CGFloat x = self.center.x - cosf(currentAngle) * (self.roundRadius - self.itemRadius);
    CGFloat y = self.center.y - sinf(currentAngle) * (self.roundRadius - self.itemRadius) + self.collectionView.contentOffset.y;
    NSLog(@"----------contentOffsetY: %f", self.collectionView.contentOffset.y);
    attributes.center = CGPointMake(x, y);
    objc_setAssociatedObject(attributes, @"currentAngle", [NSNumber numberWithFloat:currentAngle], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return attributes;
}

/* ---------- 待补充 ----------
/// item出现动画
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];

    return attributes;
}

/// item消失动画
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    
}
*/
/// 设置contentSize
- (CGSize)collectionViewContentSize {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    CGFloat pageCounts = (CGFloat)count / self.itemCountPerPage;
    CGSize contentSize = CGSizeMake(COLLECTIONVIEW_WIDTH, (COLLECTIONVIEW_HEIGHT -  self.sectionInset.top - self.sectionInset.bottom) * pageCounts);
    return contentSize;
}

/// 布局范围变化时重置layout
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

#pragma mark- ---------- 自定义方法 ----------
#pragma mark -懒加载
- (CGPoint)center {
    if (!_center.x && !_center.y) {
        _center = CGPointMake(0, COLLECTIONVIEW_Y + COLLECTIONVIEW_HEIGHT * 0.5);
    }
    return _center;
}

- (CGFloat)roundRadius {
    if (!_roundRadius) {
        _roundRadius = MIN(COLLECTIONVIEW_WIDTH, COLLECTIONVIEW_HEIGHT * 0.5);
    }
    return _roundRadius;
}

- (CGFloat)itemRadius {
    if (!_itemRadius) {
        _itemRadius = MAX(self.itemSize.width, self.itemSize.height) * 0.5;
    }
    return _itemRadius;
}

#pragma mark -初始化方法
/// 设置属性
- (void)setDefault {
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    // 获取item外切线角度
    self.anglePerItem = 2 * asin(self.itemRadius / (self.roundRadius - self.itemRadius));
    // 圆心与第一个item圆心连线偏移x轴角度
    self.angleDriftX = acos((self.center.x - self.itemRadius - self.sectionInset.left) / (self.roundRadius - self.itemRadius));
    // 获取collectionview显示的item最大数
    self.itemCountPerPage = floor(2 * (M_PI - self.angleDriftX) / self.anglePerItem) + 1;
    // item间隔角度
    self.angleBetweenItem = 2 * (M_PI - self.angleDriftX) / (self.itemCountPerPage - 1) -  self.anglePerItem;
    // item对应的offsetY
    self.offsetYPerItem = (COLLECTIONVIEW_HEIGHT - self.sectionInset.top - self.sectionInset.bottom) / self.itemCountPerPage;
}

@end



@implementation UICollectionView (YJSelectItem)

- (void)setDisplayLink:(CADisplayLink *)displayLink {
    objc_setAssociatedObject(self, @"YJDisplayLink", displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CADisplayLink *)displayLink {
    return (CADisplayLink *)objc_getAssociatedObject(self, @"YJDisplayLink");
}

- (void)setOffsetY:(CGFloat)offsetY {
    objc_setAssociatedObject(self, @"YJOffset", [NSNumber numberWithFloat:offsetY], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)offsetY {
    return [objc_getAssociatedObject(self, @"YJOffset") floatValue];
}

- (void)setCount:(NSInteger)count {
    objc_setAssociatedObject(self, @"YJCount", [NSNumber numberWithInteger:count], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSInteger)count {
    return [objc_getAssociatedObject(self, @"YJCount") integerValue];
}


- (void)yjSelectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition {
    YJHalfRoundLayout *layout = (YJHalfRoundLayout *)self.collectionViewLayout;
    // 根据显示的位置补差
    CGFloat addOffsetY = 0.0f;
    switch (scrollPosition) {
        case UICollectionViewScrollPositionCenteredVertically:
            // 上下居中
            addOffsetY = self.height * 0.5 - layout.offsetYPerItem * 0.5;
            break;
        case UICollectionViewScrollPositionBottom:
            // 底部显示
            addOffsetY = self.height - layout.offsetYPerItem;
            break;
        default:
            break;
    }
    
    // 最大可偏移量
    CGFloat maxOffsetY = MAX(0, self.contentSize.height - self.height);
    // 实际需要的偏移量
    CGFloat itemOffsetY = MAX(layout.offsetYPerItem * indexPath.item - addOffsetY, 0);
    // 结束的偏移量
    CGFloat endOffsetY = MIN(maxOffsetY, itemOffsetY);
    // 最终计算出偏移距离
    self.offsetY = self.contentOffset.y - endOffsetY;
    
    if (animated) {
        if (self.displayLink) {
            [self.displayLink invalidate];
        }
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.count = 0;
    } else {
        self.contentOffset = CGPointMake(0, endOffsetY);
    }
}

/*
 * 预设1s减速到0, displayLink默认1秒执行60次, 单位时间 t = 1 / 60, 单位时间count为累计数
 * 根据匀减速公式, vt^2 - v0^2 = 2 * a * s , vt = v0 + at, vt = 0计算, a = - 2 * s, v0 = 2 * s
 * 计算s' = (v2^2 - v1^2) / 2 * a = ((v0 + a * count * t)^2 - (v0 + a * (count - 1) * t)^2) / 2 * a
 * s' = 2 * s * t * (1 - t * (count - 0.5))
 */

- (void)displayLinkAction:(CADisplayLink *)displayLink {
    self.count++;
    self.contentOffset = CGPointMake(0, self.contentOffset.y - 2 * self.offsetY * (1 - (self.count - 0.5) / 60) / 60);
    NSLog(@"---------- self.contentOffsetY:%f", self.contentOffset.y);
    if (self.count > 60) {
        [displayLink invalidate];
        displayLink = nil;
    }
}

- (void)dealloc {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

@end
