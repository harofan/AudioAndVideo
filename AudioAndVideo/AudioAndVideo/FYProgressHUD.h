//
//  FYProgressHUD.h
//  AudioAndVideo
//
//  Created by fy on 16/9/12.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FYProgressHUD : NSObject

+(void)show;

+(void)showWithMessage:(NSString*)message;

+(void)dismiss;

+(void)showError:(NSString *)errorInfo;

+(void)showSuccess:(NSString *)info;

@end
