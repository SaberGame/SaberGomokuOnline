//
//  GameViewController.m
//  ChessGame
//
//  Created by songlong on 16/9/14.
//  Copyright © 2016年 Saber. All rights reserved.
//

#import "GameViewController.h"

@interface GameViewController ()

@property (nonatomic, assign) BOOL isX;
@property (nonatomic, strong) UIView *selectView;
@property (nonatomic, strong) UILabel *myPointLabel;
@property (nonatomic, strong) UILabel *otherPointLabel;
@property (nonatomic, strong) UILabel *turnLabel;
@property (nonatomic, strong) UIView *gameView;
@property (nonatomic, strong) UIButton *popButton;
@property (nonatomic, strong) UILabel *compareLabel;

@property (nonatomic, assign) NSInteger myPoint;
@property (nonatomic, assign) NSInteger otherPoint;

@property (nonatomic, strong) NSMutableArray *xArray;
@property (nonatomic, strong) NSMutableArray *oArray;

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupGame];
    
}

- (void)setupGame {
    _xArray = [NSMutableArray array];
    _oArray = [NSMutableArray array];
    
    _selectView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _selectView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_selectView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, [UIScreen mainScreen].bounds.size.width - 100, 30)];
    label.font = [UIFont systemFontOfSize:25];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"比大小";
    self.compareLabel = label;
    [_selectView addSubview:label];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 100) / 2, 150, 100, 100)];

    self.popButton = button;
    [button addTarget:self action:@selector(clickPoint) forControlEvents:UIControlEventTouchUpInside];
//    button.backgroundColor = [UIColor blueColor];
    [button setBackgroundImage:[UIImage imageNamed:@"dice"] forState:UIControlStateNormal];
    [_selectView addSubview:button];
    
    _myPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, 30)];
    _myPointLabel.textAlignment = NSTextAlignmentCenter;
    [_selectView addSubview:_myPointLabel];
    
    _otherPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 350, [UIScreen mainScreen].bounds.size.width, 30)];
    _otherPointLabel.textAlignment = NSTextAlignmentCenter;
    [_selectView addSubview:_otherPointLabel];
}

- (void)remotePoint:(NSInteger)point {
    self.otherPoint = point;
    _otherPointLabel.text = [NSString stringWithFormat:@"对方点数：%zd", self.otherPoint];
    [self checkPoints];
}

- (void)clickPoint {
    
    self.myPoint = arc4random() % 10 + 1;
    _myPointLabel.text = [NSString stringWithFormat:@"我的点数：%zd",self.myPoint];
    if ([self.delegate respondsToSelector:@selector(gameViewController:localPoint:)]) {
        [self.delegate gameViewController:self localPoint:self.myPoint];
    }
    [self checkPoints];
    self.popButton.userInteractionEnabled = NO;
}

- (void)checkPoints {
    __weak typeof(self) weakself = self;
    if (self.myPoint > 0 && self.otherPoint > 0 && self.otherPoint != self.myPoint) {
        
        if (self.myPoint > self.otherPoint) {
            self.compareLabel.text = @"恭喜获得先手";
        } else if (self.myPoint < self.otherPoint) {
            self.compareLabel.text = @"很遗憾获得后手";
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself.selectView removeFromSuperview];
            [weakself initGame];
            
        });
    }
    
    if (self.myPoint == self.otherPoint) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakself.myPointLabel.text = @"点数相同重新roll";
            weakself.otherPointLabel.text = nil;
            weakself.myPoint = 0;
            weakself.otherPoint = 0;
            weakself.popButton.userInteractionEnabled = YES;
        });
    }
}

- (void)initGame {
    self.view.backgroundColor = [UIColor yellowColor];
    
    UIView *gameView = [[UIView alloc] initWithFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width) / 2, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    self.gameView = gameView;
    [self.view addSubview:gameView];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width / 15;
    
    for (int i = 0; i < 15; i++) {
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(width / 2 + i * width, width / 2, 1, [UIScreen mainScreen].bounds.size.width - width)];
        lineView.backgroundColor = [UIColor blackColor];
        [gameView addSubview:lineView];
        
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(width / 2, width / 2 + i * width, [UIScreen mainScreen].bounds.size.width - width, 1)];
        rowView.backgroundColor = [UIColor blackColor];
        [gameView addSubview:rowView];
    }
    
    for (int i = 0; i < 225; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(width * (i % 15), width * (i / 15), width, width)];
