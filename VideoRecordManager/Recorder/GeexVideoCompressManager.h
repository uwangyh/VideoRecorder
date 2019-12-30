//
//  GeexVideoCompressManager.h
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/27.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^CompressOutPutBlock)(NSURL *);

@interface GeexVideoCompressManager : NSObject

//@property(nonatomic,copy) void (^compressOutPutBlock) (NSURL *outputUrl);

//压缩视频
- (void)convertVideo:(NSURL *)targetPath callBack:(CompressOutPutBlock)callBack;
//背景视频压缩
//- (void)convertBackGroundVideo:(NSURL *)targetPath;

//此方法可以获取文件的大小，返回的是单位是KB。
- (CGFloat)getFileSize:(NSString *)path;
//此方法可以获取视频文件的时长。
- (CGFloat)getVideoLength:(NSURL *)URL;
//删除缓存中的视频
- (void)clearMovieFromDoucments;
#pragma mark----获取视频的某一帧
- (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;


@end

NS_ASSUME_NONNULL_END
