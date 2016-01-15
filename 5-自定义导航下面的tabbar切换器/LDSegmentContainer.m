//
//  LDSegmentContainer.m
//  5-自定义导航下面的tabbar切换器
//
//  Created by silence on 15/10/19.
//  Copyright © 2015年 silence. All rights reserved.
//

#import "LDSegmentContainer.h"
#import "UIView+Common.h"
#define itemView_start_tag 111

#define font(a) [UIFont systemFontOfSize:a]

@interface LDSegmentContainer () <UIScrollViewDelegate>
{
    BOOL _didLoadData;
    NSInteger _curIndex;
}
@property (nonatomic, strong) UIScrollView *topBar; /**< 顶部滚动栏 */
@property (nonatomic, strong) UIScrollView *containerView; /**< 底部滚动容器 */

@property (nonatomic, assign) NSUInteger itemCount;/**< 总共有多少项 */
@property (nonatomic, strong) NSMutableArray *itemViewArray; /**< 所有的控制器数组 */
@property (nonatomic, strong) NSMutableDictionary *contentsDic;/**<  */

@property (nonatomic, strong) UIView *lineView;/** 底部分割线 */

@end

@implementation LDSegmentContainer


#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.topBarHeight = [UIScreen mainScreen].scale == 3 ? 42 : 36; // 顶部选项条默认高度
        self.itemPadding = 20; // 项与项之间默认距离
        self.bottomLineHeight = 0.5;//分隔线默认高度
        self.allowGesture = YES; // 默认是可以通过滑动来进行切换选项
        self.expandToTopBarWidth = YES; // 默认铺满topBar的宽高
        self.containerBackgroundColor = [UIColor redColor];
        
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:self.lineView];
        [self addSubview:self.topBar];
        [self addSubview:self.containerView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_didLoadData) {
        _didLoadData = YES;
        [self reloadData];//在layoutsubview中(本控件第一次显示时)调用reloadData可以保证reload时，所依赖的视图大小都已是实际显示大小。
    }
    
    self.containerView.frame = CGRectMake(0, self.topBar.bottom, self.width, self.height - self.topBar.height);
    self.containerView.contentSize = CGSizeMake(self.containerView.contentSize.width, self.containerView.height);
}

#pragma mark - reloadData
- (void)reloadData
{
    if (!_didLoadData
        || !self.delegate
        || ![self.delegate respondsToSelector:@selector(numberOfItemsInSegmentContainer:)]
        || ![self.delegate respondsToSelector:@selector(segmentContainer:titleForItemAtIndex:)]
        || ![self.delegate respondsToSelector:@selector(segmentContainer:contentForIndex:)] )
    {
        return;
    }
    
    self.itemCount = [self.delegate numberOfItemsInSegmentContainer:self];
    [self reloadTopBar];
    [self reloadContainerView];
    
    if (self.currentIndex >= self.itemCount) {
        _currentIndex = 0;
    }
    [self setSelectedIndex:self.currentIndex withAnimated:NO];
    
    
    // 数据刷新
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentContainerDidReloadData:)]) {
        [self.delegate segmentContainerDidReloadData:self];
    }
}



/***************************************************************************************/
#pragma mark - TopBar Private Methods

- (void)reloadTopBar
{
    if (self.itemCount <= 1) {
        self.topBar.frame = CGRectMake(0, 0, self.topBar.width, 0);
        return;
    }
    
    self.topBar.frame = CGRectMake(0, 0, self.topBar.width, self.topBarHeight);
    
    /*------------- 删除顶部的所有按钮但是不删除srollView中的指示器 -----------------*/
    for (UIButton *btn in self.itemViewArray) {
        [btn removeFromSuperview];
    }
    
    [self.itemViewArray removeAllObjects];
    /*------------------------------------------------------------------------*/
    
    for (NSInteger i = 0; i < self.itemCount; i++) {
        UIButton *btn = [self itemButtonForIndex:i];
        [self.topBar addSubview:btn];
        [self.itemViewArray addObject:btn];
    }
    
    
    // 如果该值为YES，则会忽略对顶部选项条的所有配置的间隔值，且选项条与父视图同宽，不能滑动，对选项条进行平均分割，即每一个选项的宽度相同。默认为NO。
    if (self.averageSegmentation) {
        [self reLayoutTopBarUseAverageMode];
    } else {
        [self reLayoutTopBar];
    }
}

