//
//  ViewController.m
//  SFSpeechDemo
//
//  Created by 贺文杰 on 2020/6/26.
//  Copyright © 2020 贺文杰. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h> //管理语音识别过程的上下文对象

@interface ViewController ()<SFSpeechRecognizerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self speechRecognizer];
}

/*
    注意事项:
    1.Speech框架必须iOS 10.0以后才能使用，包含10.0
    2.现有音频文件使用SFSpeechURLRecognitionRequest对象,音频流使用SFSpeechAudioBufferRecognitionRequest对象
    3.语音识别不能超过一分钟
 
    流程:
    1.请求语音识别的授权
      在plist文件中增加keyNSSpeechRecognitionUsageDescription,不然会崩溃
    2.创建SFSpeechRecognizer对象
    3.根据isAvailable属性检查语音识别服务是否可以对当前语音使用
    4.准备音频内容
    5.创建一个请求识别对象（SFSpeechRecognitionRequest）
    6.调用recognitionTask(with:delegate:) 或者 recognitionTask(with:resultHandler:) 方法开始识别过程
 */

- (void)speechRecognizer
{
    SFSpeechRecognizer *spR = [[SFSpeechRecognizer alloc] init];
    spR.delegate = self;
    
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        NSLog(@"languageCode = %@", locale.languageCode);
    }

    //该方法为异步方法,用户第一次使用语音识别服务时，系统会记录用户的选择，之后的请求会立即返回之前记录的结果
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
            {
                //用户已授权
                NSLog(@"用户已授权");
                if (spR.isAvailable) { //检查语音识别服务是否可以对当前语音使用，否则需要联网
                    SFSpeechAudioBufferRecognitionRequest *rRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
                    [spR recognitionTaskWithRequest:rRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                        if (result) {
                            NSLog(@"result = %@", result);
                        }
                    }];
                }
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
            {
                //用户已拒绝
                NSLog(@"用户已拒绝");
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
            {
                //该设备限制语音识别服务
                NSLog(@"该设备限制语音识别服务");
            }
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
            {
                //语音识别没有授权
                NSLog(@"语音识别没有授权");
            }
                break;
            default:
                break;
        }
    }];
}

#pragma mark -- SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available
{
    if (available) { //检查语音识别服务是否可以对当前语音使用，否则需要联网
        
    }
}


@end
