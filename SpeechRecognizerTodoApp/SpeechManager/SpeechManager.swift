//
//  SpeechManager.swift
//  SpeechRecognizerTodoApp
//
//  Created by ramil on 28.12.2020.
//

import Foundation
import Speech

class SpeechManager {
    public var isRecording = false
    
    private var audionEngine: AVAudioEngine!
    private var inputNote: AVAudioInputNode!
    private var audioSession: AVAudioSession!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    func checkPermission() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized: break
                default:
                    print("Speech recognition is not available")
                }
            }
        }
    }
    
    func start(completion: @escaping (String?) -> Void) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(completion: completion)
        }
    }
    
    func startRecording(completion: @escaping (String?) -> Void) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            print("Speech recognizer is not available")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest!.shouldReportPartialResults = true
        
        recognizer.recognitionTask(with: recognitionRequest!) { (result, error) in
            guard error == nil else {
                print("got error \(error!.localizedDescription)")
                return
            }
            
            guard let result = result else { return }
            
            if result.isFinal {
                completion(result.bestTranscription.formattedString)
            }
        }
        
        audionEngine = AVAudioEngine()
        inputNote = audionEngine.inputNode
        let recordingFormat = inputNote.outputFormat(forBus: 0)
        inputNote.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        audionEngine.prepare()
        
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audionEngine.start()
        } catch {
            print(error)
        }
    }
    
    func stopRecording() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audionEngine.stop()
        inputNote.removeTap(onBus: 0)
        
        try? audioSession.setActive(false)
        audioSession = nil
    }
}
