//
//  VideoEncodeVC.m
//  AudioAndVideo
//
//  Created by fy on 2016/11/24.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "VideoEncodeVC.h"

#import <AVFoundation/AVFoundation.h>

#import <VideoToolbox/VideoToolbox.h>

#import "AACEncode.h" //苹果自带的



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

//AAC编码工具类
@property(nonatomic,strong) AACEncode * aacEncode;


////输出视频流
//@property(nonatomic,strong)AVCaptureConnection * videoConnection;
//
////输出音频流
//@property(nonatomic,strong)AVCaptureConnection * audioConnection;
@end

@implementation VideoEncodeVC
{
    //编码队列
    dispatch_queue_t _encodeQueue;
    
    //帧编号
    int _frameID;
    
    //编码回话
    VTCompressionSessionRef _encodeingSession;
    
    //视频文件
    NSFileHandle * _fileHandle;
    
    //音频文件
    NSFileHandle * _audioFileHandle;
    
    //是否开始了硬编码
    BOOL _isStartHardEncoding;
}

#pragma mark -  生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self doInit];
    
    //开始采集
    [self startCollectData];
}

-(void)dealloc{
    
    [self destroyCaptureSession];
    
    NSLog(@"销毁了");
    
}

#pragma mark -  初始化
-(void)doInit{
    
    //创建编码队列
    _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //创建音频编码工具类
    self.aacEncode = [[AACEncode alloc]init];
    
    //默认没有开始硬编码
    _isStartHardEncoding = 0;
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
    
    //初始化VideoToolBox硬编码
    [self initVideoToolBox];
    
    //管理文件写入
    [self createFileHandle];
    
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
 管理文件写入
 */
-(void)createFileHandle{
    // 视频编码保存的路径
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.h264"];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]; // 移除旧文件
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
    
    //音频编码保存的路径
    NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.aac"];
    [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
    [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
    _audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
}


/**
 关闭文件写入
 */
-(void)closeFileHandle{
    
    //视频文件
    [_fileHandle closeFile];
    _fileHandle = NULL;
    
    [_audioFileHandle closeFile];
    _audioFileHandle = NULL;
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
    
    //视频防抖
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


/**
 销毁
 */
-(void) destroyCaptureSession{
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    if (_isStartHardEncoding) {
        
        //结束硬编码
        [self stopHardCoding];
        _isStartHardEncoding = 0;
    }
    
}


#pragma mark -  delegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

        if ([self.videoDataOutput isEqual:captureOutput]) {
            //捕获到视频数据
            NSLog(@"视频");
            
            //将视频数据转换成YUV420数据
//            NSData *yuv420Data = [self convertVideoSampleToYUV420:sampleBuffer];
            
            dispatch_sync(_encodeQueue, ^{
                
                //开始硬编码
                _isStartHardEncoding = 1;
                
                // 摄像头采集后的图像是未编码的CMSampleBuffer形式，
                [self videoEncode:sampleBuffer];
                
            });
            
//            [self sendVideoSampleBuffer:sampleBuffer];
        }else if([self.audioDataOutput isEqual:captureOutput]){
            //捕获到音频数据
            NSLog(@"音频");

            //AudioToolBox PCM->AAC硬编码
            dispatch_sync(_encodeQueue, ^{
                
                [self.aacEncode encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
                    [_audioFileHandle writeData:encodedData];
                    NSLog(@"%@",_audioFileHandle);
                    
                }];
            });
            

            
            //音频数据转PCM
//            NSData *pcmData = [self convertAudioSampleToYUV420:sampleBuffer];
            
        }
    
}

#pragma mark -  SmapleBuffer转换
-(NSData *)convertVideoSampleToYUV420:(CMSampleBufferRef)videoSample{
    
    // 获取yuv数据
    // 通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef。
    // 这里面就包含了yuv420(NV12)数据的指针
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoSample);
    
    //表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //图像宽度（像素）
    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    //yuv中的y所占字节数
    size_t y_size = pixelWidth * pixelHeight;
    //yuv中的uv所占的字节数
    size_t uv_size = y_size / 2;
    
    //开创空间
    uint8_t *yuv_frame = malloc(uv_size + y_size);
    
    //清0
    memset(yuv_frame, 0, y_size+uv_size);
    
    
    //获取CVImageBufferRef中的y数据
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yuv_frame, y_frame, y_size);
    
    //获取CMVImageBufferRef中的uv数据
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(yuv_frame+y_size, uv_frame, uv_size);
    
    //锁定操作
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:yuv_frame length:y_size+uv_size];
}

