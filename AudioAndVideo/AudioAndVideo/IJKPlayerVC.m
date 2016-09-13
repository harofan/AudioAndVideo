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

@interface IJKPlayerVC ()

@end

@implementation IJKPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUI];
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
    
    [[livePlayBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
    }];
    
    [[netVideoBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
    }];
}
@end
