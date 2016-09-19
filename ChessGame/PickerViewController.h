//
//  PickerViewController.h
//  ChessGame
//
//  Created by songlong on 16/9/14.
//  Copyright © 2016年 Saber. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PickerViewController;

@protocol PickerDelegate <NSObject>

@optional

- (void)pickerViewController:(PickerViewController *)controller connectToService:(NSNetService *)service;
- (void)pickerViewControllerDidCancelConnect:(PickerViewController *)controller;

@end

@interface PickerViewController : UIViewController

@property (nonatomic, weak) id<PickerDelegate> delegate;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) NSNetService *localService;

- (void)cancelConnect;
- (void)start;
- (void)stop;

@end