- (void)reLayoutTopBarUseAverageMode
{
    self.topBar.contentSize = self.topBar.bounds.size;
    
    CGFloat leftPos = 0;
    CGFloat averageWith = self.topBar.width / self.itemCount;
    for (NSInteger i = 0; i < self.itemViewArray.count; i++) {
        
        UIButton *btn = [self.itemViewArray objectAtIndex:i];
        btn.x = leftPos;
        btn.width = averageWith;
        leftPos = btn.right;
    }
}

- (void)reLayoutTopBar
{
    CGFloat horizonMargin = self.horizontalInset > 0 ? self.horizontalInset : 0.5 * self.itemPadding; // 左右缩进量默认为padding的一半，如果设置了horizontalInset, 则按horizontalInset计算
    CGFloat leftPos = horizonMargin;
    for (NSInteger i = 0; i < self.itemViewArray.count; i++) {
        UIButton *btn = [self.itemViewArray objectAtIndex:i];
        btn.x = leftPos;
        leftPos += btn.width + self.itemPadding;
    }
    
    
    
    // 所有控件布局完成后，最右边的位置
    CGFloat rigthPos = leftPos - self.itemPadding + horizonMargin;
    self.topBar.contentSize = CGSizeMake(rigthPos, self.topBar.height);
    
    // 超过屏幕宽度20个像素才滑动，否则调整间距，使之刚好铺满屏幕
    if (rigthPos >= self.topBar.width + 20) {
        
            self.topBar.contentSize = CGSizeMake(rigthPos, self.topBar.height);
        
    } else {
            self.topBar.contentSize = self.topBar.bounds.size;
            
            CGFloat detal = (self.topBar.width - rigthPos) / self.itemCount;
            
            if (detal < 0 || self.expandToTopBarWidth) {
                
                for (NSInteger i = 0; i < self.itemViewArray.count ; i++ ) {
                    UIButton *btn = [self.itemViewArray objectAtIndex:i];
                    btn.x += (i + 0.5) * detal;
                }
            }
    }
    
}



