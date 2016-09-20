//
//  IJKLiveVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "IJKLiveVC.h"

#import <IJKMediaFramework/IJKMediaFramework.h>

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "LiveControlView.h"

#define screenSize [UIScreen mainScreen].bounds.size


@interface IJKLiveVC ()

@property(atomic,strong)id <IJKMediaPlayback> player;

@end

@implementation IJKLiveVC

#pragma mark - 屏幕旋转
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate{
    
    return YES;
    
}
#pragma mark - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    //隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    //配置播放器
    [self setupPlayer];
    
}


-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    //准备播放
    [self.player prepareToPlay];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    //释放掉播放器
    [self.player stop];
    
    [self.player shutdown];
}

#pragma mark - 配置播放器
-(void)setupPlayer{
    
    // 检查当前FFmpeg版本是否匹配
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    
    // IJKFFOptions 是对视频的配置信息
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
    //是否要展示配置信息指示器(默认为NO)
    options.showHudView = NO;
    
    //创建播放器,配置
    self.player = [[IJKFFMoviePlayerController alloc]initWithContentURL:[NSURL URLWithString:self.url] withOptions:options];
    
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //创建控制页面,同时确定控制页面类型
    LiveControlView * liveControlView = [LiveControlView viewFromXibWith:self.isLiveVC];

    liveControlView.playerDelegate = self.player;
    
    CGFloat width = MAX(screenSize.width, screenSize.height);
    
    CGFloat height = MIN(screenSize.width, screenSize.height);
    
    //判断横竖屏
    if (screenSize.width>400) {
        
        //横屏
        self.player.view.frame = CGRectMake(0, 0, width, height);
        
    } else {
        //竖屏
        self.player.view.frame = CGRectMake(0, 0, screenSize.width, 300);
    }
    liveControlView.frame = self.player.view.bounds;
    
    //监听屏幕翻转通知
    [[[NSNotificationCenter defaultCenter]rac_addObserverForName:UIDeviceOrientationDidChangeNotification object:nil] subscribeNext:^(id x) {
        
        if (screenSize.width>400) {
            
            //横屏
            self.player.view.frame = CGRectMake(0, 0, width, height);
            
        } else {
            //竖屏
            self.player.view.frame = CGRectMake(0, 0, screenSize.width, 300);
        }
        
        liveControlView.frame = self.player.view.bounds;
        
        [self.player.view setNeedsDisplay];
        
        [liveControlView setNeedsDisplay];
        
        [self.player play];
    }];
    
    //ijkplaeyer缩放模式
    self.player.scalingMode = IJKMPMovieScalingModeFill;
    
    //打开自动播放
    self.player.shouldAutoplay = YES;
    
    //播放器背景颜色
    self.player.view.backgroundColor = [UIColor whiteColor];
    
    self.view.autoresizesSubviews = YES;
    
    [self.view addSubview:self.player.view];
    
    [self.view addSubview:liveControlView];
    
    [self.player play];
}
@end
