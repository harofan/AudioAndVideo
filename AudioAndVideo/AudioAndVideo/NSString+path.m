//
//  NSString+path.m
//  AudioAndVideo
//
//  Created by fy on 16/9/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "NSString+path.h"

@implementation NSString (path)

+(NSString *)documentPath{
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
