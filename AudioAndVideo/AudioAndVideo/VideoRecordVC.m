//
//  VideoRecordVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "VideoRecordVC.h"

//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND

//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS

#import "Masonry.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#import <AVFoundation/AVFoundation.h>

#import "NSString+path.h"

@interface VideoRecordVC ()<AVCaptureFileOutputRecordingDelegate>

//摄像头输入
@property (strong, nonatomic)   AVCaptureInput  *cameraInput;

//麦克风输入
@property (strong, nonatomic)   AVCaptureInput  *audioInput;

//输出
@property (strong, nonatomic)   AVCaptureMovieFileOutput    *output;

//定义会话
@property (strong, nonatomic)   AVCaptureSession        *session;

//定义预览界面
@property (strong, nonatomic)   AVCaptureVideoPreviewLayer  *previewLayer;

@end

@implementation VideoRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self createRecord];
    
    [self createUpUI];
    
}

-(void)dealloc{
    
    NSLog(@"已销毁");
    
    [self.output stopRecording];
}
#pragma mark -  创建录制
-(void)createRecord{
    
    //输入（摄像头，麦克风）
    //摄像头输入
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:nil];
    
    //麦克风输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    //输出
    self.output = [AVCaptureMovieFileOutput new];
    
    //创建关联会话
    self.session = [AVCaptureSession new];
    
    //关联输入输出
    if([self.session canAddInput:self.cameraInput]) {
        [self.session addInput:self.cameraInput];
    }
    if([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    if([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    
    //通过会话设置预览
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    self.previewLayer.frame = self.view.frame;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    //开启会话
    [self.session startRunning];
}

#pragma mark -  UI
-(void)createUpUI{
    
    UIButton * startBtn = [[UIButton alloc]init];
    
    @weakify(self);
    //开始/继续录像
    [[startBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/test1.mov"];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        @strongify(self);
        [self.output startRecordingToOutputFileURL:url recordingDelegate:self];
        
    }];
    
    UIButton * pauseBtn = [[UIButton alloc]init];
    
    //暂停录像
    [[pauseBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        @strongify(self);
        [self.output stopRecording];
        
    }];
    [startBtn setTitle:@"开始录像" forState:UIControlStateNormal];
    
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [pauseBtn setTitle:@"暂停录像" forState:UIControlStateNormal];
    
    [pauseBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    
    [self.view addSubview:startBtn];
    
    [self.view addSubview:pauseBtn];
    
    
    [pauseBtn makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.centerX);
        
        make.bottom.equalTo(self.view.bottom).equalTo(-20);
    }];
    
    [startBtn makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(self.view.centerX);
        
        make.bottom.equalTo(pauseBtn.top).offset(-20);
    }];
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"录制完成");
}


@end