-(NSData *)convertAudioSampleToYUV420:(CMSampleBufferRef)audioSample{
    
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(audioSample);

    //分配空间
    int8_t *audio_data = malloc(audioDataSize);
    
    //清0
    memset(audio_data, 0, audioDataSize);
    
    //获取CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(audioSample);
    
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}

#pragma mark -  VideoToolBox 硬编码
/*
 1、-initVideoToolBox中调用VTCompressionSessionCreate创建编码session，然后调用VTSessionSetProperty设置参数，最后调用VTCompressionSessionPrepareToEncodeFrames开始编码；
 2、开始视频录制，获取到摄像头的视频帧，传入-encode:，调用VTCompressionSessionEncodeFrame传入需要编码的视频帧，如果返回失败，调用VTCompressionSessionInvalidate销毁session，然后释放session；
 3、每一帧视频编码完成后会调用预先设置的编码函数didCompressH264，如果是关键帧需要用CMSampleBufferGetFormatDescription获取CMFormatDescriptionRef，然后用
 CMVideoFormatDescriptionGetH264ParameterSetAtIndex取得PPS和SPS；
 最后把每一帧的所有NALU数据前四个字节变成0x00 00 00 01之后再写入文件；
 4、调用VTCompressionSessionCompleteFrames完成编码，然后销毁session：VTCompressionSessionInvalidate，释放session。
 
 */


/**
 初始化videoToolBox
 */
-(void)initVideoToolBox{
    

    
    //同步
    dispatch_sync(_encodeQueue, ^{
       
        _frameID = 0;
        
        //给定宽高,过高的话会编码失败
        int width = 640 , height = 480;
        
        /**
         创建编码会话

         @param allocator#> 会话的分配器,传入NULL默认 description#>
         @param width#> 帧宽 description#>
         @param height#> 帧高 description#>
         @param codecType#> 编码器类型 description#>
         @param encoderSpecification#> 指定必须使用的特定视频编码器。通过空来让视频工具箱选择一个编码器。 description#>
         @param sourceImageBufferAttributes#> 像素缓存池源帧 description#>
         @param compressedDataAllocator#> 压缩数据分配器,默认为空 description#>
         @param outputCallback#> 回调函数,图像编码成功后调用 description#>
         @param outputCallbackRefCon#> 客户端定义的输出回调的参考值。 description#>
         @param compressionSessionOut#> 指向一个变量，以接收新的压缩会话 description#>
         @return <#return value description#>
         */
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self), &_encodeingSession);
        
        NSLog(@"H264状态:VTCompressionSessionCreate %d",(int)status);
        
        if (status != 0) {
            
            NSLog(@"H264会话创建失败");
            return ;
        }
        
        //设置实时编码输出(避免延迟)
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        
        // 设置关键帧（GOPsize)间隔,gop太小的话有时候图像会糊
        int frameInterval = 10;
        CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
        
        // 设置期望帧率,不是实际帧率
        int fps = 10;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);

        //设置码率，上限，单位是bps
        int bitRate = width * height * 3 * 4 * 8 ;
        CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
        
        // 设置码率，均值，单位是byte
        int bitRateLimit = width * height * 3 * 4 ;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        NSLog(@"码率%@",bitRateLimitRef);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        //可以开始编码
        VTCompressionSessionPrepareToEncodeFrames(_encodeingSession);
        
    });
    
    
}

