//
//  SpeedView.h
//  AudioAndVideo
//
//  Created by fy on 16/9/19.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpeedView : UIView


/**
 快进/快退图标
 */
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

/**
 快进/快退详情
 */
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

/**
 速度
 */
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

/**
 进度
 */
@property (weak, nonatomic) IBOutlet UIProgressView *progessView;

@end

