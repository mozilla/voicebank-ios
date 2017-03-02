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
    
    @IBOutlet weak var leftWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var rightWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var textView: UITextView!
    
    var timer:Timer?
    
    let quotes = [
        "“Don't cry because it's over, smile because it happened.” ― Dr. Seuss",
        "“Never put off till tomorrow what may be done day after tomorrow just as well.” ― Mark Twain",
        "“Be yourself; everyone else is already taken.” ― Oscar Wilde",
        "“You only live once, but if you do it right, once is enough.” ― Mae West",
        "“No one can make you feel inferior without your consent.” ― Eleanor Roosevelt, This is My Story",
        "“Live as if you were to die tomorrow. Learn as if you were to live forever.” ― Mahatma Gandhi"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        recorder = Recorder()
        startWaveView()
        recordButton.delegate = self
        
        // Flip the view around.
        self.leftWaveView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        // Center record button.
        let mid = self.view.bounds.width / 2.0
        recordButton.center = CGPoint(x: mid, y: recordButton.center.y)
    
        showRandomQuote()
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
        showText(quotes[Int(arc4random_uniform(UInt32(quotes.count)))])
    }
    
    var isRecording = false
    @IBAction func recordTapped() {
        if isRecording {
            amplitudeDelta = -0.01
            showRandomQuote()
            playSound("fuzz")
        } else {
            amplitudeDelta = 0.01
            playSound("fuzz")
        }
        isRecording = !isRecording
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
    
    internal func waveViewTick(_:Timer) {
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
                let newAmplitudeMultiplier = 1 + avgValue * 100
                self.amplitudeMultiplier += (newAmplitudeMultiplier - self.amplitudeMultiplier) * 0.2
            }
        }
        try! engine.start()
    }
    
    func playSound(_ sound: String) {
        let audioFilePath = Bundle.main.path(forResource: sound, ofType: "mp3")
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

