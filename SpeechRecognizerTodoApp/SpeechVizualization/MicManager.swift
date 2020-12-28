//
//  MicManager.swift
//  SpeechRecognizerTodoApp
//
//  Created by ramil on 28.12.2020.
//

import Foundation
import AVFoundation

class MicMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    @Published public var soundSample: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples > 0 ? numberOfSamples : 10
        self.soundSample = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (success) in
                if !success {
                    fatalError("We need audio recording for visualization")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.soundSample[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
    }
    
    public func stopMonitoring() {
        audioRecorder.stop()
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}
