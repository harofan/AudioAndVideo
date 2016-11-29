//
//  GPUImageVC.m
//  AudioAndVideo
//
//  Created by fy on 2016/11/28.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "GPUImageVC.h"

#import "GPUImage.h"

#import "GPUImageBeautifyFilter.h"

#import "AWGPUImageVideoCamera.h"

#import "libyuv.h"


//GPUImage data handler
@interface AWGPUImageAVCaptureDataHandler : GPUImageRawDataOutput< AWGPUImageVideoCameraDelegate>

@end

@implementation AWGPUImageAVCaptureDataHandler

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat
{
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
       
    }
    return self;
}

// 获取到音频数据，通过sendAudioSampleBuffer发送出去
-(void)processAudioSample:(CMSampleBufferRef)sampleBuffer{

}


// 获取到视频数据，转换格式后，使用sendVideoYuvData 发送出去。
-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];

    
    // GPUImage获取到的数据是BGRA格式。
    // 而各种编码器最适合编码的格式还是yuv（NV12格式）。
    // 所以在此将BGRA格式的视频数据转成yuv格式。(后面会介绍yuv和pcm格式)
    
    //将bgra转为yuv
    //图像宽度
    int width = imageSize.width;
    //图像高度
    int height = imageSize.height;
    //宽*高
    int w_x_h = width * height;
    //yuv数据长度 = (宽 * 高) * 3 / 2
    int yuv_len = w_x_h * 3 / 2;
    
    //yuv数据
    uint8_t *yuv_bytes = malloc(yuv_len);
    
    //使用libyuv库，做格式转换。libyuv中的格式都是大端(高位存高位，低位存低位)，而iOS设备是小端(高位存低位，低位存高位)，小端为BGRA，则大端为ARGB，所以这里使用ARGBToNV12。
    //self.rawBytesForImage就是美颜后的图片数据，格式是BGRA。
    //关于大端小端，请自行baidu。
    //NV12格式介绍请看下一篇文章：[1小时学会：最简单的iOS直播推流（五）yuv、pcm数据的介绍和获取](http://www.jianshu.com/p/d5489a8fe2a9)
    
    //ARGBToNV12这个函数是libyuv这个第三方库提供的一个将bgra图片转为yuv420格式的一个函数。
    //libyuv是google提供的高性能的图片转码操作。支持大量关于图片的各种高效操作，是视频推流不可缺少的重要组件，你值得拥有。
    [self lockFramebufferForReading];
    ARGBToNV12(self.rawBytesForImage, width * 4, yuv_bytes, width, yuv_bytes + w_x_h, width, width, height);
    [self unlockFramebufferAfterReading];
    
    //yuv数据
    NSData *yuvData = [NSData dataWithBytesNoCopy:yuv_bytes length:yuv_len];
    

}

@end


#pragma mark -  GPUImageVC
@interface GPUImageVC ()

//摄像头
@property(nonatomic,strong)AWGPUImageVideoCamera * videoCamera;

@property(nonatomic,strong)GPUImageView *gpuImageView;

@property(nonatomic,strong)GPUImageBeautifyFilter *beautifyFilter;

@property (nonatomic, strong) AWGPUImageAVCaptureDataHandler *dataHandler;

@end

@implementation GPUImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self onInit];
}

-(void)onInit{
    //摄像头初始化
    // AWGPUImageVideoCamera 继承自 GPUImageVideoCamera。继承是为了获取音频数据，原代码中，默认情况下音频数据发送给了 audioEncodingTarget。
    // 这个东西一看类型是GPUImageMovieWriter，应该是文件写入功能。果断覆盖掉processAudioSampleBuffer方法，拿到音频数据后自己处理。
    // 音频就这样可以了，GPUImage主要工作还是在视频处理这里。
    // 设置预览分辨率 self.captureSessionPreset是根据AWVideoConfig的设置，获取的分辨率。设置前置、后置摄像头。
    _videoCamera = [[AWGPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    
    //开启捕获声音
    [_videoCamera addAudioInputsAndOutputs];
    
    //设置输出图像方向，可用于横屏推流。
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    //镜像策略，这里这样设置是最自然的。跟系统相机默认一样。
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    //设置预览view
    _gpuImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_gpuImageView];
    
    //初始化美颜滤镜
    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    
    //相机获取视频数据输出至美颜滤镜
    [_videoCamera addTarget:_beautifyFilter];
    
    //美颜后输出至预览
    [_beautifyFilter addTarget:_gpuImageView];
    
    // 到这里我们已经能够打开相机并预览了。
    // 因为要推流，除了预览之外，我们还要截取到视频数据。这就需要使用GPUImage中的GPUImageRawDataOutput，它能将美颜后的数据输出，便于我们处理后发送出去。
    // AWGPUImageAVCaptureDataHandler继承自GPUImageRawDataOutput，从 newFrameReadyAtTime 方法中就可以获取到美颜后输出的数据。
    // 输出的图片格式为BGRA。
    _dataHandler = [[AWGPUImageAVCaptureDataHandler alloc]initWithImageSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height) resultsInBGRAFormat:YES ];
    [_beautifyFilter addTarget:_dataHandler];
    
    // 令AWGPUImageAVCaptureDataHandler实现AWGPUImageVideoCameraDelegate协议，并且让camera的awAudioDelegate指向_dataHandler对象。
    // 将音频数据转到_dataHandler中处理。然后音视频数据就可以都在_dataHandler中处理了。
    _videoCamera.awAudioDelegate = _dataHandler;
    
    //开始捕获视频
    [self.videoCamera startCameraCapture];
    
    //修改帧率
//    [self updateFps:self.videoConfig.fps];
}

@end
