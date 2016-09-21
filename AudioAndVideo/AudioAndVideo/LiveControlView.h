//
//  LiveControlView.h
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <IJKMediaFramework/IJKMediaFramework.h>


// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface LiveControlView : UIView


/**
 遵守代理控制器的播放器
 */
@property(nonatomic,weak)id<IJKMediaPlayback>playerDelegate;

+ (instancetype)viewFromXibWith:(BOOL)isLiveVC;

@end
