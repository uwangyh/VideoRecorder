//
//  GeexVideoRecordVC.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/26.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "GeexVideoRecordVC.h"
#import <AVFoundation/AVFoundation.h>
#import "GeexVideoConfirmVC.h"
#import "GeexDecibelHelper.h"

#define kStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface GeexVideoRecordVC ()<AVCaptureFileOutputRecordingDelegate>
{
   //拍摄是否准备完毕
   BOOL _cameraReady;
   //当前倒数
   NSInteger _secCount;
}
//自定义导航栏
@property(nonatomic)UIView *customNavigationView;
@property(nonatomic)UILabel *customNavigationTitleLabel;

//视频捕获区域
@property(nonatomic)UIView *containerView;
//人脸位置辅助图片
@property(nonatomic)UIImageView *videoAssistImage;
//周围音量检测视图
@property(nonatomic)UIView *dbDetectionView;
@property(nonatomic)GeexDecibelHelper *dbHelper;
//音量波动视图
@property(nonatomic)UIView *dbFluctuateView;

//"开始录制"按钮
@property(nonatomic,strong)UIButton *recordButton;

//当前正在进行的状态  1：准备拍摄  2：拍摄中
@property(nonatomic,assign)NSInteger currentStip;

@property(nonatomic,assign)NSInteger timeSec;

@property(nonatomic,strong)UIImageView *countDownImage;

@property(nonatomic,strong) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property(nonatomic,strong) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property(nonatomic,strong) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

@property(nonatomic,strong) NSTimer *timer;

@property(nonatomic,copy) NSString *path;     //文件路径

@property(nonatomic)NSUInteger confirmTimeSec;
@end

//默认视频时长
static NSUInteger defaultVideoTime = 30;

@implementation GeexVideoRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = true;
    self.view.backgroundColor = [UIColor whiteColor];
    _currentStip = 1;
    
    //视频时长有值取值 无值取默认
    self.confirmTimeSec = self.customsTime ? : defaultVideoTime;
    
    //顶部自定义导航栏
    [self.view addSubview:self.customNavigationView];
    //视频捕获区域
    [self.view addSubview:self.containerView];
    //视频捕获区域加上一张人脸位置辅助的图片
    [self.view addSubview:self.videoAssistImage];
    //话术信息
    [self creatWordsView];
    //"开始录制"按钮
    [self.view addSubview:self.recordButton];
    
    //周围音量检测
    self.dbHelper = [[GeexDecibelHelper alloc]init];
    [self.view addSubview:self.dbDetectionView];
    //1秒后开始检测 此时才可点击“开始录制”
    [self performSelector:@selector(dbStart) withObject:nil afterDelay:1];
    //视频时长限制
    _timeSec = self.confirmTimeSec;
    //录制组件初始化
    [self initVideoConfig];
    //倒计时提示图片
    [self countDownLayout];
}

//"开始录制" 按钮事件
- (void)recButtonTap{
    if (!_cameraReady) {
        NSLog(@"录制组件尚未初始化");
        return;
    }
    NSLog(@"点击了开始/完成录制");
    
    if (_currentStip == 1) {
        //准备拍摄阶段 按下按钮开始拍摄
        [self.recordButton setTitle:@"完成录制" forState:UIControlStateNormal];
        self.recordButton.enabled = false;
        
        self.countDownImage.hidden = false;
        _secCount = 5;
        
        //先倒计时再进行录制
        [self performSelector:@selector(changeSecImage) withObject:nil afterDelay:1];
            
    }else if (_currentStip == 2){
        //正在拍摄阶段  按下按钮停止拍摄
        _currentStip = 2;
        //防连点
        self.recordButton.enabled = false;
        [self finishRecordVideo];
    }
    
}

- (void)dbStart{
    //音量检测
    [self.dbHelper startMeasuringWithIsSaveVoice:NO];
    [self dbConfig];
    //开始录制
    self.recordButton.enabled = true;
}

