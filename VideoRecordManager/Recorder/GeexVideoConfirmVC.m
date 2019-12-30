//
//  GeexVideoConfirmVC.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/27.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "GeexVideoConfirmVC.h"
#import "GeexVideoCompressManager.h"

#define kStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface GeexVideoConfirmVC ()

@property(nonatomic,strong)GeexVideoCompressManager *compressManager;

//自定义导航栏
@property(nonatomic)UIView *customNavigationView;
@property(nonatomic)UILabel *customNavigationTitleLabel;

//视频预览图片
@property(nonatomic)UIImageView *previewImage;

@end

@implementation GeexVideoConfirmVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = true;
    self.view.backgroundColor = [UIColor colorWithRed:40.0/255.0f green:52.0/255.0f blue:64.0/255.0f alpha:1];
    
    NSLog(@"压缩前%.2fKB----时长%.1fs", [self.compressManager getFileSize:[self.videoUrl path]],[self.compressManager getVideoLength:self.videoUrl]);
    //自定义导航栏
    [self.view addSubview:self.customNavigationView];
    //视频预览图片
    [self.view addSubview:self.previewImage];
    
    //底部布局
    [self bottomUILayout];
    
}

- (void)bottomButtonTap:(UIButton *)btn{
    if (btn.tag == 10) {
        NSLog(@"重新拍摄");
        [self backVC];
    }else{
        NSLog(@"确认提交");
        //视频压缩
        __weak typeof(self) weakSelf = self;
        [self.compressManager convertVideo:self.videoUrl callBack:^(NSURL * _Nonnull outputUrl) {
            weakSelf.videoUrl = outputUrl;
            //压缩后的路径
            NSLog(@"%@",weakSelf.videoUrl);
            if (weakSelf.videoUrl) {
                weakSelf.compressBlcok(weakSelf.videoUrl);
            }
            [weakSelf dismissViewControllerAnimated:true completion:nil];
        }];
    }
}

- (void)bottomUILayout{
    UILabel *finishLale = [[UILabel alloc]initWithFrame:CGRectMake(0, self.previewImage.frame.size.height + self.customNavigationView.frame.size.height, kScreenWidth, 100)];
    finishLale.text = @"录制已完成";
    finishLale.textColor = [UIColor whiteColor];
    finishLale.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:finishLale];
    
    CGFloat x = (kScreenWidth-300)/3.0;
    CGFloat y = finishLale.frame.origin.y + finishLale.frame.size.height;
    
    NSArray *itemArr = @[@"重新拍摄",@"确认提交"];
    NSArray *imageNameArr = @[@"chongxinpaishe",@"querentijiao"];
    for (NSInteger i = 0; i < 2; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:itemArr[i] forState:UIControlStateNormal];
        button.tag = 10+i;
        [button addTarget:self action:@selector(bottomButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(x*(i+1)+150*i, y, 150, 45);
        [button setBackgroundImage:[UIImage imageNamed:imageNameArr[i]] forState:UIControlStateNormal];
        [self.view addSubview:button];
    }
}

//自定义导航栏
- (UIView *)customNavigationView{
    if (!_customNavigationView) {
        _customNavigationView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kStatusBarHeight + 44)];
        _customNavigationView.backgroundColor = [UIColor blackColor];
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:[UIImage imageNamed:@"shangyibu"] forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, kStatusBarHeight, 100, 44);
        [backButton addTarget:self action:@selector(backVC) forControlEvents:UIControlEventTouchUpInside];
        [_customNavigationView addSubview:backButton];
        
        self.customNavigationTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(kScreenWidth/2-50, kStatusBarHeight, 100, 44)];
        self.customNavigationTitleLabel.text = @"视频确认";
        self.customNavigationTitleLabel.textColor = [UIColor whiteColor];
        self.customNavigationTitleLabel.textAlignment = NSTextAlignmentCenter;
        [_customNavigationView addSubview:self.customNavigationTitleLabel];
        
        
    }
    return _customNavigationView;
}
- (UIImageView *)previewImage{
    if (!_previewImage) {
        _previewImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.customNavigationView.frame.size.height, kScreenWidth, kScreenWidth/340.0*350.0)];
        _previewImage.image = [self.compressManager thumbnailImageForVideo:self.videoUrl atTime:2];
    }
    return _previewImage;
}

- (GeexVideoCompressManager *)compressManager{
    if (!_compressManager) {
        _compressManager = [[GeexVideoCompressManager alloc]init];
    }
    return _compressManager;
}

- (void)backVC{
    [self.compressManager clearMovieFromDoucments];
    [self.navigationController popViewControllerAnimated:true];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
