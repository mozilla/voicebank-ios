//
//  Recording.swift
//  Voicebank
//
//  Created by Andre Natal on 2/22/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import AVFoundation
import Speech

class Recorder:  NSObject, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var permission_granted = false
    var audioRecorder: AVAudioRecorder!
    var wsComm: WSComm!
    var sentence: String = ""
    var viewController: ViewController!
    var recordingCanceled: Bool = false
    var audioPlayer:AVAudioPlayer!
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    var siriEnabled = false
    var hashSentences: [String: Sentence] = [:]
    var currentsentenceHash: String = ""
    
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
                    } else {
                        self.permission_granted = false
                    }
                }
            }
            
            SFSpeechRecognizer.requestAuthorization { (authStatus) in
                
                switch authStatus {
                    case .authorized:
                        self.siriEnabled = true
                    case .denied:
                        self.siriEnabled = false
                        print("User denied access to speech recognition")
                    case .restricted:
                        self.siriEnabled = false
                        print("Speech recognition restricted on this device")
                    case .notDetermined:
                        self.siriEnabled = false
                        print("Speech recognition not yet authorized")
                }
                
                OperationQueue.main.addOperation() {
                }
            }
            
        } catch {
            // failed to record!
        }
    }
    
    func createRecorder() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.audioRecorder = try AVAudioRecorder(url:  (hashSentences[self.currentsentenceHash]?.audioFilename)!, settings: settings)
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
    
    func finishRecording() {
        NSLog("Finished Recording")
    }
    
    func isRecording() -> Bool {
        return self.audioRecorder.isRecording
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if (!self.recordingCanceled){
            if flag {
                let _sentenceHash = self.currentsentenceHash
                recognizeFile(sentenceHash: _sentenceHash, completion: {(STT: String) -> Void in
                    self.hashSentences[_sentenceHash]?.sentenceSTT = STT
                    self.wsComm.uploadAudio(sentence: self.hashSentences[_sentenceHash]!, completion: {(data : Data?, urlresponse: URLResponse?, error: Error?) -> Void in
                        print("upload completed");
                    })
                })
                
                self.viewController.showRandomQuote()
                self.viewController.countRecording()
            }
        } else {
            self.viewController.fadeCancel(startAlpha: 1, endAlpha: 0, showToast: true)
        }
    }
    
    func setSentence(sentence: String) {
        let sentenceObj = Sentence(sentence: sentence)
        hashSentences[sentenceObj.sentenceHash] = sentenceObj
        currentsentenceHash = sentenceObj.sentenceHash
        self.createRecorder()
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
    
    func recognizeFile(sentenceHash: String, completion: @escaping (String) -> Void) {
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            return
        }
        
        if !myRecognizer.isAvailable {
            // The recognizer is not available right now
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: (hashSentences[self.currentsentenceHash]?.audioFilename)! as URL)
        request.shouldReportPartialResults = false

        myRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                completion("STT Error:\(error?.localizedDescription)")
                print("STT Error:\(error?.localizedDescription)")
                // Recognition failed, so check error for details and handle it
                return
            }
            
            if result.isFinal {
                // Print the speech that has been recognized so far
                completion("STT:\(result.bestTranscription.formattedString)")
            }
        }}
    
}


class Sentence {
    
    func getDocsFolder() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    init(sentence: String) {
        self.sentence = sentence;
        self.sentenceHash = sentence.digest(length: CC_SHA1_DIGEST_LENGTH, gen: {(data, len, md) in CC_SHA1(data,len,md)})
        self.audioFilename = getDocsFolder().appendingPathComponent("\(sentenceHash).m4a")
    }
    
    var sentence: String = ""
    var sentenceHash: String = ""
    var sentenceSTT: String = ""
    var audioFilename: URL!
}