//倒计时事件
- (void)changeSecImage{
    if (_secCount == 1) {
        _secCount = 5;
        self.countDownImage.hidden = YES;
        self.countDownImage.image = [UIImage imageNamed:@"daojishi5"];
        
        self.customNavigationTitleLabel.text = [NSString stringWithFormat:@"00:00:%02ld",_timeSec];
        
        [self starRecordVideo];
        self.recordButton.enabled = YES;
    }else{
        _secCount--;
        NSString *imageName = [NSString stringWithFormat:@"daojishi%ld",_secCount];
        self.countDownImage.image = [UIImage imageNamed:imageName];
        [self performSelector:@selector(changeSecImage) withObject:nil afterDelay:1];
    }
}

//开始录制
- (void)starRecordVideo{
    
    //开始检测
    //[self.dbHelper startMeasuringWithIsSaveVoice:NO];
    
    [self removeTimer];
    //开始录制 进入录制中阶段
    _currentStip = 2;
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //如果支持多任务则则开始多任务
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }
    //预览图层和视频方向保持一致
    captureConnection.videoOrientation = [self.captureVideoPreviewLayer connection].videoOrientation;
    
    //添加路径
    _path = [self getPath];
    NSURL *fileUrl = [NSURL fileURLWithPath:_path];
    [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    
    //开始计时
    [self startTimer];
}

//完成录制
- (void)finishRecordVideo{
    
    //录制完成 进入准备录制阶段
    _currentStip = 1;
    //更新界面
    _timeSec = self.confirmTimeSec;
    //self.timerLabel.hidden = YES;
    self.customNavigationTitleLabel.text = @"视频认证";
    [self.recordButton setTitle:@"开始录制" forState:UIControlStateNormal];
    
    //移除音量监听
    //self.dbMainView.hidden = YES;
    //[self.dbHelper stopMeasuring];
    
    //结束录制
    [self stopVideoRecoding];

    //移除定时器
    [self removeTimer];
    
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    /********跳转放在录制完成的代理方法中执行*********/
//    PlayVideoVC *pc = [[PlayVideoVC alloc]init];
//    pc.videoPath = _path;
//    [self.navigationController pushViewController:pc animated:YES];
    
    //配置avplayer的item
    //[self setPlayerItem];
}

#pragma mark - 视频输出代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"视频录制完成.%@",outputFileURL);
    self.recordButton.enabled = true;
    GeexVideoConfirmVC *gc = [[GeexVideoConfirmVC alloc]init];
    gc.videoUrl = outputFileURL;
    
    __weak typeof(self) weakSelf = self;
    [gc setCompressBlcok:^(NSURL *compressVideoPath) {
        if (weakSelf.finishBlcok) {
            weakSelf.finishBlcok([NSString stringWithFormat:@"%@",compressVideoPath]);
        }
    }];
    [self.navigationController pushViewController:gc animated:true];
}


//启动定时器
- (void)startTimer{
    _timeSec = self.confirmTimeSec;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerAct) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
}

//定时器事件
- (void)timerAct{
    _timeSec--;
    NSLog(@"%ld",_timeSec);
    if (_timeSec == -1) {
        [self removeTimer];
        //修改步骤 重新设置按钮文字
        _currentStip = 1;
        [self finishRecordVideo];
        
    }else{
        if (_timeSec <= self.confirmTimeSec) {
            //
            self.customNavigationTitleLabel.text = [NSString stringWithFormat:@"00:00:%02ld",_timeSec];
        }
    }
}

//销毁定时器
- (void)removeTimer{
    [_timer invalidate];
    _timer = nil;
}
//结束录制
- (void)stopVideoRecoding{
    if ([self.captureMovieFileOutput isRecording]) {
        [self.captureMovieFileOutput stopRecording];
    }
}

//视频路径
- (NSString *)getPath{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", dateStr]];
    return path;
}