/**
 *  h.264硬编码完成后回调 VTCompressionOutputCallback
 *  将硬编码成功的CMSampleBuffer转换成H264码流，通过网络传播
 *  解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组长成NALU。将NALU发送出去。
 */

//编码完成后回调
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    
//    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    //状态错误
    if (status != 0) {
        return;
    }
    
    //没准备好
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    VideoEncodeVC * encoder = (__bridge VideoEncodeVC*)outputCallbackRefCon;
    
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 判断当前帧是否为关键帧 获取sps & pps 数据
    // 解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组长成NALU。将NALU发送出去。
    if (keyframe) {
        
        // CMVideoFormatDescription：图像存储方式，编解码器等格式描述
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // sps
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusSPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusSPS == noErr) {
            
            // Found sps and now check for pps
            // pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusPPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusPPS == noErr) {
                
                // found sps pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder) {
                    
                    [encoder gotSPS:sps withPPS:pps];
                }
            }
        }
    }
    
    // 编码后的图像，以CMBlockBuffe方式存储
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffSet = 0;
        // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        static const int AVCCHeaderLength = 4;
        
        // 循环获取nalu数据
        while (bufferOffSet < totalLength - AVCCHeaderLength) {
            
            uint32_t NALUUnitLength = 0;
            // Read the NAL unit length
            memcpy(&NALUUnitLength, dataPointer + bufferOffSet, AVCCHeaderLength);
            // 从大端转系统端
            NALUUnitLength = CFSwapInt32BigToHost(NALUUnitLength);
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffSet + AVCCHeaderLength) length:NALUUnitLength];
            [encoder gotEncodedData:data isKeyFrame:keyframe];
            
            // Move to the next NAL unit in the block buffer
            bufferOffSet += AVCCHeaderLength + NALUUnitLength;
        }
    }
}

//传入PPS和SPS,写入到文件
- (void)gotSPS:(NSData *)sps withPPS:(NSData *)pps{
    
//    NSLog(@"gotSPSAndPPS %d withPPS %d", (int)[sps length], (int)[pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    [_fileHandle writeData:byteHeader];
    [_fileHandle writeData:sps];
    [_fileHandle writeData:byteHeader];
    [_fileHandle writeData:pps];
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    
//    NSLog(@"gotEncodedData %d", (int)[data length]);
    if (_fileHandle != NULL) {
        
        const char bytes[]= "\x00\x00\x00\x01";
        size_t lenght = (sizeof bytes) - 1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:lenght];
        [_fileHandle writeData:byteHeader];
        [_fileHandle writeData:data];
    }
}
/**
 视频编码

 @param videoSample <#videoSample description#>
 */
-(void)videoEncode:(CMSampleBufferRef)videoSampleBuffer{
    
    // CVPixelBufferRef 编码前图像数据结构
    // 利用给定的接口函数CMSampleBufferGetImageBuffer从中提取出CVPixelBufferRef
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(videoSampleBuffer);
    
    // 帧时间, 如果不设置会导致时间轴过长
    CMTime presentationTimeStamp = CMTimeMake(_frameID++, 1000);
    VTEncodeInfoFlags flags;
    
    // 使用硬编码接口VTCompressionSessionEncodeFrame来对该帧进行硬编码
    // 编码成功后，会自动调用session初始化时设置的回调函数
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeingSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        VTCompressionSessionInvalidate(_encodeingSession);
        CFRelease(_encodeingSession);
        _encodeingSession = NULL;
        return;
    }
    
//    NSLog(@"H264: VTCompressionSessionEncodeFrame Success : %d", (int)statusCode);
}


/**
 结束编码
 */
- (void)endVideoToolBox{
    
    VTCompressionSessionCompleteFrames(_encodeingSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(_encodeingSession);
    CFRelease(_encodeingSession);
    _encodeingSession = NULL;
}


/**
 停止视频硬编码
 */
-(void)stopHardCoding{
    
    if (_encodeingSession) {
        
        [self endVideoToolBox];
    }
    
    if (_fileHandle) {
        
        [self closeFileHandle];
    }
    
}



@end
