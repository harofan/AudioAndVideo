//
//  UIView+extension.m
//  AudioAndVideo
//
//  Created by fy on 16/9/19.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "UIView+extension.h"

@implementation UIView (extension)

+ (instancetype)viewFromXib
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}
@end
