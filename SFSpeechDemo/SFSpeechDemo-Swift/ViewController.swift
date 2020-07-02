//
//  ViewController.swift
//  SFSpeechDemo-Swift
//
//  Created by 贺文杰 on 2020/6/29.
//  Copyright © 2020 贺文杰. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer.init()
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var playRecordButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var picSlider: UISlider!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var volumeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self.recordButton.isEnabled = true
                
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("用户已拒绝", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("该设备限制语音识别服务", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("语音识别没有授权", for: .disabled)
                    
                default:
                    self.recordButton.isEnabled = false
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("初始化SFSpeechAudioBufferRecognitionRequest对象失败") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordButton.isEnabled = true
                self.recordButton.setTitle("开始录制", for: [])
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func playSpeech(_ content: String, _ language: String){
        try? AVAudioSession.sharedInstance().setActive(true, options: .init())
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let spe = AVSpeechUtterance.init(string: content)
        spe.pitchMultiplier = self.picSlider.value
        spe.rate = self.rateSlider.value
        spe.volume = self.volumeSlider.value
        spe.postUtteranceDelay = 0.4
        spe.preUtteranceDelay = 0.3
        
        let spVoice = AVSpeechSynthesisVoice.init(language: language)
        spe.voice = spVoice
        
        self.speechSynthesizer.delegate = self
        self.speechSynthesizer.speak(spe)
        
    }
    @IBAction func clickPlaySpeech(_ sender: Any) {
        playSpeech(self.textView.text, "zh-CN")
    }
    
    @IBAction func clickPlayRecordButton(_ sender: Any) {
        guard let path = Bundle.main.path(forResource: "xiangchou", ofType: "mp3")  else {
            fatalError("初始化路径失败")
        }
        let speechR = SFSpeechURLRecognitionRequest.init(url: URL.init(fileURLWithPath: path))
        speechRecognizer.recognitionTask(with: speechR) { (result, error) in
            var isFinal = false
            if let result = result {
                // Update the text view with the results.
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            if error != nil || isFinal {
                print("结束了")
            }
        }
    }
    
    @IBAction func clickRecordButton(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("停止录制", for: .disabled)
        } else {
            do {
                try startRecording()
                recordButton.setTitle("停止录制", for: [])
            } catch {
                recordButton.setTitle("当前不支持语音识别", for: [])
            }
        }
    }
    
    // MARK:SFSpeechRecognizerDelegate
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("开始录制", for: [])
        }else{
            recordButton.isEnabled = false
            recordButton.setTitle("当前不支持语音识别", for: .disabled)
        }
    }
    
    // MARK:AVSpeechSynthesizerDelegate
    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance){
        
    }

    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        
    }

    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance){
        
    }

    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance){
        
    }

    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance){
        
    }

    
    @available(iOS 7.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance){
        
    }
    
}

