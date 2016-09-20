//
//  IJKLiveVC.h
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJKLiveVC : UIViewController

//外界给一个URL地址(可以是直播,也可以是网络视频地址)
@property (atomic, strong) NSString *url;  //此处线程是安全的

//播放器是直播还是播放视频
@property (atomic, assign) BOOL isLiveVC;

@end
