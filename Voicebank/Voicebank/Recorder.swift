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
    var sentence: String = ""
    var viewController: ViewController!
    var recordingCanceled: Bool = false
    var audioPlayer:AVAudioPlayer!

    
    init(wsComm: WSComm!, viewController: ViewController!) {
        super.init()
        self.wsComm = wsComm
        self.recordingSession = AVAudioSession.sharedInstance()
        self.viewController = viewController
        
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
    
    func stopRecording(recordingCanceled: Bool) {
        self.recordingCanceled = recordingCanceled
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
        if (!self.recordingCanceled){
            if flag {
                self.wsComm.uploadAudio(audioFile: self.audioFilename, sentence: self.sentence, completion: {(data : Data?, urlresponse: URLResponse?, error: Error?) -> Void in
                    self.viewController.showToast("Audio uploaded")
                    self.viewController.showRandomQuote()
                })
            }
        } else {
            self.viewController.fadeCancel(startAlpha: 1, endAlpha: 0, showToast: true)
        }
    }
    
    func playSound(_ sound: String) {
        let audioFilePath = Bundle.main.path(forResource: sound, ofType: "wav")
        if audioFilePath != nil {
            let audioFileUrl = NSURL.fileURL(withPath: audioFilePath!)
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: audioFileUrl)
                audioPlayer.play()
            } catch {
                print("Error Playing Audio Clip")
            }
        } else {
            print("Audio file is not found")
        }
    }
    
}
