//
//  GeexVideoRecorder.h
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/30.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeexVideoRecordVC.h"

typedef void(^VideoPathBlock) (NSString *_Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface GeexVideoRecorder : NSObject

@property(nonatomic)NSUInteger videoTimes;

+ (instancetype _Nonnull)shared;

- (void)startWithWords:(NSString *)words controller:(UIViewController *)controller callBack:(VideoPathBlock)callBack;

@end

NS_ASSUME_NONNULL_END
