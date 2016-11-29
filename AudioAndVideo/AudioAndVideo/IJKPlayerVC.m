//
//  IJKPlayerVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "IJKPlayerVC.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND

//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS

#import "Masonry.h"

#import "IJKLiveVC.h"


@interface IJKPlayerVC ()

@end

@implementation IJKPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUI];
}

-(void)dealloc{
    
    NSLog(@"销毁了");
}

-(void)setupUI{
    
    self.navigationController.navigationBar.hidden = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton * livePlayBtn = [[UIButton alloc] init];
    
    UIButton * netVideoBtn = [[UIButton alloc] init];
    
    [livePlayBtn setTitle:@"播放直播" forState:UIControlStateNormal];
    
    [livePlayBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [netVideoBtn setTitle:@"播放网络视频" forState:UIControlStateNormal];
    
    [netVideoBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    
    [self.view addSubview:livePlayBtn];
    
    [self.view addSubview:netVideoBtn];
    
    
    [livePlayBtn makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.centerX);
        
        make.bottom.equalTo(self.view.bottom).equalTo(-20);
    }];
    
    [netVideoBtn makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(self.view.centerX);
        
        make.bottom.equalTo(livePlayBtn.top).offset(-20);
        
    }];
    //直播按钮点击
    [[livePlayBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        IJKLiveVC * liveVC = [[IJKLiveVC alloc] init];
        
        liveVC.url = @"http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8";
        
        liveVC.isLiveVC = YES;
        
//        liveVC.url = @"https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
        
        [self.navigationController pushViewController:liveVC animated:YES];
        
    }];
    //视频播放按钮点击
    [[netVideoBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        IJKLiveVC * liveVC = [[IJKLiveVC alloc] init];
        
        liveVC.isLiveVC = NO;
        
        liveVC.url = @"http://60.190.28.52/c31.aipai.com/user/107/35831107/6571752/card/38774421/card.mp4";
        
        [self.navigationController pushViewController:liveVC animated:YES];
        
    }];
}
@end
