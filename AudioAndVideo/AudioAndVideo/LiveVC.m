//
//  LiveVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/9.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "LiveVC.h"

#import "LFLiveSession.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "FYProgressHUD.h"

@interface LiveVC ()<LFLiveSessionDelegate>

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

//来疯直播session
@property (strong, nonatomic)LFLiveSession * session;

/** 灯泡状态,默认为关闭 */
@property (nonatomic) AVCaptureTorchMode torchMode;

@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@end

@implementation LiveVC

#pragma mark -  懒加载
        -(LFLiveSession *)session{
            
            if (nil == _session) {
                /**
                 默认音频质量 audio sample rate: 44MHz(默认44.1Hz iphoneg6以上48Hz), audio bitrate: 64Kbps
                 分辨率： 540 *960 帧数：30 码率：800Kps
                 方向竖屏
                 */
                
                // 视频配置(质量 & 是否是横屏)可以点进去看
                _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:[LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_Medium3 landscape:NO]];
                
                _session.delegate = self;
                _session.showDebugInfo = self;
                _session.preView = self.view;
            }
            return _session;
        }

#pragma mark -  生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置UI
    [self createupUI];
    
    _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //闪光灯
    _torchMode = AVCaptureTorchModeOff;
    
    //开始直播按钮
    @weakify(self);
    [[_startOrStopBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        @strongify(self);
        self.startOrStopBtn.selected = !self.startOrStopBtn.selected;
        
        if (self.startOrStopBtn.isSelected) {
            //开始直播状态
            [self.startOrStopBtn setTitle:@"结束直播" forState:UIControlStateNormal];
            
            LFLiveStreamInfo * sterm = [LFLiveStreamInfo new];
            
            sterm.url = @"rtmp://192.168.1.42:1935/rtmplive/room";
            
            [self.session startLive:sterm];
            
        } else {
            //结束直播状态
            [self.startOrStopBtn setTitle:@"开始直播" forState:UIControlStateNormal];
            
            [self.session stopLive];
        }
    }];
    
    
    //美颜按钮
    [[self.beautifulBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        self.session.beautyFace = !self.session.beautyFace;
        self.beautifulBtn.selected = !self.session.beautyFace;
        
    }];
    
    //前后镜头反转
    [[self.cameraBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        @strongify(self);;
        
        AVCaptureDevicePosition devicePosition = self.session.captureDevicePosition;
        
        self.session.captureDevicePosition = (devicePosition == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    }];
    
    //闪光灯
    [[self.lightBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self.session setTorch:!self.lightBtn.selected];
        self.lightBtn.selected = !self.lightBtn.selected;
    }];
    
    //镜面翻转
    [[self.mirrorBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        @strongify(self);
        [self.session setMirror:!self.mirrorBtn.selected];
        
        self.mirrorBtn.selected = !self.mirrorBtn.selected;
    }];
    
    [self requestAccessForVideo];
    
    [self requestAccessForAudio];
}

#pragma mark -  请求授权

- (void)requestAccessForVideo {
    @weakify(self);
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @strongify(self);
                        [self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self.session setRunning:YES];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}

        -(void)liveSession:(LFLiveSession *)session liveStateDidChange:(LFLiveState)state{
            self.liveStateLabel.textColor = [UIColor blackColor];
            switch (state) {
                case LFLiveReady:
                    NSLog(@"未连接");
                    self.liveStateLabel.text = @"未连接";
                    break;
                case LFLivePending:
                    NSLog(@"连接中");
                    [FYProgressHUD showWithMessage:@"正在连接..."];
                    self.liveStateLabel.text = @"正在连接...";
                    break;
                case LFLiveStart:
                    NSLog(@"已连接");
                    [FYProgressHUD showSuccess:@"连接成功"];
                    self.liveStateLabel.text = @"正在直播";
                    break;
                case LFLiveError:
                    NSLog(@"连接错误");
                    [FYProgressHUD showError:@"连接错误"];
                    self.liveStateLabel.text = @"未连接";
                    break;
                case LFLiveStop:
                    self.liveStateLabel.text = @"未连接";
                    NSLog(@"未连接");
                    break;
                default:
                    break;
            }
        }


#pragma mark -  UI
-(void)createupUI{
    
    self.navigationController.navigationBar.hidden = YES;
    
    //圆角
    _startOrStopBtn.layer.cornerRadius = 10;
    
    _startOrStopBtn.layer.masksToBounds = YES;
    
    [self.startOrStopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    [self.startOrStopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    
    self.view.autoresizingMask = YES;
    
    
}

@end
