//
//  AACEncode.m
//  AudioAndVideo
//
//  Created by fy on 2016/12/1.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "AACEncode.h"

@interface AACEncode ()

//音频转换器
@property (nonatomic) AudioConverterRef audioConverter;

//aac缓冲区
@property (nonatomic) uint8_t *aacBuffer;

//缓冲区大小
@property (nonatomic) NSUInteger aacBufferSize;

//pcm缓冲区
@property (nonatomic) char *pcmBuffer;

//pcm缓冲区大小
@property (nonatomic) size_t pcmBufferSize;

@end

@implementation AACEncode


/**
 初始化

 @return <#return value description#>
 */
-(instancetype)init{
    
    if (self = [super init]) {
        //创建队列
        _encoderQueue = dispatch_queue_create("AAC Encoder Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("AAC Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
        _audioConverter = NULL;
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
    }
    
    return self;
}

-(void)dealloc{
    AudioConverterDispose(_audioConverter);
    free(_aacBuffer);
}


/**
 设置编码参数

 @param sampleBuffer <#sampleBuffer description#>
 */
//-(void)setupEncoderFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
//    
//    //输入音频流描述
//    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
//    
//     // 初始化输出流的结构体描述为0. 很重要。
//    AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
//   
//    // 音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
//    outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
//    
//    // 设置编码格式
//    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;
//    
//    // 无损编码 ，0表示没有
//    outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC;
//    
//    // 每一个packet的音频数据大小。如果的动态大小，设置为0。动态大小的格式，需要用AudioStreamPacketDescription 来确定每个packet的大小。
//    outAudioStreamBasicDescription.mBytesPerPacket = 0;
//    
//    // 每个packet的帧数。如果是未压缩的音频数据，值是1。动态帧率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
//    outAudioStreamBasicDescription.mFramesPerPacket = 1024;
//    
//    //  每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0 。
//    outAudioStreamBasicDescription.mBytesPerFrame = 0;
//    
//    // 声道数
//    outAudioStreamBasicDescription.mChannelsPerFrame = 1;
//    
//    // 压缩格式设置为0
//    outAudioStreamBasicDescription.mBitsPerChannel = 0;
//    
//    // 8字节对齐，填0.
//    outAudioStreamBasicDescription.mReserved = 0;
//    
//    //软编
//    AudioClassDescription *description = [self
//                                          getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
//                                          fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
//    
//    // 创建转换器
//    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription, &outAudioStreamBasicDescription, 1, description, &_audioConverter);
//    if (status != 0) {
//        NSLog(@"setup converter: %d", (int)status);
//    }
//    
//}
//
//-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *, NSError *))completionBlock{
//    CFRetain(sampleBuffer);
//    dispatch_async(_encoderQueue, ^{
//        if (!_audioConverter) {
//            [self setupEncoderFromSampleBuffer:sampleBuffer];
//        }
//        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//        CFRetain(blockBuffer);
//        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
//        NSError *error = nil;
//        if (status != kCMBlockBufferNoErr) {
//            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
//        }
//        memset(_aacBuffer, 0, _aacBufferSize);
//        
//        AudioBufferList outAudioBufferList = {0};
//        outAudioBufferList.mNumberBuffers = 1;
//        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
//        outAudioBufferList.mBuffers[0].mDataByteSize = (int)_aacBufferSize;
//        outAudioBufferList.mBuffers[0].mData = _aacBuffer;
//        AudioStreamPacketDescription *outPacketDescription = NULL;
//        UInt32 ioOutputDataPacketSize = 1;
//        // Converts data supplied by an input callback function, supporting non-interleaved and packetized formats.
//        // Produces a buffer list of output data from an AudioConverter. The supplied input callback function is called whenever necessary.
//        status = AudioConverterFillComplexBuffer(_audioConverter, inInputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, &outAudioBufferList, outPacketDescription);
//        NSData *data = nil;
//        if (status == 0) {
//            NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
//            NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
//            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
//            [fullData appendData:rawAAC];
//            data = fullData;
//        } else {
//            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
//        }
//        if (completionBlock) {
//            dispatch_async(_callbackQueue, ^{
//                completionBlock(data, error);
//            });
//        }
//        CFRelease(sampleBuffer);
//        CFRelease(blockBuffer);
//    });
//
//}
@end
