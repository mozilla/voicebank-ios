//
//  WSComm.swift
//  Voicebank
//
//  Created by Andre Natal on 2/27/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import UIKit

class WSComm: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
   
    var responseData = NSMutableData()
    let webserviceEndpoint = "https://murmur.vaani.io"
    override init(){
        
    }
    
    func uploadAudio(sentence: Sentence, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                let data: NSData = try NSData(contentsOfFile: sentence.audioFilename.path)
                let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/upload/\(sentence.sentenceHash)/") as! URL)
                request.httpMethod = "POST"
                request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
                request.setValue("audio/mp4a", forHTTPHeaderField: "content-type")
                request.setValue(UIDevice.current.identifierForVendor!.uuidString, forHTTPHeaderField: "uid")
                request.setValue("\(sentence.sentence)|\(sentence.sentenceSTT)"   , forHTTPHeaderField: "sentence")
                let configuration = URLSessionConfiguration.default
                let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                let task = session.uploadTask(with: request as URLRequest, from: data as Data, completionHandler: completion)
                task.resume()
                var sentencesSpoken = (UserDefaults.standard.stringArray(forKey: "sentencesSpoken") ?? [String]())
                sentencesSpoken.append(sentence.sentenceHash)
                UserDefaults.standard.set(sentencesSpoken, forKey: "sentencesSpoken")
            } catch let error as NSError{
                print("Error: \(error)")
            }
        }
    }
    
    func uploadInfo(gender: String, age: String, language: String) {
        DispatchQueue.main.async {
            let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/data/ios/") as! URL)
            request.httpMethod = "GET"
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue(UIDevice.current.identifierForVendor!.uuidString, forHTTPHeaderField: "id")
            request.setValue(gender, forHTTPHeaderField: "gender")
            request.setValue(age, forHTTPHeaderField: "age")
            request.setValue(language, forHTTPHeaderField: "langs1")
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest)
            task.resume()
        }
    }
    
    func getSentences(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/sentences.json") as! URL)
        request.httpMethod = "GET"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: completion)
        task.resume()
    }
    
}
