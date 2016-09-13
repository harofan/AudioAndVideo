//
//  IJKMediaPlayerVC.h
//  AudioAndVideo
//
//  Created by fy on 16/9/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJKMediaPlayerVC : UIViewController

//外界给一个URL地址(可以是直播,也可以是网络视频地址)
@property (atomic, strong) NSURL *url;  //此处线程是安全的

@end
