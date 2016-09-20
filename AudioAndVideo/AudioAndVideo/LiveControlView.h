//
//  LiveControlView.h
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <IJKMediaFramework/IJKMediaFramework.h>


@protocol LiveControlViewDelegate <NSObject>


@end

@interface LiveControlView : UIView



/**
 遵守代理控制器的播放器
 */
@property(nonatomic,weak)id<IJKMediaPlayback>playerDelegate;

@property(nonatomic,weak)id<LiveControlViewDelegate>delegate;

+ (instancetype)viewFromXibWith:(BOOL)isLiveVC;

@end
