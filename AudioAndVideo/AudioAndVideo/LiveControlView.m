//
//  LiveControlView.m
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "LiveControlView.h"

@interface  LiveControlView()

//覆盖层
@property (weak, nonatomic) IBOutlet UIView *coverView;

//播放按钮
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

//播放进度滑块
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

//返回按钮
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

//当前播放时间
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

//总播放时间
@property (weak, nonatomic) IBOutlet UILabel *totalTileLabel;

//音量滑块
@property (strong, nonatomic) UISlider *volumeSlider;

//进度条
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

//是否显示
@property (nonatomic ,assign) BOOL isShowCoverView;

//是否正在调节音量
@property (nonatomic ,assign) BOOL isVolume;

//@property (nonatomic ,assign)

@end

@implementation LiveControlView
#pragma mark -  初始化
-(instancetype)init{
    
    if (self = [super init]) {
        
    }
    return self;
}

/**
 初始化控制页面,并设置透明度
 */
-(void)initialization{

    self.alpha = 1.0;
    
    self.isShowCoverView = YES;
}


-(void)awakeFromNib{
    
    [super awakeFromNib];
    
    //初始化,默认不隐藏,且透明度为1
    [self initialization];
    
    
}
#pragma mark -  UI
-(void)createUpUI{
    
    
}

/**
 隐藏控制器
 */
-(void)hideControl{
    
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade]
    
    
}


/**
 显示控制器
 */
-(void)showControl{
    
}

#pragma mark -  手势以及手势方法
/**
 创建手势
 */
-(void)createGesture{
    
    //单击(显示控制器)
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapaction:)];
    [self addGestureRecognizer:tap];
    
    //双击(播放暂停)
    UITapGestureRecognizer * doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    
    //平移(快进,音量,亮度)
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:pan];
}

/**
 单击

 @param tapGesture <#tapGesture description#>
 */
-(void)tapaction:(UITapGestureRecognizer *)tapGesture{
    
    if (tapGesture.state == UIGestureRecognizerStateRecognized) {
        self.isShowCoverView?[self hideControl]:[self showControl];
    }
    
}


/**
 双击

 @param doubleTapGesture <#doubleTapGesture description#>
 */
-(void)doubleTapAction:(UITapGestureRecognizer *)doubleTapGesture{
    
}

/**
 平移

 @param panGesture <#panGesture description#>
 */
-(void)panAction:(UIPanGestureRecognizer *)panGesture{
    
}
@end
