//
//  GeexVideoRecorder.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/30.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "GeexVideoRecorder.h"

@implementation GeexVideoRecorder

+ (instancetype _Nonnull)shared {
    static dispatch_once_t onceToken;
    static GeexVideoRecorder *shareInstance = nil;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (void)startWithWords:(NSString *)words controller:(UIViewController *)controller callBack:(VideoPathBlock)callBack{
    GeexVideoRecordVC *gc = [[GeexVideoRecordVC alloc]init];
    gc.words = words;
    if (self.videoTimes) {
        gc.customsTime = self.videoTimes;
    }
    [gc setFinishBlcok:^(NSString *path) {
        if (path) {
            callBack(path);
        }
    }];
    [controller presentViewController:[[UINavigationController alloc]initWithRootViewController:gc] animated:true completion:nil];
}

@end
