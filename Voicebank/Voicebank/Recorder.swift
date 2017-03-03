//
//  Recording.swift
//  Voicebank
//
//  Created by Andre Natal on 2/22/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import AVFoundation

class Recorder:  NSObject, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var permission_granted = false
    var audioRecorder: AVAudioRecorder!
    var audioFilename: URL!
    var wsComm: WSComm!
    var sentenceKey: String = ""
    
    init(wsComm: WSComm!) {
        super.init()
        self.wsComm = wsComm
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try self.recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try self.recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.permission_granted = true
                        self.createRecorder()
                    } else {
                        self.permission_granted = false
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    func createRecorder() {
        self.audioFilename = getDocsFolder().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.audioRecorder = try AVAudioRecorder(url: self.audioFilename, settings: settings)
            self.audioRecorder.delegate = self
            
        } catch {
            //finishRecording(success: false)
            NSLog("Error Recording")
        }
    }
    
    func startRecording() {
        self.audioRecorder.record()
    }
    
    func stopRecording() {
        self.audioRecorder.stop()
    }
    
    func getDocsFolder() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func finishRecording() {
        NSLog("Finished Recording")
    }
    
    func isRecording() -> Bool {
        return self.audioRecorder.isRecording
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            // show the toast with the counter
            self.wsComm.uploadAudio(audioFile: self.audioFilename, sentenceKey: self.sentenceKey)
        }
    }
    
    
}