#pragma mark - topBar__itemButtonForIndex
- (UIButton *)itemButtonForIndex:(NSUInteger)index
{
    if (self.delegate
        && index < self.itemCount
        && [self.delegate respondsToSelector:@selector(segmentContainer:titleForItemAtIndex:)])
    {
        NSString *title = [self.delegate segmentContainer:self titleForItemAtIndex:index];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = itemView_start_tag + index;
        [button.titleLabel setFont:self.titleFont];
//        button.backgroundColor = [UIColor lightGrayColor];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:self.titleNormalColor forState:UIControlStateNormal];
        [button setTitleColor:self.titleSelectedColor forState:UIControlStateSelected];
        
        [button addTarget:self action:@selector(itemButtonsClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        button.frame = CGRectMake(0, 0, button.width + 20, self.topBarHeight);
//        CGFloat btnW = self.topBar.width / (CGFloat)self.itemCount;
//        button.frame = CGRectMake(0, btnW * (index + 1), btnW , self.topBarHeight);
//        button.frame = CGRectMake(0, 0, btnW - 10, self.topBarHeight);
        
        return button;
    }
    
    return nil;
}

- (void)itemButtonsClicked:(UIButton *)button
{
    _curIndex = button.tag - itemView_start_tag;
    [self scrollToItemAtIndex:button.tag - itemView_start_tag withAnimated:YES slide:NO];
    
}


- (void)scrollToItemAtIndex:(NSUInteger)index withAnimated:(BOOL)animated slide:(BOOL)slide
{
    if (index >= self.itemCount) { // 大于总页数不需要再进行滚动
        return;
    }
    
    [self willScrollToIndex:index]; // 在需要的时候添加视图
    
    NSUInteger oldIndex = self.currentIndex;
    _currentIndex = index;
    _curIndex = index;
    
    [self setContentAtIndex:oldIndex scrollToTop:NO];
    [self setContentAtIndex:index scrollToTop:YES];
    
    UIButton *origin = (UIButton *)[self.itemViewArray objectAtIndex:oldIndex];
    origin.selected = NO;
    
    UIButton *newBtn = (UIButton *)[self.itemViewArray objectAtIndex:index];
    newBtn.selected = YES;
    if (newBtn.currentTitleColor == self.titleNormalColor && origin.currentTitleColor == self.titleSelectedColor) {
        newBtn.titleLabel.font = font(15);
        origin.titleLabel.font = font(15);
    } else {
        origin.titleLabel.font = font(15);
        newBtn.titleLabel.font = font(15 * 1.2);
    }
    
    CGPoint containOffset = CGPointMake(index * self.containerView.width, 0);
    
    if (animated) {
        
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:0.2 animations:^{
                __strong typeof(weakSelf) strongSelf = self;
                
                strongSelf.containerView.contentOffset = containOffset;
                [strongSelf scrollRectToVisibleCenteredOn:newBtn.frame animated:NO];
            
            } completion:^(BOOL finished) {
                __strong typeof(weakSelf) strongSelf = self;
                if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(segmentContainer:didSelectedItemAtIndex:)]) {
                    [self.delegate segmentContainer:strongSelf didSelectedItemAtIndex:index];
                }
                
                if (slide) {
                    
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(segmentContainer:didSlideToItemAtIndex:)]) {
                        [strongSelf.delegate segmentContainer:strongSelf didSlideToItemAtIndex:index];
                    }
                    
                } else {
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(segmentContainer:didSelectedItemAtIndex:)]) {
                        [strongSelf.delegate segmentContainer:strongSelf didSelectedItemAtIndex:index];
                    }
                }
                
            }];
        
        
    } else {
        
        
            self.containerView.contentOffset = containOffset;
            [self scrollRectToVisibleCenteredOn:newBtn.frame animated:NO];
            if (self.delegate && [self.delegate respondsToSelector:@selector(segmentContainer:didSelectedItemAtIndex:)]) {
                [self.delegate segmentContainer:self didSelectedItemAtIndex:index];
            }
            if (slide) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(segmentContainer:didSlideToItemAtIndex:)]) {
                    [self.delegate segmentContainer:self didSlideToItemAtIndex:index];
                }
            }
            else{
                if (self.delegate && [self.delegate respondsToSelector:@selector(segmentContainer:didClickedItemAtIndex:)]) {
                    [self.delegate segmentContainer:self didClickedItemAtIndex:index];
                }
            }
        
    }
    
}

- (void)scrollRectToVisibleCenteredOn:(CGRect)visibleRect
                             animated:(BOOL)animated {
    CGRect centeredRect = CGRectMake(visibleRect.origin.x + visibleRect.size.width/2.0 - self.topBar.width/2.0,
                                     visibleRect.origin.y + visibleRect.size.height/2.0 - self.topBar.height/2.0,
                                     self.topBar.width,
                                     self.topBar.height);
    [self.topBar scrollRectToVisible:centeredRect
                            animated:animated];
}

     
- (void)willScrollToIndex:(NSUInteger)index
{
    //做视图预加载，显示index页时，提前添加其前后页面
    [self addContentAtIndex:index - 1];
    [self addContentAtIndex:index];
    [self addContentAtIndex:index + 1];
}

