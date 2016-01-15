//
//  UIView+Common.h
//  
//
//  Created by silence on 15/9/14.
//
//

#import <UIKit/UIKit.h>

@interface UIView (Common)

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat centerX;

@property (nonatomic ,assign) CGSize size;
@property (nonatomic ,assign) CGPoint origin;

@end
