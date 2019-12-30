//
//  ViewController.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/26.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "GeexVideoRecorder.h"

@interface ViewController () <WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>

@property(nonatomic,strong)WKWebView *webView;

// 注入JS脚本
@property (nonatomic, strong) NSArray *jsScripts;
@end

static NSString * const jsHandler = @"JSHandld";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //[self webView];
    [self creatButton];
}

- (void)awakeVideoRecorder{
    NSLog(@"唤起视频录制页面");
    [GeexVideoRecorder shared].videoTimes = 20;
    [[GeexVideoRecorder shared]startWithWords:@"123"
                                   controller:self
                                     callBack:^(NSString * compressVideoPath) {
        NSLog(@"视频压缩完成，路径为%@",compressVideoPath);
    }];
    
    //[self presentViewController:[[UINavigationController alloc]initWithRootViewController:[GeexVideoRecordVC new]] animated:true completion:nil];
}

- (void)creatButton{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20,  [UIScreen mainScreen].bounds.size.height/2-30,  [UIScreen mainScreen].bounds.size.width-40, 60);
    [button setTitle:@"点击录制视频" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(awakeVideoRecorder) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}



- (WKWebView *)webView{
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc]init];
        //允许使用内联本机播放器
        configuration.allowsInlineMediaPlayback = true;
        if (@available(iOS 10.0, *)) {
            configuration.mediaTypesRequiringUserActionForPlayback = false;
        }
        configuration.preferences = [[WKPreferences alloc]init];
        //最小字体
        //configuration.preferences.minimumFontSize = 10;
        //JavaScript 默认就是打开
        configuration.preferences.javaScriptEnabled = true;
        
        //默认是不能通过JS自动打开窗口的，必须铜鼓用户交互才能打开
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false;
        
        //通过JS与webView内容交互配置
        configuration.userContentController = [[WKUserContentController alloc]init];
        
        //可以通过configuration.userContentController注入JS
        for (NSString *jsScript in self.jsScripts) {
            WKUserScript *script = [[WKUserScript alloc]initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:true];
            [configuration.userContentController addUserScript:script];
        }
        
        //添加一个名称，就可以在JS通过这个名称发送消息
        [configuration.userContentController addScriptMessageHandler:self name:jsHandler];
        
        _webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) configuration:configuration];
        [self.view addSubview:_webView];
        
        _webView.allowsBackForwardNavigationGestures = true;
        self.webView.navigationDelegate = self;
        self.webView.UIDelegate = self;
        
    }
    return _webView;
}

//WKScriptMessageHandler  required
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
}

@end
