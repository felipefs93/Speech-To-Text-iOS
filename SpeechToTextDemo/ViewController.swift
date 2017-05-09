//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Felipe Soares on 28/04/17.
//  Copyright © 2017 Felipe Soares. All rights reserved.
//

import UIKit
import Speech


class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "pt-BR"))  //1
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        microphoneButton.isEnabled = false //2
        speechRecognizer?.delegate = self //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in //4
            var isButtonEnabled = false
            
            switch authStatus{
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecording(){
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else{
            fatalError("Audio engine has no input mode")
        }
        
        guard let recognitionRequest = recognitionRequest else{
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil{
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal{
                self.audioEngine.stop()
                print(result?.bestTranscription.formattedString)
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
                print("ativa de novo")
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do{
            try audioEngine.start()
        }catch{
            print("audio couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }

    @IBAction func microphoneTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }

    @IBAction func hold(_ sender: UIButton) {
        print("down")
        startRecording()
        microphoneButton.setTitle("Stop Recording", for: .normal)
    }
    
    @IBAction func release(_ sender: UIButton) {
        print("up inside")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        microphoneButton.isEnabled = false
        microphoneButton.setTitle("Start Recording", for: .normal)
    }
    
    @IBAction func release2(_ sender: UIButton) {
        print("up outside")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        microphoneButton.isEnabled = false
        microphoneButton.setTitle("Start Recording", for: .normal)
    }
    
    
    

    
    
}

