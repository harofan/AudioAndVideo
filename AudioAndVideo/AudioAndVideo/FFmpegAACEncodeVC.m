//
//  FFmpegAACEncodeVC.m
//  AudioAndVideo
//
//  Created by fy on 2016/12/6.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "FFmpegAACEncodeVC.h"

#import "avformat.h"

#import "avcodec.h"

@interface FFmpegAACEncodeVC ()

{
    AVFormatContext* _pFormatCtx;       //上下文
    AVOutputFormat* _fmt;               //输出格式
    AVStream* _audio_st;                //音频流
    AVCodecContext* _pCodecCtx;         //编码器上下文结构体
    AVCodec* _pCodec;                   //编码类型
    
    uint8_t* _frame_buf;                //缓冲区数据
    AVFrame* _pFrame;                   //编码后的数据
    AVPacket _pkt;                      //编码前的数据
}

@end

@implementation FFmpegAACEncodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self encode];
}

-(void)encode{
    
    //音频占用字节数
    int size = 0;
    
    //音频帧数量(决定循环次数)
    int frameNumber = 1000;
    int i;
    
    int gotFrame = 0;
    int ret = 0;
    
    //文件路径
    NSString *inFilePath = [[NSBundle mainBundle]pathForResource:@"tdjm.pcm" ofType:nil];
    
    const char * inPath = [inFilePath UTF8String];
    
    FILE * in_file = NULL;
    
    in_file = fopen(inPath, "rb");
    
    if (!in_file) {
        NSLog(@"打开失败");
        return;
    }
    
    //输出文件
    NSString *outFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.aac"];
    [[NSFileManager defaultManager] removeItemAtPath:outFilePath error:nil]; // 移除旧文件
//    [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil]; // 创建新文件
    
    const char * outPath = [outFilePath UTF8String];
    
    //注册
    av_register_all();
    
    //初始化输出码流
    _pFormatCtx = avformat_alloc_context();
    _fmt = av_guess_format(NULL, outPath, NULL);
    _pFormatCtx->oformat = _fmt;
    
    /*
     s：函数调用成功之后创建的AVIOContext结构体。
     url：输入输出协议的地址（文件也是一种“广义”的协议，对于文件来说就是文件的路径）。
     flags：打开地址的方式。可以选择只读，只写，或者读写。取值如下。
     AVIO_FLAG_READ：只读。
     AVIO_FLAG_WRITE：只写。
     AVIO_FLAG_READ_WRITE：读写。
     int_cb：目前还没有用过。
     options：目前还没有用过
     */
    //打开输出文件
    if (avio_open(&_pFormatCtx->pb, outPath, AVIO_FLAG_WRITE)<0) {
        NSLog(@"打开输出文件路径失败");
        return;
    }
    
    //创建输出码流通道
    _audio_st = avformat_new_stream(_pFormatCtx, 0);
    
    if (_audio_st == NULL) {
        return ;
    }
    
    _pCodecCtx = _audio_st->codec;
    _pCodecCtx->codec_id = _fmt->audio_codec;//编码器
    _pCodecCtx->codec_type = AVMEDIA_TYPE_AUDIO;//编码器类型
    _pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;//16位
    _pCodecCtx->sample_rate= 44100;//采样率
    _pCodecCtx->channel_layout=AV_CH_LAYOUT_STEREO;
    _pCodecCtx->channels = av_get_channel_layout_nb_channels(_pCodecCtx->channel_layout);
    _pCodecCtx->bit_rate = 64000;//平均比特率,码率
    
    //展示信息(打印有关输入或输出格式的详细信息，例如持续时间，比特率，流，容器，程序，元数据，辅助数据，编解码器和时基。)
    av_dump_format(_pCodecCtx, 0, outPath, 1);
    
    //查找编码器
    _pCodec = avcodec_find_encoder(_pCodecCtx->codec_id);
    
    if (!_pCodec) {
        NSLog(@"没找到编码器");
        return;
    }
    
    //打开编码器
    if (avcodec_open2(_pCodecCtx, _pCodec, NULL)<0) {
        NSLog(@"打开编码器失败");
        return;
    }
    
    //开辟编码后数据
    _pFrame = av_frame_alloc();
    
    //信道数目,个人理解，就是同时有个几个设备在进行音频的采样，最少为1，一般通道数越多，音质越好。
    _pFrame->nb_samples = _pCodecCtx->frame_size;
    
    //帧的格式
    _pFrame->format = _pCodecCtx->sample_fmt;
    
    
    
    /**
     获取给定音频参数所需的缓冲区大小

     @param linesize#> 每行字节数 description#>
     @param nb_channels#> 通道数 description#>
     @param nb_samples#> 单个通道中的样本数 description#>
     @param sample_fmt#> 示例格式 description#>
     @param align#> 缓冲区大小是否对齐 description#>
     @return <#return value description#>
     */
    size = av_samples_get_buffer_size(NULL, _pCodecCtx->channels, _pCodecCtx->frame_size, _pCodecCtx->sample_fmt, 1);
    
    //开辟缓冲区
    _frame_buf = (uint8_t *)av_malloc(size);
    
    /**
     填充音频数据和行指针
     
     缓冲区buf必须是预分配的缓冲区，其大小足以包含指定的样本量。 填充的AVFrame数据指针将指向此缓冲区。

     @param frame#> 原始数据 description#>
     @param nb_channels#> 通道数 description#>
     @param sample_fmt#> 示例格式 description#>
     @param buf#> 缓冲区用于帧数据 description#>
     @param buf_size#> 缓冲区大小 description#>
     @param align#> 平面尺寸样本对齐,默认为0 description#>
     @return 大于0成功,小于0失败
     */
    avcodec_fill_audio_frame(_pFrame, _pCodecCtx->channels, _pCodecCtx->sample_fmt, (const uint8_t*)_frame_buf, size, 1);
    
    //写头文件
    avformat_write_header(_pCodecCtx, NULL);
    
    //数据包
    av_new_packet(&_pkt, size);
    
    for (i = 0; i < frameNumber; i++) {
        
        //循环读取PCM
        if (fread(_frame_buf, 1, size, in_file)<=0) {
            NSLog(@"读取失败");
            return;
        }else if (feof(in_file)){
            //若文件读取结束
            break;
        }
        
        //PCM DATA
        _pFrame->data[0] = _frame_buf;
        
        //播放时间戳
        _pFrame->pts = i * 100;
        
        gotFrame = 0;
        
        //编码
        
        /**
         编码一个音频AVFrame为AVPacket。

         @param avctx#> <#avctx#> description#>
         @param avpkt#> <#avpkt#> description#>
         @param frame#> <#frame#> description#>
         @param got_packet_ptr#> <#got_packet_ptr#> description#>
         @return <#return value description#>
         */
//        ret = avcodec_encode_audio2(<#AVCodecContext *avctx#>, <#AVPacket *avpkt#>, <#const AVFrame *frame#>, <#int *got_packet_ptr#>)
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
    }
    
}

@end
