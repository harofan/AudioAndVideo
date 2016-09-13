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

@end

@implementation IJKMediaPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 检查当前FFmpeg版本是否匹配
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    
    // IJKFFOptions 是对视频的配置信息
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
}



@end
