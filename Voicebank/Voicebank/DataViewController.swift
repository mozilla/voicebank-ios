//
//  DataViewController.swift
//  Voicebank
//
//  Created by Andre Natal on 3/10/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import UIKit

class DataViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var dataGender: [String] = [String]()
    var dataAge: [String] = [String]()
    var dataAccent: [String] = [String]()

    @IBOutlet weak var submitButton : UIButton!
    @IBOutlet weak var ignoreButton : UIButton!
    @IBOutlet weak var pickerView: UIPickerView!

    override func viewDidLoad() {
        // Connect data:
        dataGender = ["Gender", "Male", "Female", "Other"]
        dataAge = ["Age", "14-18","19-25","26-30","31-40","41-50","51-60","+60"]
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
    }
 
    @available(iOS 2.0, *)
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (component){
            case 0:
                return dataAccent.count
            case 1:
                return dataAge.count
            case 2:
                return dataGender.count
            default:
                return 0
        }
    }
    
    func startPickers(){
        do {
            if let path = Bundle.main.path(forResource: "langs", ofType: "txt"){
                let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                dataAccent = data.components(separatedBy: "\n")
            }
        } catch let err as NSError {
            print(err)
        }
    }
    
    // Number of columns of data
    func numberOfComponents(in: UIPickerView) -> Int {
        return 3
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (component){
            case 0:
                return dataAccent[row]
            case 1:
                return dataAge[row]
            case 2:
                return dataGender[row]
            default:
                return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerLabel = view as? UILabel;
        
        if (pickerLabel == nil)
        {
            pickerLabel = UILabel()
            
            pickerLabel?.font = UIFont(name: "Avenir Heavy", size: 16)
            pickerLabel?.textAlignment = NSTextAlignment.center
            pickerLabel?.textColor = UIColor.white
        }
        
        switch (component){
            case 0:
                pickerLabel?.text = dataAccent[row]
            case 1:
                pickerLabel?.text = dataAge[row]
            case 2:
                pickerLabel?.text = dataGender[row]
            default:
                pickerLabel?.text = ""
        }

        return pickerLabel!;
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch (component){
            case 0:
                return 106;
            case 1:
                return 106;
            case 2:
                return 106;
            default:
                return 0.0;
        }
    }
    
    func segueToRecordingView() {
        self.performSegue(withIdentifier: "recording", sender: self)
    }
    
    @IBAction func ignoreDetails() {
        let prefs = UserDefaults.standard
        prefs.setValue(0, forKey: "userDetails")
    }
    
    @IBAction func submitData(){
        let prefs = UserDefaults.standard
        let wsComm = WSComm()
        let gender = pickerView.selectedRow(inComponent: 2)
        let age = pickerView.selectedRow(inComponent: 1)
        let language = pickerView.selectedRow(inComponent: 0)
        
        if (gender == 0 || age == 0 || language == 0){
            let alert = UIAlertController(title: "Warning", message: "Please, select all fields", preferredStyle:UIAlertControllerStyle.alert)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(defaultAction)
            self.present(alert, animated: true){
                
            }
        } else  {
            wsComm.uploadInfo(gender: String(gender), age: String(age), language: String(language))
            prefs.setValue(1, forKey: "userDetails")
            self.segueToRecordingView()
        }
    }
    
}

