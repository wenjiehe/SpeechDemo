# SpeechDemo

## 简介

> 对现场或预先录制的音频进行语音识别,并接收回调的结果。

## SDKs

* iOS 10.0+
* macOS 10.15+
* Mac Catalyst 13.0+

## 运行环境

* Xcode 11.5
* iOS 10.0及以上

## 工程配置

工程中必须在Info.plist文件中添加以下键值，否则会崩溃

```Objective-C
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>音吧需要使用语音识别功能来为您服务</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>音吧需要使用麦克风来为您服务</string>
```

## API介绍

```Objective-C

    #import <Speech/SFVoiceAnalytics.h> //录制音频的语音分析类
    #import <Speech/SFSpeechRecognitionResult.h> //请求结果类
    #import <Speech/SFSpeechRecognitionRequest.h> //请求类，包含处理现有音频和音频流的请求类
    #import <Speech/SFSpeechRecognitionTask.h> //监控语音识别进程的任务对象类
    #import <Speech/SFSpeechRecognitionTaskHint.h> //语音识别的任务类型
    #import <Speech/SFSpeechRecognizer.h> //用于检查语音识别服务的可用性并启动语音识别过程的对象。
    #import <Speech/SFTranscriptionSegment.h> //语音识别转换信息的一小段，由speech Recognizer提供
    #import <Speech/SFTranscription.h> //由speech Recognizer给定的语音的完整文本表示

```

```Objective-C
typedef NS_ENUM(NSInteger, SFSpeechRecognizerAuthorizationStatus) {
    SFSpeechRecognizerAuthorizationStatusNotDetermined,
    //用户已授权
    SFSpeechRecognizerAuthorizationStatusDenied,
    //用户已拒绝
    SFSpeechRecognizerAuthorizationStatusRestricted,
    //该设备限制语音识别服务
    SFSpeechRecognizerAuthorizationStatusAuthorized,
    //没有授权
} API_AVAILABLE(ios(10.0), macos(10.15));
```

```Objective-C
typedef NS_ENUM(NSInteger, SFSpeechRecognitionTaskState) {
    SFSpeechRecognitionTaskStateStarting = 0,       
    /*
        Speech processing (potentially including recording) has not yet begun
        语音处理(可能包括录音)还没有开始
    */
    SFSpeechRecognitionTaskStateRunning = 1,        
    /*
        Speech processing (potentially including recording) is running
        语音处理(可能包括录音)正在运行
    */
    SFSpeechRecognitionTaskStateFinishing = 2,      
    /*
        No more audio is being recorded, but more recognition results may arrive
        没有更多的音频被记录，但更多的识别结果可能到达
    */
    SFSpeechRecognitionTaskStateCanceling = 3,      
    /*
        No more recognition reuslts will arrive, but recording may not have stopped yet
        没有更多的识别重新到达，但录音可能还没有停止
    */
    SFSpeechRecognitionTaskStateCompleted = 4,      
    /*
        No more results will arrive, and recording is stopped.
        没有更多的结果将到达，记录将停止。
    */
} API_AVAILABLE(ios(10.0), macos(10.15));
```

```Objective-C
typedef NS_ENUM(NSInteger, SFSpeechRecognitionTaskHint) {
    SFSpeechRecognitionTaskHintUnspecified = 0,     
    /* 
        Unspecified recognition
        未指定的任务类型。
    */
    SFSpeechRecognitionTaskHintDictation = 1,       
    /* 
        General dictation/keyboard-style
        使用捕获的语音进行文本输入的任务。
    */
    SFSpeechRecognitionTaskHintSearch = 2,
    /*
        Search-style requests
        使用捕获的语音来指定搜索术语的任务。
    */
    SFSpeechRecognitionTaskHintConfirmation = 3,    
    /*
        Short, confirmation-style requests ("Yes", "No", "Maybe")
        捕获的语音用于简短的、确认式的请求。
    */
} API_AVAILABLE(ios(10.0), macos(10.15));
```

```Objective-C
typedef NS_ENUM(NSInteger, AVSpeechBoundary) {
    AVSpeechBoundaryImmediate, //立刻停止
    AVSpeechBoundaryWord       //读完最后一个字停止
} NS_ENUM_AVAILABLE(10_14, 7_0);
```

```Objective-C
@property(nonatomic) NSTimeInterval preUtteranceDelay;    // Default is 0.0  读一段话之前的停顿
@property(nonatomic) NSTimeInterval postUtteranceDelay;   // Default is 0.0  读完一段后的停顿时间
```

```Objective-C
- (BOOL)stopSpeakingAtBoundary:(AVSpeechBoundary)boundary; //停止播放语音
- (BOOL)pauseSpeakingAtBoundary:(AVSpeechBoundary)boundary; //暂停播放语音
- (BOOL)continueSpeaking; //继续播放语音
```

## 注意事项

* Speech框架必须iOS 10.0以后才能使用，包含10.0
* 现有音频文件使用SFSpeechURLRecognitionRequest对象,音频流使用SFSpeechAudioBufferRecognitionRequest对象
* 语音识别不能超过一分钟


## 参考资料

[官网speech](https://developer.apple.com/documentation/speech)

[AVAudioEngine资料](https://www.jianshu.com/p/506c62183763)

[Languages supported by VoiceOver](https://support.apple.com/en-us/HT206175)
