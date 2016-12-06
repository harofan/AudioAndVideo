//
//  AACEncode.h
//  AudioAndVideo
//
//  Created by fy on 2016/12/1.
//  Copyright © 2016年 LY. All rights reserved.
//  默认情况下，Apple会创建一个硬件编码器，如果硬件不可用，会创建软件编码器。
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import <AudioToolbox/AudioToolbox.h>

@interface AACEncode : NSObject

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;


@end
