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
import Instructions


class ViewController: UIViewController, LongPressRecordButtonDelegate, CoachMarksControllerDataSource, CoachMarksControllerDelegate {

    var recorder: Recorder!
    var engine: AVAudioEngine = AVAudioEngine()
    var wsComm: WSComm!
    var jsonSentences: Any?
    var recordingCanceled: Bool = false
    var dataViewController: UIViewController? = nil
    let coachMarksController = CoachMarksController()

    @IBOutlet weak var labelCount: UILabel!
    @IBOutlet weak var recordButton: LongPressRecordButton!
    @IBOutlet weak var toastView: UILabel!
    @IBOutlet weak var leftWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var rightWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var cancelView : UILabel!
    
    var timer:Timer?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (UserDefaults.standard.integer(forKey: "instructionsShown") == 0) {
            self.coachMarksController.startOn(self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (UserDefaults.standard.integer(forKey: "instructionsShown") == 0) {
            self.coachMarksController.stop(immediately: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startWaveView()
        recordButton.delegate = self
        
        if (UserDefaults.standard.integer(forKey: "instructionsShown") == 0) {
            self.coachMarksController.dataSource = self
        }
        
        // Flip the view around.
        self.leftWaveView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        let mid = self.view.bounds.width / 2.0
        
        // align the leftWaveView
        var newrightWaveViewFrame = self.rightWaveView.frame
        newrightWaveViewFrame.size.width = mid
        newrightWaveViewFrame.origin.x = mid
        self.rightWaveView.frame = newrightWaveViewFrame
        
        // Center record button.
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
        let swipeLeftTV = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.viewSwipped(gesture:)))
        swipeLeftTV.direction = UISwipeGestureRecognizerDirection.left
        self.textView.addGestureRecognizer(swipeLeftTV)
        
        // and then to the right
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.viewSwipped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        let swipeRightTV = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.viewSwipped(gesture:)))
        swipeRightTV.direction = UISwipeGestureRecognizerDirection.right
        self.textView.addGestureRecognizer(swipeRightTV)

        // create DataViewController if required
        if  UserDefaults.standard.string(forKey: "userDetails") == nil {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            dataViewController = mainStoryboard.instantiateViewController(withIdentifier: "data") as UIViewController
            (dataViewController as! DataViewController).startPickers()
        }
        
        // display the current total of recordings
        textView.font =  UIFont(name: "Avenir Heavy", size: 20)
        textView.textColor = UIColor.white
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
            let sentencesSpoken = (UserDefaults.standard.stringArray(forKey: "sentencesSpoken") ?? [String]())
            var newSentence = false
            if (dictionary.count == sentencesSpoken.count) {
                let alert = UIAlertController(title: "Warning", message: "You completed all the sentences!", preferredStyle:UIAlertControllerStyle.alert)
                let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                alert.addAction(defaultAction)
                self.present(alert, animated: true){
                    
                }
                return;
            }
            
            while (!newSentence) {
                if let sentence = dictionary[String(sentenceid)] as? String {
                    let sentenceHash = sentence.digest(length: CC_SHA1_DIGEST_LENGTH, gen: {(data, len, md) in CC_SHA1(data,len,md)})
                    if (!sentencesSpoken.contains(sentenceHash)) {
                        // display the sentence
                        showText(sentence)
                        // and pass it to the recorder
                        recorder.sentence = sentence
                        newSentence = true
                    } else {
                        newSentence = false
                    }
                }
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
    
    // COACH DELEGATES
    
    /// Asks for the views defining the coach mark that will be displayed in
    /// the given nth place. The arrow view is optional. However, if you provide
    /// one, you are responsible for supplying the proper arrow orientation.
    /// The expected orientation is available through
    /// `coachMark.arrowOrientation` and was computed beforehand.
    ///
    /// - Parameter coachMarksController: the coach mark controller requesting
    ///                                   the information.
    /// - Parameter coachMarkViewsForIndex: the index referring to the nth place.
    /// - Parameter coachMark: the coach mark meta data.
    ///
    /// - Returns: a tuple packaging the body component and the arrow component.
    public func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        switch (index){
            case 0:
                coachViews.bodyView.hintLabel.text = "Here you'll see the sentences to be spoken. You can swipe left or right to change it."
                coachViews.bodyView.nextLabel.text = "Ok"
            case 1:
                coachViews.bodyView.hintLabel.text = "This is the record button. Hold it until you hear a short bip and then start speaking the sentence. When you finish, just release the button."
                coachViews.bodyView.nextLabel.text = "Ok"
            case 2:
                coachViews.bodyView.hintLabel.text = "If you move your finger away from the button you will see this little X. This means if you release your finger at this moment, the recording will be canceled."
                coachViews.bodyView.nextLabel.text = "Ok"
                cancelView.alpha = 1.0
            case 3:
                coachViews.bodyView.hintLabel.text = "Here you have the total of sentences that still need to be submitted to reach your goal. Just tap Ok and start to contribute!"
                coachViews.bodyView.nextLabel.text = "Ok"
                UserDefaults.standard.setValue(1, forKey: "instructionsShown")
                cancelView.alpha = 0.0
            default:
                self.coachMarksController.stop(immediately: true)
                cancelView.alpha = 0.0
        }

        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    /// Asks for the metadata of the coach mark that will be displayed in the
    /// given nth place. All `CoachMark` metadata are optional or filled with
    /// sensible defaults. You are not forced to provide the `cutoutPath`.
    /// If you don't the coach mark will be dispayed at the bottom of the screen,
    /// without an arrow.
    ///
    /// - Parameter coachMarksController: the coach mark controller requesting
    ///                                   the information.
    /// - Parameter coachMarkViewsForIndex: the index referring to the nth place.
    ///
    /// - Returns: the coach mark metadata.
    public func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        
        switch (index){
            case 0:
                return coachMarksController.helper.makeCoachMark(for: self.textView)
            case 1:
                return coachMarksController.helper.makeCoachMark(for: self.recordButton)
            case 2:
                return coachMarksController.helper.makeCoachMark(for: self.recordButton)
            case 3:
                return coachMarksController.helper.makeCoachMark(for: self.labelCount)
            default:
                return coachMarksController.helper.makeCoachMark(for: self.view)
            }
    }
    
    /// Asks for the number of coach marks to display.
    ///
    /// - Parameter coachMarksController: the coach mark controller requesting
    ///                                   the information.
    ///
    /// - Returns: the number of coach marks to display.
    public func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 5
    }

}

extension String {
    
    func digest(length:Int32, gen:(_ data: UnsafeRawPointer, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>) -> String {
        var cStr = [UInt8](self.utf8)
        var result = [UInt8](repeating:0, count:Int(length))
        gen(&cStr, CC_LONG(cStr.count), &result)
        
        let output = NSMutableString(capacity:Int(length))
        
        for r in result {
            output.appendFormat("%02x", r)
        }
        
        return String(output)
    }
    
}
