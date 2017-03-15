//
//  AgreementViewController.swift
//  Voicebank
//
//  Created by Andre Natal on 3/11/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import UIKit

class AgreementViewcontroller: UIViewController {

    @IBOutlet weak var agreeButton : UIButton!
    @IBOutlet weak var disclaimerView : UITextView!
    let prefs = UserDefaults.standard
    
    override func viewDidAppear(_ animated: Bool) {
        if prefs.string(forKey: "agreementAccepted") != nil {
            print(prefs.string(forKey: "agreementAccepted")!)
            self.segueToRecordingView()
        } else {
            self.view.isHidden = false
        }
    }
    
    func segueToRecordingView() {
        self.performSegue(withIdentifier: "agreement", sender: self)
    }
    
    @IBAction func acceptAgreement() {
        let prefs = UserDefaults.standard
        prefs.setValue(1, forKey: "agreementAccepted")
    }
    
}