//视图将要消失
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
}
//视图消失  移除通知 销毁定时器
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopVideoRecoding];
    [self removeTimer];
    //[self removeBackGroundTimer];
    [self.dbHelper stopMeasuring];
    [self removeNotification];
    [self.captureSession stopRunning];
}


//视频拍摄相关组件初始化
- (void)initVideoConfig{
    _captureSession = [[AVCaptureSession alloc]init];
    //设置分辨率
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    //获得输入设备（前置摄像头）
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
    if (!captureDevice) {
        NSLog(@"取得前置置摄像头时出现问题");
        return;
    }
    //添加一个音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSError *error = nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@", error.localizedDescription);
        return;
    }
    AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@", error.localizedDescription);
        return;
    }
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    //不设置这个属性，超过10s的视频会没有声音
    _captureMovieFileOutput.movieFragmentInterval = kCMTimeInvalid;

    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }

    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    //摄像头方向
    AVCaptureConnection *captureConnection = [self.captureVideoPreviewLayer connection];
    captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    CALayer *layer = _containerView.layer;
    layer.masksToBounds = YES;
    
    _captureVideoPreviewLayer.frame = [[UIApplication sharedApplication].delegate window].frame;
    //填充模式
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //将视频预览层添加到界面中
    [layer insertSublayer:_captureVideoPreviewLayer below:nil];
    
    //拍摄准备完毕
    _cameraReady = YES;
    //捕获区域改变通知
    //[self addNotificationToCaptureDevice:captureDevice];
}

#pragma mark - 通知
//给输入设备添加通知
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}
//改变设备属性的统一操作方法
- (void)changeDeviceProperty:(void (^)(AVCaptureDevice *))propertyChange{
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@", error.localizedDescription);
    }
}
//捕获区域改变
- (void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变");
}
//移除通知
- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 私有方法
//取得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

//自定义导航栏
- (UIView *)customNavigationView{
    if (!_customNavigationView) {
        _customNavigationView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kStatusBarHeight + 44)];
        _customNavigationView.backgroundColor = [UIColor blackColor];
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:[UIImage imageNamed:@"shangyibu"] forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, kStatusBarHeight, 100, 44);
        [backButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
        [_customNavigationView addSubview:backButton];
        
        self.customNavigationTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(kScreenWidth/2-50, kStatusBarHeight, 100, 44)];
        self.customNavigationTitleLabel.text = @"视频录制";
        self.customNavigationTitleLabel.textColor = [UIColor whiteColor];
        self.customNavigationTitleLabel.textAlignment = NSTextAlignmentCenter;
        [_customNavigationView addSubview:self.customNavigationTitleLabel];
    }
    return _customNavigationView;
}

//视频捕获区域
- (UIView *)containerView{
    if (!_containerView) {
        _containerView = [[UIView alloc]initWithFrame:CGRectMake(0, _customNavigationView.frame.size.height, kScreenWidth, kScreenHeight - _customNavigationView.frame.size.height)];
    }
    return _containerView;
}

//视频人脸位置辅助视图
- (UIImageView *)videoAssistImage{
    if (!_videoAssistImage) {
        _videoAssistImage = [[UIImageView alloc]initWithFrame:self.containerView.frame];
        _videoAssistImage.image = [UIImage imageNamed:@"menban"];
    }
    return _videoAssistImage;
}

