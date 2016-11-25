//
//  VideoEncodeVC.m
//  AudioAndVideo
//
//  Created by fy on 2016/11/24.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "VideoEncodeVC.h"

#import <AVFoundation/AVFoundation.h>

@interface VideoEncodeVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation VideoEncodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
   //开始获取数据
    [self startGetData];
    
    //开始编码
    [self encode];
}


/**
 开始获取数据
 */
-(void)startGetData{
    
    //创建后置摄像头
    AVCaptureDevice * avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //打开摄像头
    NSError * error = nil;
    
    //创建输入设备
    AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice:avCaptureDevice error:&error];
    
    //创建失败
    if (!videoInput) {
        
        NSLog(@"%@",error);
        
        return;
    }
    
    //创建会话,将输入输出结合在一起,并可以开始自动捕获设备
    AVCaptureSession *avCaptureSession = [[AVCaptureSession alloc]init];
    
    //设置采集质量
    avCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;//默认就为高
    
    //添加输入流
    [avCaptureSession addInput:videoInput];
    
    //采集数据从视频
    AVCaptureVideoDataOutput * avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
    //设置参数
    NSDictionary * settings = @{(__bridge id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    
    avCaptureVideoDataOutput.videoSettings = settings;
    
    //创建队列
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    
    //设置代理和队列
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    //会话添加输出
    [avCaptureSession addOutput:avCaptureVideoDataOutput];
    
    //添加预览界面
    AVCaptureVideoPreviewLayer * previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:avCaptureSession];
    
    previewLayer.frame = self.view.frame;
    
    //保留纵横比
    previewLayer.videoGravity = AVVideoScalingModeResizeAspectFill;
    
    [self.view.layer addSublayer:previewLayer];
    
    [avCaptureSession startRunning];

}



/**
 编码
 */
-(void)encode{
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}

#pragma mark -  delegate
static int i = 0;
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

}
@end
