//
//  ViewController.swift
//  Voicebank
//
//  Created by Andre Natal on 2/17/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class ViewController: UIViewController, LongPressRecordButtonDelegate {

    // @IBOutlet var recordButton: UIButton!
    @IBOutlet weak var recordButton: LongPressRecordButton!
    var recorder: Recorder!
    var engine:AVAudioEngine = AVAudioEngine()
    var audioPlayer:AVAudioPlayer!
    var wsComm : WSComm!
    var jsonSentences : Any?
    
    @IBOutlet weak var leftWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var rightWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var textView: UITextView!
    
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startWaveView()
        recordButton.delegate = self
        
        // Flip the view around.
        self.leftWaveView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        // Center record button.
        let mid = self.view.bounds.width / 2.0
        recordButton.center = CGPoint(x: mid, y: recordButton.center.y)
        
        self.wsComm = WSComm()
        // first we download the sentences
        self.wsComm.getSentences(completion: {(data : Data?, urlresponse: URLResponse?, error: Error?) -> Void in
            // then we parse it
            if ((data) != nil) {
                self.jsonSentences = try? JSONSerialization.jsonObject(with: data!, options: [])
                // and show the first sentence
                self.showRandomQuote()
            }
        })
        recorder = Recorder(wsComm: self.wsComm, viewController: self)
        
        // we add the swipes here
        
        // first to the left
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.viewSwipped(gesture:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        // and then to the right
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.viewSwipped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    func viewSwipped(gesture: UIGestureRecognizer) {
        if gesture.view != nil {
            if ((gesture as! UISwipeGestureRecognizer).direction == UISwipeGestureRecognizerDirection.right) {
                NSLog("text view swipped right")
                showRandomQuote()
            } else {
                NSLog("text view swipped left")
                showRandomQuote()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func longPressRecordButtonDidStartLongPress(_ button: LongPressRecordButton) {
        recordTapped()
    }
    
    func longPressRecordButtonDidStopLongPress(_ button: LongPressRecordButton) {
        recordTapped()
    }
    
    func showRandomQuote() {
        if let dictionary = self.jsonSentences as? NSDictionary {
            let sentenceKey = "s\(String(format: "%04d", Int(arc4random_uniform(UInt32(dictionary.count)))))"
            if let sentence = dictionary[sentenceKey] as? String {
                // display the sentence
                showText(sentence)
                // set the sentencekey to the recorder
                recorder.sentenceKey = sentenceKey
            }
        }
    }
    
    @IBAction func recordTapped() {
        if !self.recorder.isRecording() {
            NSLog("start recording")
            startWave()
            playSound("click3")
            recorder.startRecording()
        } else {
            NSLog("stop recording")
            stopWave()
            recorder.stopRecording()
            playSound("click2")
        }
    }
    
    func startWave() {
        amplitudeDelta = 0.01
        self.leftWaveView.waveColor = UIColor.red
        self.rightWaveView.waveColor = UIColor.red
    }
    
    func stopWave() {
        amplitudeDelta = -0.01
        self.leftWaveView.waveColor = UIColor.white
        self.rightWaveView.waveColor = UIColor.white
    }
    
    func showText(_ text: String) {
        let duration = 0.2
        UIView.animate(withDuration: duration, animations: {
            self.textView.alpha = 0
        }) {
            (finished) in
            self.textView.text = text
            UIView.animate(withDuration: duration, animations: {
                self.textView.alpha = 1
            })
        }
    }
    
    var amplitude:Float = 0
    var amplitudeDelta:Float = 0
    var amplitudeMultiplier:Float = 1
    var newAmplitudeMultiplier:Float = 1
    
    internal func waveViewTick(_:Timer) {
        self.amplitudeMultiplier += (newAmplitudeMultiplier - self.amplitudeMultiplier) * 0.2
        amplitude = Float.maximum(0, Float.minimum(amplitude + amplitudeDelta, 0.1))
        let value = CGFloat(amplitude * amplitudeMultiplier)
        self.leftWaveView.amplitude = value
        self.rightWaveView.amplitude = value
    }
    
    func stopWaveViewTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startWaveView() {
        timer = Timer.scheduledTimer(timeInterval: 0.013, target: self, selector: #selector(ViewController.waveViewTick(_:)), userInfo: nil, repeats: true)
        
        let input = engine.inputNode!
        input.installTap(onBus: 0, bufferSize: 0, format: input.inputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            if let floatChannelData = buffer.floatChannelData {
                let stride = buffer.stride
                let length = Int(buffer.frameLength)
                var avgValue: Float = 0
                vDSP_meamgv(floatChannelData.pointee, stride, &avgValue, vDSP_Length(length))
                self.newAmplitudeMultiplier = 1 + avgValue * 100
            }
        }
        try! engine.start()
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

