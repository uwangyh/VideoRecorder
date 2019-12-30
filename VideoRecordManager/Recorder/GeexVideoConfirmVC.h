//
//  GeexVideoConfirmVC.h
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/27.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^VideoCompressBlock) (NSURL *_Nullable);


@interface GeexVideoConfirmVC : UIViewController

@property(nonatomic,copy) NSURL *videoUrl;
@property(nonatomic,copy)VideoCompressBlock compressBlcok;

@end

NS_ASSUME_NONNULL_END
