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

#pragma mark -  上半部分UI属性
//返回按钮
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

//播放按钮
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

#pragma mark -  下半部分UI属性
//播放进度滑块
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

//当前播放时间
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

//总播放时间
@property (weak, nonatomic) IBOutlet UILabel *totalTileLabel;

//音量滑块
@property (strong, nonatomic) UISlider *volumeSlider;

//进度条
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

#pragma mark -  逻辑控制属性属性
//是否显示
@property (nonatomic ,assign) BOOL isShowCoverView;

//是否正在调节音量
@property (nonatomic ,assign) BOOL isVolume;

//是否是直播控制器
//@property (nonatomic ,assign) BOOL isLiveVC;


//@property (nonatomic ,assign)

@end

@implementation LiveControlView

static BOOL isLiveVCType;

+ (instancetype)viewFromXibWith:(BOOL)isLiveVC
{
    isLiveVCType = isLiveVC;
    LiveControlView * controlView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
    return controlView;
}

//-(void)setIsLiveVC:(BOOL)isLiveVC{
//    
//    _isLiveVC = isLiveVC;
//    
//    
//    
//   
//}
#pragma mark -  初始化
-(instancetype)init{
    
    if (self = [super init]) {
        
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    
    [super drawRect:rect];
    
//    [self createUpUI];
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
    
//    NSLog(@"|||||||||||||||||||||||||c%d c||||||||||||||||||||",self.isLiveVC);

    self.backgroundColor = [UIColor clearColor];
    
    //初始化,默认不隐藏,且透明度为1
    [self initialization];
    
    [self createGesture];
    
    [self createUpUI];
   

}
#pragma mark -  UI
-(void)createUpUI{
    
    self.coverView.backgroundColor = [UIColor clearColor];
    

    if (isLiveVCType) {
        //是直播
        self.playSlider.hidden = YES;
        
        self.currentTimeLabel.hidden = YES;
        
        self.totalTileLabel.hidden = YES;
        
        self.progressView.hidden = YES;
        
    } else {
        //是普通的播放器
        
        self.playSlider.hidden = NO;
        
        self.currentTimeLabel.hidden = NO;
        
        self.totalTileLabel.hidden = NO;
        
        self.progressView.hidden = NO;
    }
    
    [self setNeedsDisplay];
}

/**
 隐藏控制器
 */
-(void)hideControl{
    
    if (self.isShowCoverView == NO) {
        return;
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    //渐隐动画
    [UIView animateWithDuration:0.5 animations:^{
        self.coverView.alpha = 0;
    }completion:^(BOOL finished) {
        self.isShowCoverView = NO;
    }];
    
}


/**
 显示控制器
 */
-(void)showControl{
    
    if (self.isShowCoverView == YES) {
        return;
    }
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.coverView.alpha = 1;
    } completion:^(BOOL finished) {
        self.isShowCoverView = YES;
    }];
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
    
    //当双击手势不生效时单点手势才会生效
    [tap requireGestureRecognizerToFail:doubleTap];
    
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
    
    [self showControl];
    
    [self changePlayState];
}



/**
 平移

 @param panGesture <#panGesture description#>
 */
-(void)panAction:(UIPanGestureRecognizer *)panGesture{
    
    //直播功能暂不提供进度拖拽
    
}

#pragma mark -  播放器

/**
 改变播放器状态
 */
-(void)changePlayState{
    
    if ([self.playerDelegate isPlaying] ) {
        [self.playerDelegate pause];
    }else{
        [self.playerDelegate play];
    }
    
    self.playBtn.selected = [self.playerDelegate isPlaying];
}
@end