- (void)addContentAtIndex:(NSInteger)index
{
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(segmentContainer:contentForIndex:)]) {
        return;
    }
    
    if (index < 0 || index >= self.itemCount) {
        return;
    }
    
    id content = [self.contentsDic objectForKey:[self savedKeyForContentAtIndex:index]];
    
    if (content) {
        UIView *view = nil;
        if ([content isKindOfClass:[UIView class]]) {
            view = content;
        } else if ([content isKindOfClass:[UIViewController class]]) {
            view = [(UIViewController *)content view];
        }
        
        if (view.x != index * self.containerView.width) {
            view.frame = CGRectMake(index * self.containerView.width, 0, self.containerView.width, self.containerView.height);
        }
        
    } else {
        
        content = [self.delegate segmentContainer:self contentForIndex:index];
        
        if (content) {
            [self.contentsDic objectForKey:[self savedKeyForContentAtIndex:index]];
            
            if ([content isKindOfClass:[UIView class]]) {
                
                UIView *contentView = (UIView *)content;
                contentView.frame = CGRectMake(index * self.containerView.width, 0, self.containerView.width, self.containerView.height);
                [self.containerView addSubview:contentView];
                
            } else if ([content isKindOfClass:[UIViewController class]]) {
                UIViewController *vc = (UIViewController *)content;
                if (self.parentVC) {
                    [self.parentVC addChildViewController:vc];
                    [vc didMoveToParentViewController:self.parentVC];
                }
                
                vc.view.frame = CGRectMake(index * self.containerView.width, 0, self.containerView.width, self.containerView.height);
                [self.containerView addSubview:vc.view];
            }
            
            [self setContentAtIndex:index scrollToTop:NO];// 默认scrollsTotop为NO,只有当显示时才为YES
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(segmentContainer:preDisplayItemAtIndex:)]) {
                [self.delegate segmentContainer:self preDisplayItemAtIndex:index];
            }
        }
        
        
    }
    
}

- (NSString *)savedKeyForContentAtIndex:(NSUInteger)index
{
    return [NSString stringWithFormat:@"%lu",(unsigned long)index];
}


// 设置scrollview的scrollsToTop属性
- (void)setContentAtIndex:(NSInteger)index scrollToTop:(BOOL)scrollsToTop
{
    id content = [self contentAtIndex:index];
    if (content) {
        UIView *superView = nil;
        
        if ([content isKindOfClass:[UIViewController class]]) {
            
            superView = ((UIViewController *)content).view;
            
        } else if ([content isKindOfClass:[UIView class]]) {
            
            if ([content isKindOfClass:[UIScrollView class]]) {
                
                UIScrollView *scrollView = (UIScrollView *)content;
                scrollView.scrollsToTop = scrollsToTop;
                superView = scrollView;
                
            } else {
                
                superView = (UIView *)content;
                
            }
            
            
            if (superView) {
                [self setSubView:superView scrollsTotop:scrollsToTop];
            }
            
        }
    }
}

// 设置superview的subView中的scrollView的scrollsToTop
- (void)setSubView:(UIView *)superView scrollsTotop:(BOOL)scrollsTop
{
    for (NSInteger i = self.superview.subviews.count - 1; i >= 0; i--) {
        UIView *subView = [superView.subviews objectAtIndex:i];
        
        if ([subView isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)subView;
            scrollView.scrollsToTop = scrollsTop;
            break;
        }
        
        [self setSubView:subView scrollsTotop:scrollsTop];
    }
}


/***************************************************************************************/

#pragma mark - ContainerView Relative Methods
- (void)reloadContainerView
{
    for (UIView *subview in self.containerView.subviews) {
        [subview removeFromSuperview];
    }
    
    if (self.parentVC) {
        for (UIViewController *child in self.parentVC.childViewControllers) {
            [child removeFromParentViewController];
        }
    }
    [self.contentsDic removeAllObjects];
    
    self.containerView.contentSize = CGSizeMake(self.itemCount * self.containerView.width, self.containerView.height);
}




#pragma mark - item switch
- (void)switchTab
{
    [self scrollToItemAtIndex:++_curIndex withAnimated:YES slide:NO];
//    [self scrollToItemAtIndex:++_curIndex withAnimation:YES slide:NO];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / scrollView.width;
    if (page != self.currentIndex) {
        _curIndex = page;
        [self scrollToItemAtIndex:page withAnimated:YES slide:YES];
    }
}


