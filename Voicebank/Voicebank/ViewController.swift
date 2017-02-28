//
//  ViewController.swift
//  Voicebank
//
//  Created by Andre Natal on 2/17/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!
    var recorder: Recorder!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        recorder = Recorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordTapped() {
        if (self.recorder != nil){
            if (!self.recorder.isRecording()){
                self.recorder.startRecording()
                recordButton.setTitle("Tap to Stop", for: .normal)
            } else {
                self.recorder.stopRecording()
                recordButton.setTitle("Record", for: .normal)
            }
        }
    }
    
}

