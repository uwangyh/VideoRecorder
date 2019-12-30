//
//  GeexVideoRecordVC.h
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/26.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^VideoFinishBlock) (NSString *_Nullable);

@interface GeexVideoRecordVC : UIViewController

//话术信息
@property(nonatomic,copy)NSString *words;
//视频时间
@property(nonatomic)NSUInteger customsTime;
@property(nonatomic,copy)VideoFinishBlock finishBlcok;

@end

NS_ASSUME_NONNULL_END