#pragma mark - config
- (void)setSelectedIndex:(NSUInteger)index withAnimated:(BOOL)animated
{
    if (!_didLoadData) {
        
        _currentIndex = index;
        _curIndex = index;
        
    } else {
        [self scrollToItemAtIndex:index withAnimated:animated slide:NO];
    }
}


- (UIButton *)itemAtIndex:(NSUInteger)index
{
    return [self.itemViewArray objectAtIndex:index];
}


- (id)contentAtIndex:(NSUInteger)index
{
    return [self.contentsDic objectForKey:[self savedKeyForContentAtIndex:index]];
}


- (void)addCustomViewToTopBar:(UIView *)customView onRight:(BOOL)onRight
{
    if (customView) {
        customView.centerY = customView.centerY;
        customView.x = onRight ? self.width - customView.width : 0;
        [self insertSubview:customView belowSubview:self.containerView];
        
        self.topBar.width -= customView.width;
        [self reLayoutTopBar];
    }
    
}





#pragma mark - Properties

- (NSMutableArray *)itemViewArray
{
    if (!_itemViewArray) {
        _itemViewArray = [[NSMutableArray alloc] init];
    }
    return _itemViewArray;
}

- (NSMutableDictionary *)contentsDic
{
    if (!_contentsDic) {
        _contentsDic = [[NSMutableDictionary alloc] init];
    }
    return _contentsDic;
}


- (UIScrollView *)topBar
{
    if (!_topBar) {
        _topBar = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.topBarHeight)];
        _topBar.showsHorizontalScrollIndicator = NO;
        _topBar.showsVerticalScrollIndicator = NO;
        _topBar.bounces = NO;
        _topBar.directionalLockEnabled = NO;
        _topBar.scrollsToTop = YES;
        
    }
    return _topBar;
}

- (UIScrollView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.topBarHeight, self.width, self.height - self.topBarHeight)];
        _containerView.showsHorizontalScrollIndicator = NO;
        _containerView.showsVerticalScrollIndicator = NO;
        _containerView.bounces = NO;
        _containerView.pagingEnabled = YES;
        _containerView.directionalLockEnabled = YES;
        _containerView.scrollsToTop = YES;
        _containerView.delegate = self;
        _containerView.backgroundColor = self.containerBackgroundColor;
    }
    return _containerView;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.bottom - self.bottomLineHeight, self.width, self.bottomLineHeight)];
        _lineView.backgroundColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0];
    }
    return _lineView;
}

- (void)setBottomLineHeight:(CGFloat)bottomLineHeight
{
    _bottomLineHeight = bottomLineHeight;
    self.lineView.height = bottomLineHeight;
    self.lineView.bottom = self.topBar.height;
}

#pragma mark - public Properties
// PS：下面的颜色和字体一般都是默认颜色，不需要在外边进行改变，也可把下面3个属写成私有属性

- (UIColor *)titleNormalColor
{
    if (!_titleNormalColor) {
        _titleNormalColor = [UIColor blackColor];
    }
    return _titleNormalColor;
}

- (UIColor *)titleSelectedColor
{
    if (!_titleSelectedColor) {
        _titleSelectedColor = [UIColor redColor];
    }
    return _titleSelectedColor;
}

- (UIFont *)titleFont
{
    if (!_titleFont) {
        _titleFont = [UIScreen mainScreen].scale == 3 ? font(16) : font(15);
    }
    return _titleFont;
}

// 重写下面的setter是需要进行在外部改变值的

- (void)setContainerBackgroundColor:(UIColor *)containerBackgroundColor
{
    _containerBackgroundColor = containerBackgroundColor;
    self.containerView.backgroundColor = containerBackgroundColor;
}

- (void)setTopBarHeight:(CGFloat)topBarHeight
{
    _topBarHeight = topBarHeight;
    self.topBar.height = topBarHeight;
}

- (void)setAllowGesture:(BOOL)allowGesture
{
    _allowGesture = allowGesture;
    self.containerView.scrollEnabled = allowGesture;
}

@end


