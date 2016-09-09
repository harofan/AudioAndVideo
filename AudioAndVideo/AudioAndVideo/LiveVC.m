//
//  LiveVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/9.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "LiveVC.h"

@interface LiveVC ()

//美颜按钮开关
@property (weak, nonatomic) IBOutlet UIButton *beautifulBtn;

//前后置摄像头反转
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;

//闪光灯
@property (weak, nonatomic) IBOutlet UIButton *lightBtn;

//反转按钮
@property (weak, nonatomic) IBOutlet UIButton *mirrorBtn;

//直播状态
@property (weak, nonatomic) IBOutlet UILabel *liveStateLabel;

//开始或结束直播按钮
@property (weak, nonatomic) IBOutlet UIButton *startOrStopBtn;

@end

@implementation LiveVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationController.navigationBar.hidden = YES;
}



@end
