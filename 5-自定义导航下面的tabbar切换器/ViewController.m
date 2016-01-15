//
//  ViewController.m
//  5-自定义导航下面的tabbar切换器
//
//  Created by silence on 15/10/19.
//  Copyright © 2015年 silence. All rights reserved.
//

#import "ViewController.h"
#import "LDSegmentContainer.h"
#import "UIView+Common.h"

@interface ViewController () <LDSegmentContainerDelegate>
@property (nonatomic, strong) LDSegmentContainer *segmentContainer;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.view addSubview:self.segmentContainer];
    
    
}


#pragma mark - LDSegmentContainerDelegate
- (NSUInteger)numberOfItemsInSegmentContainer:(LDSegmentContainer *)segmentContainer
{
    return 20;
}

- (NSString *)segmentContainer:(LDSegmentContainer *)segmentContainer titleForItemAtIndex:(NSUInteger)index
{
    if (index == 0) {
        return @"帅锅帅锅帅锅";
    } else if (index == 1) {
        return @"傻逼";
    } else if (index == 2) {
        return @"孙铁哈哈哈";
    } else if (index == 3) {
        return @"周云";
    } else {
        return @"余亮";
    }
}

- (id)segmentContainer:(LDSegmentContainer *)segmentContainer contentForIndex:(NSUInteger)index
{
    if (index % 2 == 0) {
        UIViewController *vc = [[UIViewController alloc] init];
        return vc;
    } else {
        UITableViewController *tableVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        tableVC.tableView.backgroundColor = [UIColor colorWithRed:arc4random() % 256 / 255.0 green:arc4random() % 255 / 255.0 blue:arc4random() % 256 / 255.0 alpha:0.6];
        return tableVC;
    }
}


- (LDSegmentContainer *)segmentContainer
{
    if (!_segmentContainer) {
        _segmentContainer = [[LDSegmentContainer alloc] initWithFrame:CGRectMake(0, 64, self.view.width, self.view.height - 64)];
        _segmentContainer.parentVC = self;
        _segmentContainer.delegate = self;
    }
    return _segmentContainer;
}


@end
