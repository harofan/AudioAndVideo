//
//  FYProgressHUD.m
//  AudioAndVideo
//
//  Created by fy on 16/9/12.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "FYProgressHUD.h"

#import "SVProgressHUD.h"

@implementation FYProgressHUD

+ (void)show
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    [SVProgressHUD show];
}

+ (void)showWithMessage:(NSString *)message
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    [SVProgressHUD showWithStatus:message];
}

+ (void)dismiss
{
    [SVProgressHUD dismiss];
}

+ (void)showError:(NSString *)errorInfo
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    
    [SVProgressHUD setMinimumDismissTimeInterval:0.1f];
    [SVProgressHUD showErrorWithStatus:errorInfo];
}

+ (void)showSuccess:(NSString *)info
{
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    
    [SVProgressHUD setMinimumDismissTimeInterval:0.1f];
    [SVProgressHUD showSuccessWithStatus:info];
}

@end
