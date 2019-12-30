//
//  GeexDecibelHelper.h
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/30.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DecibelMeterBlock)(double dbSPL);

NS_ASSUME_NONNULL_BEGIN

@interface GeexDecibelHelper : NSObject

@property (nonatomic, copy) DecibelMeterBlock decibelMeterBlock;

/** 开始，是否保存文件*/
- (void)startMeasuringWithIsSaveVoice:(BOOL)IsSaveVoice;

/** 开始，默认保存文件*/
- (void)startMeasuring;

/** 停止*/
- (void)stopMeasuring;


@end

NS_ASSUME_NONNULL_END
