//
//  GeexVideoCompressManager.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/27.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "GeexVideoCompressManager.h"
#import <AVFoundation/AVFoundation.h>

@interface GeexVideoCompressManager()

@property(nonatomic,copy)NSURL *videoUrl;

@end

@implementation GeexVideoCompressManager

- (void)convertVideo:(NSURL *)targetPath callBack:(nonnull CompressOutPutBlock)callBack{
    
    self.videoUrl = targetPath;
    
    NSURL *newVideoUrl ; //一般.mp4
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:self.videoUrl options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    //  NSLog(resultPath);
    exportSession.outputURL = newVideoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    //MF_ShowLoading;
    //MF_WEAK_SELF(self);
    __weak typeof(self) weakSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        //切到主线程执行接下来的操作
        dispatch_async(dispatch_get_main_queue(), ^{
            //MF_HideLoading;
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                //压缩成功
                NSLog(@"压缩后%.2fKB----%.1fs", [weakSelf getFileSize:[newVideoUrl path]],[weakSelf getVideoLength:newVideoUrl]);
                weakSelf.videoUrl = newVideoUrl;
                if ([weakSelf getFileSize:[newVideoUrl path]]/1000.0 > 10) {
                    //压缩后大于10M 再次压缩
                    [weakSelf convertVideo:weakSelf.videoUrl callBack:callBack];
                }else{
                    //压缩至小于10M 再进行上传
                    NSLog(@"压缩完成--%.2fM",[weakSelf getFileSize:[newVideoUrl path]]/1000);
                    //[weakSelf uploadVideo:newVideoUrl];
                    //weakSelf.haveCompress = YES;

                    //回传压缩之后的视频路径
                    if (callBack) {
                        callBack(weakSelf.videoUrl);
                    }
                }
            }else{
                NSLog(@"%ld",(long)exportSession.status);
                //压缩失败 重新压缩
                //[MBManager showBriefAlert:@"视频压缩失败，请返回重新录制"];
            }
        });
    }];
}

//此方法可以获取文件的大小，返回的是单位是KB。
- (CGFloat)getFileSize:(NSString *)path{
    //NSLog(@"%@",path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }else{
        NSLog(@"找不到文件");
    }
    return filesize;
}
//此方法可以获取视频文件的时长。
- (CGFloat)getVideoLength:(NSURL *)URL{
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:URL];
    CMTime time = [avUrl duration];
    int second = ceil(time.value/time.timescale);
    return second;
}
//删除缓存中的视频
- (void)clearMovieFromDoucments{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        NSLog(@"%@",filename);
        if ([filename isEqualToString:@"tmp.PNG"]) {
            NSLog(@"删除%@",filename);
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
            continue;
        }
        if ([[[filename pathExtension] lowercaseString] isEqualToString:@"mp4"]||
            [[[filename pathExtension] lowercaseString] isEqualToString:@"mov"]||
            [[[filename pathExtension] lowercaseString] isEqualToString:@"png"]) {
            NSLog(@"删除%@",filename);
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}


#pragma mark----获取视频的某一帧
- (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    if (!videoURL) {
        return nil;
    }
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    NSParameterAssert(asset);
    
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    
    assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    
    CFTimeInterval thumbnailImageTime = time;
    
    NSError *thumbnailImageGenerationError = nil;
    
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef){
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    }
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage:thumbnailImageRef]:nil;
    
    return thumbnailImage;
}

- (void)dealloc{
    NSLog(@"VideoCompressManager dealloc");
}

/*
- (void)convertBackGroundVideo:(NSURL *)targetPath{
    
    self.videoUrl = targetPath;
    
    NSURL *newVideoUrl ; //一般.mp4
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:self.videoUrl options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    //  NSLog(resultPath);
    exportSession.outputURL = newVideoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    //MF_WEAK_SELF(self);
    __weak typeof(self) weakSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        //切到主线程执行接下来的操作
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                //压缩成功
                NSLog(@"压缩后%.2f----%.1fs", [weakSelf getFileSize:[newVideoUrl path]],[weakSelf getVideoLength:newVideoUrl]);
                weakSelf.videoUrl = newVideoUrl;
                if ([weakSelf getFileSize:[newVideoUrl path]]/1000.0 > 10) {
                    //压缩后大于10M 再次压缩
                    [weakSelf convertVideo:weakSelf.videoUrl];
                }else{
                    //压缩至小于10M 再进行上传
                    NSLog(@"压缩完成--%.2fM",[weakSelf getFileSize:[newVideoUrl path]]/1000);
                    //[weakSelf uploadVideo:newVideoUrl];
                    //weakSelf.haveCompress = YES;
                    
                    //回传压缩之后的视频路径
                    if (weakSelf.compressOutPutBlock) {
                        weakSelf.compressOutPutBlock(weakSelf.videoUrl);
                    }
                }
            }else{
                NSLog(@"%ld",(long)exportSession.status);
                //压缩失败 重新压缩
                //[MBManager showBriefAlert:@"视频压缩失败，请返回重新录制"];
            }
        });
    }];
}*/



@end
