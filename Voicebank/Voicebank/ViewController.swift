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

    @IBOutlet weak var leftWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var rightWaveView: SwiftSiriWaveformView!
    
    var timer:Timer?
    
    
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
    
    @IBAction func recordTapped() {
        print("recordTapped")
        if (self.recorder != nil){
            if (!self.recorder.isRecording()) {
                self.recorder.startRecording()
                amplitudeDelta = 0.01
            } else {
                self.recorder.stopRecording()
                amplitudeDelta = -0.01
            }
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
}

