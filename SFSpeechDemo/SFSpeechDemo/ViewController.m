//
//  ViewController.m
//  SFSpeechDemo
//
//  Created by 贺文杰 on 2020/6/26.
//  Copyright © 2020 贺文杰. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>

@interface ViewController ()<SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest *abRequest;
@property(nonatomic,strong)SFSpeechRecognitionTask *sprTask;
@property(nonatomic,strong)SFSpeechRecognizer *spR;
@property(nonatomic)BOOL isAuthorized;
@property(nonatomic,strong)AVAudioSession *audioSession;
@property(nonatomic,strong)AVAudioEngine *audioEngine;
@property(nonatomic,strong)AVSpeechSynthesizer *speechSynthesizer; //语音合成器

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
    _isAuthorized = false;
    self.spR = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    self.spR.delegate = self;
    
    for (NSLocale *locale in [SFSpeechRecognizer supportedLocales]) {
        NSLog(@"countryCode = %@, languageCode = %@, 语言 = %@", locale.countryCode, locale.languageCode, [locale localizedStringForLanguageCode:locale.languageCode]);
    }
    
    //该方法为异步方法,用户第一次使用语音识别服务时，系统会记录用户的选择，之后的请求会立即返回之前记录的结果
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
            {
                self->_isAuthorized = true;
                //用户已授权
                NSLog(@"用户已授权");
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
- (IBAction)speechRecognizerUrl:(id)sender {
    SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"xiangchou.mp3" withExtension:nil];
    NSAssert(url, @"语音文件初始化失败");
    SFSpeechURLRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    request.taskHint = SFSpeechRecognitionTaskHintConfirmation;
    if (@available(iOS 13.0, *)) {
        request.requiresOnDeviceRecognition = NO;
    }else{
        
    }
    [recognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error = %@", error);
            return;
        }
        if (result.isFinal) {
            NSLog(@"识别文字结束 = %@", result.bestTranscription.formattedString);
            self.textView.text = result.bestTranscription.formattedString;
        }
        NSLog(@"formattedString = %@\n", result.bestTranscription.formattedString);
    }];
}

- (IBAction)startRecording:(id)sender {
    if (_isAuthorized) {
        if (self.sprTask) {
            if (self.sprTask.state == SFSpeechRecognitionTaskStateRunning) { //当前进程是进行中
                [self.audioEngine stop];
                [self.abRequest endAudio];
            }
            [self.sprTask cancel];
            self.sprTask = nil;
            NSLog(@"结束录制音频");
            return;
        }else{
            self.audioSession = [AVAudioSession sharedInstance];
            self.audioEngine = [[AVAudioEngine alloc] init]; //管理所有的音频节点

            NSError *error = nil;
            [self.audioSession setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:&error];
            NSParameterAssert(!error);
            NSError *activeError= nil;
            [self.audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&activeError];
            NSParameterAssert(!activeError);
            self.abRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
            self.abRequest.shouldReportPartialResults = true; //每产生一种结果就马上返回
            if (@available(iOS 13.0, *)) {
                self.abRequest.requiresOnDeviceRecognition = NO; //只用本地识别
            } else {
            }
            NSAssert(self.abRequest, @"SFSpeechAudioBufferRecognitionRequest初始化失败");
            
            //代理方式
//            self.sprTask = [self.spR recognitionTaskWithRequest:self.abRequest delegate:self];
            
            //block回调方式
            self.sprTask = [self.spR recognitionTaskWithRequest:self.abRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                BOOL isFinal = false;
                if (result) {
                    NSLog(@"result = %@", result);
                    self.textView.text = result.bestTranscription.formattedString;
                    isFinal = result.isFinal;
                }

                if (error || isFinal) {
                    [self.audioEngine stop];
                    [self.audioEngine.inputNode removeTapOnBus:AVAudioPlayerNodeBufferLoops];
                    self.abRequest = nil;
                    self.sprTask = nil;
                }
            }];
            
            [self.audioEngine.inputNode removeTapOnBus:AVAudioPlayerNodeBufferLoops];
            AVAudioFormat *format = [self.audioEngine.inputNode outputFormatForBus:AVAudioPlayerNodeBufferLoops];
            [self.audioEngine.inputNode installTapOnBus:AVAudioPlayerNodeBufferLoops bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                [self.abRequest appendAudioPCMBuffer:buffer];
            }];
            
            [self.audioEngine prepare];
            [self.audioEngine startAndReturnError:nil];
            NSError *startError = nil;
            if ([self.audioEngine startAndReturnError:&startError]) {
                NSLog(@"开始录制音频");
            }else{
                NSLog(@"开始录制音频失败 error = %@", startError);
            }
            NSParameterAssert(!startError);
        }
    }
}

#pragma mark -- SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available
{
    if (available) { //检查语音识别服务是否可以对当前语音使用，否则需要联网
        
    }
}

#pragma mark -- SFSpeechRecognitionTaskDelegate
// Called when the task first detects speech in the source audio
//当任务第一次在源音频中检测到语音时调用
- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task
{
    
}

// Called for all recognitions, including non-final hypothesis
//当识别出一条可用的信息后 会调用,需要注意，apple的语音识别服务会根据提供的音频源识别出多个可能的结果 每有一条结果可用 都会调用此方法
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription
{
    
}

// Called only for final recognitions of utterances. No more about the utterance will be reported
//当识别完成所有可用的结果后调用
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult
{
    if (recognitionResult) {
        self.textView.text = recognitionResult.bestTranscription.formattedString;
    }
}

// Called when the task is no longer accepting new audio but may be finishing final processing
//当不再接受音频输入时调用 即开始处理语音识别任务时调用
- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task
{
    
}

// Called when the task has been cancelled, either by client app, the user, or the system
//当语音识别任务被取消时调用
- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task
{
    
}

// Called when recognition of all requested utterances is finished.
// If successfully is false, the error property of the task will contain error information
//语音识别任务完成时被调用
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully
{
    
}


@end
