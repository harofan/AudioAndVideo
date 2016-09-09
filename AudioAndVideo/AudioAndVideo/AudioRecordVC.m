//
//  AudioRecordVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "AudioRecordVC.h"

//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND

//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS

#import "Masonry.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

#import <AVFoundation/AVFoundation.h>

#import "NSString+path.h"

@interface AudioRecordVC ()

@property (strong, nonatomic)   AVAudioRecorder *recorder;

@end

@implementation AudioRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    [self createRecord];
    
    [self createUpUI];
}

-(void)dealloc{
    
    [self.recorder stop];
}
#pragma mark -  UI
-(void)createUpUI{
    
    UIButton * startBtn = [[UIButton alloc]init];
    
    //开始/继续录音
    [[startBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
       
        [self.recorder record];
        
    }];
    
    UIButton * pauseBtn = [[UIButton alloc]init];
    
    //暂停录音
    [[pauseBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
               
        [self.recorder pause];
        
    }];
    [startBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [pauseBtn setTitle:@"暂停录音" forState:UIControlStateNormal];
    
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

#pragma mark -  record
-(void)createRecord{
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    
    //创建路径
    NSString * path = [[NSString documentPath] stringByAppendingString:@"/haha.aac"];
    
    NSURL * url = [NSURL fileURLWithPath:path];
    
    //第三方解决方案
    // 录制PCM => 第三方库(lame) => mp3数据 => 上传
    // 录制PCM => speex格式压缩 => 上传
    NSDictionary * settings = @{
                                AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                AVSampleRateKey:@(8000),    //采样频率 每秒
                                AVNumberOfChannelsKey:@(1),
                                AVLinearPCMBitDepthKey:@(8) //位深
                                };
    
    //PCM数据大小 44字节 采样率 * 位深 * 声道
    
    NSError * err= nil;
    
    //创建录制对象,避免被释放
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
}
@end
