//
//  GameViewController.h
//  ChessGame
//
//  Created by songlong on 16/9/14.
//  Copyright © 2016年 Saber. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GameViewController;
#define kItemCount 0

@protocol GameViewControllerDelegate <NSObject>

@optional

- (void)gameViewControllerDidClose:(GameViewController *)controller;
- (void)gameViewController:(GameViewController *)controller localTouchOnItem:(NSInteger)index;

- (void)gameViewController:(GameViewController *)controller localPoint:(NSInteger)point;

@end

@interface GameViewController : UIViewController

@property (nonatomic, weak) id<GameViewControllerDelegate> delegate;

- (void)remoteTouchOnItem:(NSInteger)index;
- (void)resetGame;

- (void)remotePoint:(NSInteger)point;

@end
