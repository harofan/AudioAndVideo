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

#pragma mark -  中间区域
//播放按钮
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

/** 定义一个实例变量，保存滑动方向枚举值 */
@property (nonatomic, assign) PanDirection panDirection;

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

//计时器
@property (nonatomic ,strong)NSTimer * timer;

//拖动开始时间
@property (nonatomic ,assign)NSTimeInterval  beginTime;

//拖动总时间
@property (nonatomic ,assign)NSTimeInterval  sumTime;
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

#pragma mark -  初始化

/**
 初始化控制页面,并设置透明度
 */
-(void)initialization{

    self.alpha = 1.0;
    
    self.isShowCoverView = YES;
    
}


-(void)awakeFromNib{
    
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    
    //初始化,默认不隐藏,且透明度为1
    [self initialization];
    
    [self createGesture];
    
    [self createUpUI];
   
    [self configVolume];
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
    //获取现在位置
    CGPoint locationPoint = [panGesture locationInView:panGesture.view];
    
    //算出一个移动后的point
    CGPoint velocityPoint = [panGesture velocityInView:panGesture.view];
    
    switch (panGesture.state) {
        //手势开始
        case UIGestureRecognizerStateBegan:
        {
            //使用绝对值来判断移动的方向
            CGFloat x = fabs(velocityPoint.x);
            CGFloat y = fabs(velocityPoint.y);
            
            //横向移动(进度条)
            if (x>y) {
                
                //记录横向移动状态
                _panDirection = PanDirectionHorizontalMoved;
                
                //暂停计时
                [self.timer setFireDate:[NSDate distantFuture]];
                
                //获取拖拽开始时间
                _beginTime = [_playerDelegate currentPlaybackTime];
                _sumTime = _beginTime;
                
            }else if(x<y){
            //纵向移动(亮度和音量)
                
                //记录纵向移动状态
                _panDirection = PanDirectionVerticalMoved;
                
                if (locationPoint.x>self.frame.size.width/2) {
                    //声音
                    self.isVolume = YES;
                    
                } else {
                    //亮度
                    self.isVolume = NO;
                }
            }
        }
            break;
        //手势改变
        case UIGestureRecognizerStateChanged:
        {
            
            switch (_panDirection) {
                case PanDirectionVerticalMoved:
                {
                    //纵向移动
                    [self panOnVertical:velocityPoint.x];
                    
                }
                    break;
                case PanDirectionHorizontalMoved:
                {
                    //横向移动
                    [self panOnHorizontal:velocityPoint.y];
                    
                }
                    break;
                default:
                    break;
            }
            
        }
            break;
        //手势结束
        case UIGestureRecognizerStateEnded:
        {
            switch (_panDirection) {
                case PanDirectionHorizontalMoved:
                {
                    //开启定时器
                    [_timer setFireDate:[NSDate date]];
                    
                    //视频跳转
                    [_playerDelegate setCurrentPlaybackTime:_sumTime];
                    
                    //清零否则会累加
                    _sumTime = 0;
                    
                }
                    break;
                    
                case PanDirectionVerticalMoved:
                {
                    
                    _isVolume = NO;
                    
                    
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            

            
        default:
            break;
    }
    
}

-(void)panOnVertical:(CGFloat)value{
    
    
    _isVolume?(_volumeSlider.value += value/5000):([UIScreen mainScreen].brightness-=value/10000);
    
}

-(void)panOnHorizontal:(CGFloat)value{
    
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

#pragma mark -  音量和亮度
-(void)configVolume{
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeSlider = (UISlider *)view;
            break;
        }
    }
}
@end