//显示话术信息
- (void)creatWordsView{
    if (!self.words) {
        return;
    }
    UIView *wordsMainView = [[UIView alloc]initWithFrame:CGRectMake(20, _customNavigationView.frame.size.height+5, kScreenWidth-40, 100)];
    //录制提示
    UILabel *tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth-40, 17)];
    tipLabel.font = [UIFont systemFontOfSize:13];
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.text = @"请点击开始录制，并用普通话大声朗读以下文字：";
    [wordsMainView addSubview:tipLabel];
    //话术信息内容
    UILabel *wordsLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 20, kScreenWidth-40, 90)];
    wordsLabel.text = self.words;
    wordsLabel.numberOfLines = 0;
    wordsLabel.textColor = [UIColor colorWithRed:246.0/255.0f green:199.0/255.0f blue:35.0/255.0f alpha:1];
    wordsLabel.font = [UIFont systemFontOfSize:15];
    [wordsLabel sizeToFit];
    [wordsMainView addSubview:wordsLabel];
    
    [self.view addSubview:wordsMainView];
}

//周围音量检测
- (UIView *)dbDetectionView{
    if (!_dbDetectionView) {
        _dbDetectionView = [[UIView alloc]initWithFrame:CGRectMake(kScreenWidth-50, kScreenHeight/2-100, 50, 100)];
        //“正常录音”提示
        UIImageView *imageTip = [[UIImageView alloc]initWithFrame:CGRectMake(-32, 90, 54, 20)];
        imageTip.image = [UIImage imageNamed:@"zhengchangluyin"];
        [_dbDetectionView addSubview:imageTip];
        
        //话筒icon
        UIImageView *imageIcon = [[UIImageView alloc]initWithFrame:CGRectMake(27, 182, 18, 18)];
        imageIcon.image = [UIImage imageNamed:@"yinliang"];
        [_dbDetectionView addSubview:imageIcon];
        
        //音量条背景
        UIView *dbBackView = [[UIView alloc]initWithFrame:CGRectMake(27, 0, 18, 177)];
        dbBackView.backgroundColor = [UIColor colorWithRed:102.0/255.0f green:102.0/255.0f blue:102.0/255.0f alpha:1];
        //音量波动视图
        self.dbFluctuateView = [[UIView alloc]initWithFrame:CGRectMake(0, 176, 18, 1)];
        self.dbFluctuateView.backgroundColor = [UIColor whiteColor];
        [dbBackView addSubview:self.dbFluctuateView];
        
        [_dbDetectionView addSubview:dbBackView];
    }
    return _dbDetectionView;
}
//周围环境音量变化 高度变化
- (void)dbConfig{
    __weak typeof(self) weakSelf = self;
    self.dbHelper.decibelMeterBlock = ^(double dbSPL){
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            //strongSelf.dbLabel.text = [NSString stringWithFormat:@"%.2lf",dbSPL];
            //strongSelf.dbHeight.constant = dbSPL*1.2;
            strongSelf.dbFluctuateView.frame = CGRectMake(0, 177-dbSPL*1.2, 18, dbSPL*1.2);
        });
    };
}


//“开始录制”按钮
- (UIButton *)recordButton{
    if (!_recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordButton.frame = CGRectMake(20, kScreenHeight-80, kScreenWidth - 40, 45);
        [_recordButton setTitle:@"开始录制" forState:UIControlStateNormal];
        [_recordButton setBackgroundImage:[UIImage imageNamed:@"recordButton"] forState:UIControlStateNormal];
        _recordButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _recordButton.layer.cornerRadius = 5;
        _recordButton.clipsToBounds = true;
        _recordButton.enabled = false;
        [_recordButton addTarget:self action:@selector(recButtonTap) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _recordButton;
}

- (void)countDownLayout{
    self.countDownImage = [[UIImageView alloc]initWithFrame:CGRectMake(kScreenWidth/2.0-60, kScreenHeight/2.0-80, 120, 120)];
    self.countDownImage.image = [UIImage imageNamed:@"daojishi5"];
    self.countDownImage.hidden = true;
    [self.view addSubview:self.countDownImage];
}

- (void)dealloc{
    NSLog(@"VideoManagerDealloc");
    self.dbHelper = nil;
    [self removeNotification];
}

- (void)dismissVC{
    [self removeNotification];
    [self dismissViewControllerAnimated:true completion:nil];
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
