//
//  AACEncode.h
//  AudioAndVideo
//
//  Created by fy on 2016/12/1.
//  Copyright © 2016年 LY. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import <AudioToolbox/AudioToolbox.h>

@interface AACEncode : NSObject

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;


@end
