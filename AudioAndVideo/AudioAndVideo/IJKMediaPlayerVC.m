//
//  IJKMediaPlayerVC.m
//  AudioAndVideo
//
//  Created by fy on 16/9/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "IJKMediaPlayerVC.h"

#import <IJKMediaFramework/IJKMediaFramework.h>

@interface IJKMediaPlayerVC ()

@property(atomic,strong)IJKFFMoviePlayerController * player;

@end

@implementation IJKMediaPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 检查当前FFmpeg版本是否匹配
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    
    // IJKFFOptions 是对视频的配置信息
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
    //是否要展示配置信息指示器(默认为NO)
    options.showHudView = NO;
    
    //创建播放器
    self.player = [[IJKFFMoviePlayerController alloc]initWithContentURL:[NSURL URLWithString:self.url] withOptions:options];
    
    self.player.view.frame = self.view.bounds;
    
    
    
}



@end
