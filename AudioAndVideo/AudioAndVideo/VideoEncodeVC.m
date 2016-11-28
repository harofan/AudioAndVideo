//
//  VideoEncodeVC.m
//  AudioAndVideo
//
//  Created by fy on 2016/11/24.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "VideoEncodeVC.h"

#import <AVFoundation/AVFoundation.h>

@interface VideoEncodeVC ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

//前摄像头输入
@property(nonatomic,strong)AVCaptureDeviceInput *frontCamera;

//后摄像头输入
@property(nonatomic,strong)AVCaptureDeviceInput *backCamera;

//当前使用的视频设备
@property(nonatomic,weak)AVCaptureDeviceInput *videoInputDevice;

//音频设备输入
@property(nonatomic,strong)AVCaptureDeviceInput *audioInputDevice;

//输出数据接收
@property(nonatomic,strong)AVCaptureVideoDataOutput *videoDataOutput;
@property(nonatomic,strong)AVCaptureAudioDataOutput *audioDataOutput;

//会话
@property(nonatomic,strong)AVCaptureSession *captureSession;

//预览
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;












@end

@implementation VideoEncodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    

}


#pragma mark -  采集
/**
 开始采集
 */
-(void)startCollectData{
    
    //创建音视频输入
    [self createCaptureDevice];
    
    //创建输出
    [self createOutput];
    
    //创建会话
    [self createCaptureSession];
    
    //创建预览
    [self createPreviewLayer];
    
    //开始会话
    [self.captureSession startRunning];
}


/**
 创建音视频输入
 */
-(void)createCaptureDevice{
    
    //创建摄像头
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //初始化摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    //设置当前视频输入设备
    self.videoInputDevice = self.backCamera;
}


/**
 创建输出
 */
-(void)createOutput{
    
    //创建队列
    dispatch_queue_t queue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL);
    
    //创建视频输出数据
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
    //设置代理和队列
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    
    //默认为是,是否丢弃以前的帧
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    //设置参数
    NSDictionary * settings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.videoDataOutput.videoSettings = settings;
    
    //创建音频输出数据
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc]init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:queue];
}


/**
 创建会话
 */
-(void)createCaptureSession{
    
    self.captureSession = [[AVCaptureSession alloc]init];
    
    [self.captureSession beginConfiguration];
    
    //添加视频输入
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    //添加音频输入
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    //添加视频输出
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
//        [self setVideoOutConfig];
    }
    
    //添加音频输出
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    //设置采集质量
//    if (![self.captureSession canSetSessionPreset:self.captureSessionPreset]) {
//        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.captureSessionPreset] userInfo:nil];
//    }
    
    //设置采集质量
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;//默认就为高
    
    [self.captureSession commitConfiguration];

}


/**
 创建预览
 */
-(void)createPreviewLayer{
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    self.previewLayer.frame = self.view.frame;
    
    //保留纵横比
    self.previewLayer.videoGravity = AVVideoScalingModeResizeAspectFill;
    
    [self.view.layer addSublayer:self.previewLayer];
    
}

-(void) setVideoOutConfig{
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

#pragma mark -  delegate
static int i = 0;
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

}
@end
