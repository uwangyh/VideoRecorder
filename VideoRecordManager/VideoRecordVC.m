//
//  VideoRecordVC.m
//  VideoRecordManager
//
//  Created by WangYonghe on 2019/12/26.
//  Copyright © 2019 WangYonghe. All rights reserved.
//

#import "VideoRecordVC.h"

@interface VideoRecordVC ()

@end

@implementation VideoRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = true;
    
    
    
    
}

- (void)creatBackView{
    if (kDevice_Is_iPhoneX()) {
        
    }
    
}



static inline BOOL kDevice_Is_iPhoneX(){
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    
    return iPhoneXSeries;
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
