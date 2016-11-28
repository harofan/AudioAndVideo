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
    
    //抛弃过期帧，保证实时性
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
    
    //设置预览分辨率
    //这个分辨率有一个值得注意的点：
    //iphone4录制视频时 前置摄像头只能支持 480*640 后置摄像头不支持 540*960 但是支持 720*1280
    //诸如此类的限制，所以需要写一些对分辨率进行管理的代码。
    //目前的处理是，对于不支持的分辨率会抛出一个异常
    //但是这样做是不够、不完整的，最好的方案是，根据设备，提供不同的分辨率。
    //如果必须要用一个不支持的分辨率，那么需要根据需求对数据和预览进行裁剪，缩放。
    //设置采集质量
//    if (![self.captureSession canSetSessionPreset:self.captureSessionPreset]) {
//        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.captureSessionPreset] userInfo:nil];
//    }
    
    //设置采集质量
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;//默认就为高
    
    //提交配置变更
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


/**
 设置FPS

 @param fps <#fps description#>
 */
-(void) updateFps:(NSInteger) fps{
    //获取当前capture设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //遍历所有设备（前后摄像头）
    for (AVCaptureDevice *vDevice in videoDevices) {
        //获取当前支持的最大fps
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        //如果想要设置的fps小于或等于做大fps，就进行修改
        if (maxRate >= fps) {
            //实际修改fps的代码
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}


/**
 切换摄像头

 @param videoInputDevice <#videoInputDevice description#>
 */
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice{
    if ([videoInputDevice isEqual:_videoInputDevice]) {
        return;
    }
    //captureSession 修改配置
    [self.captureSession beginConfiguration];
    //移除当前输入设备
    if (_videoInputDevice) {
        [self.captureSession removeInput:_videoInputDevice];
    }
    //增加新的输入设备
    if (videoInputDevice) {
        [self.captureSession addInput:videoInputDevice];
    }
    
    //提交配置，至此前后摄像头切换完毕
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

#pragma mark -  delegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

   
        if ([self.videoDataOutput isEqual:captureOutput]) {
            //捕获到视频数据，通过sendVideoSampleBuffer发送出去，后续文章会解释接下来的详细流程。
//            [self sendVideoSampleBuffer:sampleBuffer];
        }else if([self.audioDataOutput isEqual:captureOutput]){
            //捕获到音频数据，通过sendVideoSampleBuffer发送出去
//            [self sendAudioSampleBuffer:sampleBuffer];
        }
    
}
@end
