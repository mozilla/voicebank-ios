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

    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.string(forKey: "agreementAccepted") != nil {
            self.segueToRecordingView()
        } else {
            self.view.isHidden = false
        }
    }
    
    func segueToRecordingView() {
        self.performSegue(withIdentifier: "agreement", sender: self)
    }
    
    @IBAction func acceptAgreement() {
        UserDefaults.standard.setValue(1, forKey: "agreementAccepted")
    }
    
}


