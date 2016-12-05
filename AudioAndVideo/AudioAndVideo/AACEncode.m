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
 *  提供音频数据转换的回调函数。 当转换器准备好输入新数据时，将重复调用此回调。
 
 */
OSStatus inInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    AACEncode *encoder = (__bridge AACEncode *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //PCM 缓冲区还没满
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    
    return noErr;
}

/**
 *  填充PCM到缓冲区
 */
- (size_t) copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)_pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}

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
-(void)setupEncoderFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    //输入音频流描述
    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
     // 初始化输出流的结构体描述为0. 很重要。
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
   
    // 音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
    outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
    
    // 设置编码格式
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;
    
    // 无损编码 ，0表示没有
    outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC;
    
    // 每一个packet的音频数据大小。如果的动态大小，设置为0。动态大小的格式，需要用AudioStreamPacketDescription 来确定每个packet的大小。
    outAudioStreamBasicDescription.mBytesPerPacket = 0;
    
    // 每个packet的帧数。如果是未压缩的音频数据，值是1。动态帧率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
    outAudioStreamBasicDescription.mFramesPerPacket = 1024;
    
    //  每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0 。
    outAudioStreamBasicDescription.mBytesPerFrame = 0;
    
    // 声道数
    outAudioStreamBasicDescription.mChannelsPerFrame = 1;
    
    // 压缩格式设置为0
    outAudioStreamBasicDescription.mBitsPerChannel = 0;
    
    // 8字节对齐，填0.
    outAudioStreamBasicDescription.mReserved = 0;
    
    //软编
    AudioClassDescription *description = [self
                                          getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                          fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    
    // 创建转换器
    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription, &outAudioStreamBasicDescription, 1, description, &_audioConverter);
    if (status != 0) {
        NSLog(@"setup converter: %d", (int)status);
    }
    
}



-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *, NSError *))completionBlock{
    CFRetain(sampleBuffer);
    dispatch_async(_encoderQueue, ^{
        NSLog(@"1");
        //音频转换对象不存在
        if (!_audioConverter) {
            [self setupEncoderFromSampleBuffer:sampleBuffer];
        }
        
        // 编码后的图像，以CMBlockBuffe方式存储
        //CMBlockBuffer是在处理系统中用于移动内存块的对象。可能不在一片内存区域中,方便用它来确定位置
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        memset(_aacBuffer, 0, _aacBufferSize);
        
        //一个可变长度的audiobuffer结构阵列。
        AudioBufferList outAudioBufferList = {0};
        
        //mBuffers数量
        outAudioBufferList.mNumberBuffers = 1;
        
        //缓冲区中的交错信道的数目。
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        
        //缓冲区编码大小
        outAudioBufferList.mBuffers[0].mDataByteSize = (int)_aacBufferSize;
        
        //数据
        outAudioBufferList.mBuffers[0].mData = _aacBuffer;
        
        //这种结构描述了数据包布局的一个缓冲区的数据大小,每个包可能不是相同的或有外部数据之间的小包.
        AudioStreamPacketDescription *outPacketDescription = NULL;
        UInt32 ioOutputDataPacketSize = 1;
        
        // 将由一个输入回调函数提供的数据，支持非交错和分组格式。
        // 从AudioConverter生成输出数据的缓冲区列表。 必要时调用提供的输入回调函数。
        /**
         转换由输入回调函数提供的数据，支持非交织和分组格式。

         @param _audioConverter <#_audioConverter description#>
         @param inInputDataProc 提供输入数据的回调函数。
         @param inInputDataProcUserData 使用回调函数者
         @param ioOutputDataPacketSize 在进入时，outOutputData的容量以包中的表示转换器的输出格式。 在退出时，转换的数据包数数据写入outOutputData。
         @param outOutputData 缓冲区写入数据
         @param outPacketDescription 如果非空，并且转换器的输出使用包描述，那么数据包描述被写入此数组。 它必须指向一个内存块能够保存* ioOutputDataPacketSize数据包描述。有关确定音频格式的方法，请参阅AudioFormat.h,使用分组描述）。
         @return <#return value description#>
         */
        status = AudioConverterFillComplexBuffer(_audioConverter, inInputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, &outAudioBufferList, outPacketDescription);

        //aac data
        NSData *data = nil;
        if (status == 0) {
            NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            
            //adts头
            NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
            
            //拼接
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            data = fullData;
        } else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        //传入block
        if (completionBlock) {
            dispatch_async(_callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });

}

/**
 *  获取编解码器
 *
 *  @param type         编码格式
 *  @param manufacturer 软/硬编
 *
 编解码器（codec）指的是一个能够对一个信号或者一个数据流进行变换的设备或者程序。这里指的变换既包括将 信号或者数据流进行编码（通常是为了传输、存储或者加密）或者提取得到一个编码流的操作，也包括为了观察或者处理从这个编码流中恢复适合观察或操作的形式的操作。编解码器经常用在视频会议和流媒体等应用中。
 *  @return 指定编码器
 */
- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    
    
    /**
     检索有关给定属性的信息

     @param kAudioFormatProperty_Encoders 音频格式属性ID
     @param encoderSpecifier 大小
     @param encoderSpecifier 说明符是用作某些属性的输入参数的数据的缓冲区。
     @param size 属性当前值的大小
     @return <#return value description#>
     */
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    
    
    /**
     检索指示的属性数据

     @param kAudioFormatProperty_Encoders <#kAudioFormatProperty_Encoders description#>
     @param encoderSpecifier 说明符数据的大小。
     @param encoderSpecifier 指定符是用作某些属性的输入参数的数据缓冲区
     @param size 在其中写入属性数据的缓冲区。 如果outPropertyData为NULL，ioPropertyDataSize不为空，则将报告已写入的数量。
     @param descriptions
     @return <#return value description#>
     */
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

/**
 *  在每个AAC包的开始处添加ADTS头。
 *  当MediaCodec编码器生成原始AAC数据的分组时，这是需要的
 *
 *  注意packetLen必须在ADTS头本身计数。
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    
    //adts头是一个7bit的数据
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    
    // Variables Recycled by addADTStoPacket
    //表示使用哪个级别的AAC，有些芯片只支持AAC LC
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    /**
     0: 96000 Hz
     1: 88200 Hz
     2: 64000 Hz
     3: 48000 Hz
     4: 44100 Hz
     5: 32000 Hz
     6: 24000 Hz
     7: 22050 Hz
     8: 16000 Hz
     9: 12000 Hz
     10: 11025 Hz
     11: 8000 Hz
     12: 7350 Hz
     13: Reserved
     14: Reserved
     15: frequency is written explictly
     */
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}
@end
