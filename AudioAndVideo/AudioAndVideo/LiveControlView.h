//
//  LiveControlView.h
//  AudioAndVideo
//
//  Created by fy on 16/9/18.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LiveControlDelegate <NSObject>

@end

@interface LiveControlView : UIView

/**
 遵守代理的控制器
 */
@property(nonatomic,weak)id<LiveControlDelegate>delegateVC;


/**
 遵守代理控制器的播放器
 */
@property(nonatomic,weak)id<LiveControlDelegate>playerDelegate;

@end