//        [button setBackgroundImage:[UIImage imageNamed:@"b0"] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor clearColor];
        button.tag = i + 1;
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [gameView addSubview:button];
    }
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"cross24"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(clickClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    
    self.turnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, [UIScreen mainScreen].bounds.size.width, 30)];
    _turnLabel.textColor = [UIColor blueColor];
    _turnLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_turnLabel];;
    if (self.myPoint > self.otherPoint) {
        _turnLabel.text = @"我的回合";
        _turnLabel.textColor = [UIColor redColor];
        self.gameView.userInteractionEnabled = YES;
    } else if (self.myPoint < self.otherPoint) {
        _turnLabel.text = @"对手回合";
        _turnLabel.textColor = [UIColor blackColor];
        self.gameView.userInteractionEnabled = NO;
    }
}

- (void)clickClose {
    __weak typeof(self) weakself = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确定退出？" message:@"对方玩家也会断开连接" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([weakself.delegate respondsToSelector:@selector(gameViewControllerDidClose:)]) {
            [weakself.delegate gameViewControllerDidClose:self];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)remoteTouchOnItem:(NSInteger)index {
    UIButton *button = [self.view viewWithTag:index + 1];
    button.userInteractionEnabled = NO;
    self.gameView.userInteractionEnabled = YES;
    [button setBackgroundImage:[UIImage imageNamed:@"stone_white"] forState:normal];
    _turnLabel.text = @"我的回合";
    _turnLabel.textColor = [UIColor redColor];
    [_oArray addObject:@(button.tag)];
    [self whiteWinCheck];
}

- (void)clickButton:(UIButton *)button {
    
    
    if ([self.delegate respondsToSelector:@selector(gameViewController:localTouchOnItem:)]) {
        [self.delegate gameViewController:self localTouchOnItem:button.tag - 1];
    }
    
    button.userInteractionEnabled = NO;
    self.gameView.userInteractionEnabled = NO;

   [button setBackgroundImage:[UIImage imageNamed:@"stone_black"] forState:UIControlStateNormal];
    _turnLabel.text = @"对手回合";
    _turnLabel.textColor = [UIColor blackColor];
    [_xArray addObject:@(button.tag)];
    [self blackWinCheck];
}

- (void)resetGame {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    self.myPoint = 0;
    self.otherPoint = 0;
    [self setupGame];
}

- (void)blackWinCheck {
    if ([self winArray:self.xArray]) {
        _turnLabel.text = @"游戏结束，恭喜获胜";
        _turnLabel.textColor = [UIColor redColor];
        self.gameView.userInteractionEnabled = NO;
    }
}

- (void)whiteWinCheck {
    if ([self winArray:self.oArray]) {
        _turnLabel.text = @"游戏结束，你输了";
        _turnLabel.textColor = [UIColor redColor];
        self.gameView.userInteractionEnabled = NO;
    }
}

- (BOOL)winArray:(NSMutableArray *)arr {
    for (NSNumber *num in arr) {
        bool c1 = [arr containsObject:num] && [arr containsObject:@(num.integerValue + 1)] && [arr containsObject:@(num.integerValue + 2)] && [arr containsObject:@(num.integerValue + 3)] && [arr containsObject:@(num.integerValue + 4)];
        
        bool c2 = [arr containsObject:num] && [arr containsObject:@(num.integerValue + 15)] && [arr containsObject:@(num.integerValue + 30)] && [arr containsObject:@(num.integerValue + 45)] && [arr containsObject:@(num.integerValue + 60)];
        
        bool c3 = [arr containsObject:num] && [arr containsObject:@(num.integerValue + 14)] && [arr containsObject:@(num.integerValue + 14 * 2)] && [arr containsObject:@(num.integerValue + 14 * 3)] && [arr containsObject:@(num.integerValue + 14 * 4)];
        
        bool c4 = [arr containsObject:num] && [arr containsObject:@(num.integerValue + 16)] && [arr containsObject:@(num.integerValue + 16 * 2)] && [arr containsObject:@(num.integerValue + 16 * 3)] && [arr containsObject:@(num.integerValue + 16 * 4)];
        
        if (c1 || c2 || c3 || c4) {
            return YES;
        }
    }
    
    return NO;
}

@end
