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

    var recorder: Recorder!
    var engine: AVAudioEngine = AVAudioEngine()
    var wsComm: WSComm!
    var jsonSentences: Any?
    var recordingCanceled: Bool = false
    var dataViewController: UIViewController? = nil
    
    @IBOutlet weak var labelCount: UILabel!
    @IBOutlet weak var recordButton: LongPressRecordButton!
    @IBOutlet weak var toastView: UILabel!
    @IBOutlet weak var leftWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var rightWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var cancelView : UILabel!
    
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
        
        // Center cancel view
        cancelView.center = CGPoint(x: mid, y: recordButton.center.y)
        
        // align toast to the bottom
        toastView.frame.origin.y = self.view.frame.size.height - 30
        var newFrame = self.toastView.frame;
        newFrame.size.width = self.view.bounds.width
        toastView.frame = newFrame
        
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
        
        // create DataViewController if required
        if  UserDefaults.standard.string(forKey: "userDetails") == nil {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            dataViewController = mainStoryboard.instantiateViewController(withIdentifier: "data") as UIViewController
            (dataViewController as! DataViewController).startPickers()
        }
        
        // display the current total of recordings
        self.loadRecording()
    }
    
    func switchToDataVC() {
        self.present(dataViewController!, animated: true, completion: nil)
    }
    
    func viewSwipped(gesture: UIGestureRecognizer) {
        if gesture.view != nil {
            if ((gesture as! UISwipeGestureRecognizer).direction == UISwipeGestureRecognizerDirection.right) {
                showRandomQuote()
            } else {
                showRandomQuote()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func longPressRecordButtonDidStartLongPress(_ button: LongPressRecordButton) {
        recordingCanceled = false
        recordTapped()
    }
    
    func longPressRecordButtonDidStopLongPress(_ button: LongPressRecordButton) {
        recordTapped()
    }
    
    func cancelRecording(){
        stopWave()
    }
    
    func longPressRecordButtonDidDrag(_ button: LongPressRecordButton, gesture: UIPanGestureRecognizer, originPress: CGPoint){
        let gestureLocationInView = gesture.location(in: self.view)
        if (!recordButton.frame.contains(gestureLocationInView))  {
            self.fadeCancel(startAlpha: 0, endAlpha: 1.0, showToast: false)
            recordingCanceled = true
        } else {
            self.fadeCancel(startAlpha: 1, endAlpha: 0, showToast: false)
            recordingCanceled = false
        }
    }
    
    func shouldAskInfo() -> Bool {
        if (UserDefaults.standard.integer(forKey: "totalRecordings") > 5) && (UserDefaults.standard.string(forKey: "userDetails") == nil) {
            return true
        } else {
            return false
        }
    }
    
    func showRandomQuote() {
        if (self.shouldAskInfo()){
            switchToDataVC()
        }
        if let dictionary = self.jsonSentences as? NSDictionary {
            let sentenceid = Int(arc4random_uniform(UInt32(dictionary.count)))
            if let sentence = dictionary[String(sentenceid)] as? String {
                // display the sentence
                showText(sentence)
                // now we generate sentence hash an pass it to the recorder
                recorder.sentence = sentence
            }
        }
    }
    
    @IBAction func recordTapped() {
        if !self.recorder.isRecording() {
            startWave()
            recorder.playSound("click3")
            recorder.startRecording()
        } else {
            stopWave()
            recorder.stopRecording(recordingCanceled: recordingCanceled)
            recorder.playSound("click2")
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
    
    func fadeCancel(startAlpha: CGFloat, endAlpha: CGFloat, showToast: Bool){
        let duration = 0.5
        if (endAlpha == self.cancelView.alpha && !showToast){
            return
        }
        UIView.animate(withDuration: duration, animations: {
            self.cancelView.alpha = startAlpha
            if (showToast) {
                self.toastView.text = "Recording Canceled"
                self.toastView.alpha = 1
            }
        }) {
            (finished) in
            UIView.animate(withDuration: duration, animations: {
                self.cancelView.alpha = endAlpha
                if (showToast) {
                    self.toastView.alpha = 0
                }
            })
        }
    }
    
    func showToast(_ text: String) {
        let duration = 1.0
        UIView.animate(withDuration: duration, animations: {
            self.toastView.alpha = 0
        })
        {(finished) in
            self.toastView.text = text
            UIView.animate(withDuration: duration, animations: {
                self.toastView.alpha = 1
            })
            {(finished) in
                self.toastView.text = text
                UIView.animate(withDuration: duration, animations: {
                    self.toastView.alpha = 0
                })
            }
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

    func loadRecording() {
        labelCount.text = String(100 - UserDefaults.standard.integer(forKey: "totalRecordings"))
    }
    
    func countRecording() {
        UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: "totalRecordings") + 1, forKey: "totalRecordings")
        self.loadRecording()
    }
}

